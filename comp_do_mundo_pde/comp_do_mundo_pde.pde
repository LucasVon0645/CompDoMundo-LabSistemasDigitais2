import processing.serial.*;      // serial comm lib
import processing.sound.*;       // sound lib
import java.awt.event.KeyEvent;  // keyboard reading lib
import java.sql.*;               // lib for interfacing with postgreSQL
import java.io.IOException;
import java.util.Map;


// Class to connect to PostgreSQL remote database
class PostgresClient {

    // Database info in AWS RDS
    private final static String url =
            "jdbc:postgresql://comp-do-mundo.c0v17euafbbn.sa-east-1.rds.amazonaws.com:5432/processing";
    private final static String user = "processing";
    private final static String password = "hexa2022";

    private Connection conn = null;
    private PreparedStatement pstmt = null;

    // Connect itself to the remote db
    private boolean connect() {
        try {

            Class.forName("org.postgresql.Driver");
            conn = DriverManager.getConnection(url, user, password);
            conn.setAutoCommit(false);
            return true;

        } catch (Exception e) {

            e.printStackTrace();
            println(e.getClass().getName() + ": " + e.getMessage());
            return false;
        }
    }
    
    // Disconnect itself to the remote db
    private void disconnect() {
        try {
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
            println(e.getClass().getName() + ": " + e.getMessage());
        }
    }
    
    // Save a match to the db using the latest match info
    public void saveMatchToDatabase(Match match) {
        if (this.connect()) {
            println("Escrevendo dados ao banco de dados!");
            
            try {
                long now = System.currentTimeMillis();
                Timestamp timestamp = new Timestamp(now);
                
                String query = "INSERT INTO matches ";
                query += "(timestamp, winner, rounds, goals_by_a, goals_by_b, left_kicks_by_A, ";
                query += "left_kicks_by_B, right_kicks_by_A, right_kicks_by_B) ";
                query += "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
                
                pstmt = conn.prepareStatement(query);
                pstmt.setTimestamp(1, timestamp);
                pstmt.setString(2, String.valueOf(match.winner));
                pstmt.setInt(3, match.round);
                pstmt.setInt(4, match.goalsA);
                pstmt.setInt(5, match.goalsB);
                pstmt.setInt(6, match.kickerA.getKicks('E'));
                pstmt.setInt(7, match.kickerB.getKicks('E'));
                pstmt.setInt(8, match.kickerA.getKicks('D'));
                pstmt.setInt(9, match.kickerB.getKicks('D'));
    
                pstmt.executeUpdate();
                pstmt.close();
                conn.commit();
                
            } catch (Exception e) {
                println(e.getClass().getName() + ": " + e.getMessage());
            }
            
            this.disconnect();
        }
        else {
            println("ERRO: Incapaz de se conectar ao servidor.");
        }
    }

    // Constructor
    public PostgresClient() {};
}


// Abtract class for creating players, such as Kickers or Goalkeepers
abstract class Player {
    protected String team;
    protected HashMap<String,PImage> images;
    protected PImage currentImage;
    
    protected abstract void loadImages(); // Loads images based on team
    protected abstract void resizeImages(); // Resize images proportionally
    protected abstract void positionPlayer(); // Tranlate player to wherever it needs to be, based on its image
    protected abstract void updateCurrentImage(); // Updates current image of player
    
    // Draws player centered in the given coordinates
    public void drawPlayer() {        
        float currentHeight, currentWidth;
        
        pushMatrix();
        pushStyle();
        
        this.resizeImages();
        this.positionPlayer();

        currentHeight = this.currentImage.height;
        currentWidth = this.currentImage.width;
        
        translate(-currentWidth / 2, -currentHeight, 0);
        textureMode(NORMAL);
        beginShape();
            noStroke();
            texture(this.currentImage);
            vertex(0, 0, 0, 0, 0);
            vertex(currentWidth, 0, 0, 1, 0);
            vertex(currentWidth, currentHeight, 0, 1, 1);
            vertex(0, currentHeight, 0, 0, 1);
        endShape();
    
        popStyle();
        popMatrix();
    }
    
    public Player(String team) {
        this.team = team;
        this.images = new HashMap<String,PImage>();
        this.loadImages();
        this.updateCurrentImage();
    }
}


// Class to draw and keep info about Goalkeeper
class Kicker extends Player {
    
    private IntDict kicks;
    public char id;
    
    protected void loadImages() {
        this.images.put("kicker_still", loadImage(this.team == "Brazil" ? "characters/brazil/Kicker_still.png" : "characters/brazil/Kicker_still.png"));
        this.images.put("kicker_moving", loadImage(this.team == "Brazil" ? "characters/brazil/Kicker_moving.png" : "characters/brazil/Kicker_moving.png"));
    }
    
    protected void resizeImages() {
        float kickerStillHeight = 0.85*goalHeight;
        float kickerMovingHeight = 0.75*goalHeight;

        this.images.get("kicker_still").resize(0, int(kickerStillHeight));
        this.images.get("kicker_moving").resize(0, int(kickerMovingHeight));
    }
    
    protected void positionPlayer() {
        translate(0.3*width, 1.01*height, 0);
    }
    
    public void updateCurrentImage() {
        this.currentImage = this.images.get("kicker_still");
    }
    
    // Adds 1 to the current kick count of a given direction
    public void updateKickCount(char direction) {
        int currentKickCount = this.kicks.get(Character.toString(direction));
        this.kicks.set(Character.toString(direction), currentKickCount+1);
    }
    
    // Get the current kick count of a given direction
    public int getKicks(char direction) {
        return this.kicks.get(Character.toString(direction));
    }


    // Constructor
    public Kicker(String team) {
        super(team);
        this.id = (team == "Brazil") ? 'A' : 'B';
        this.kicks = new IntDict();
        this.kicks.set("D", 0);
        this.kicks.set("E", 0);
    };
}


// Class to draw and keep info about Goalkeeper
class Goalkeeper extends Player {
    
    private char direction;
    
    protected void loadImages() {
        this.images.put("goalkeeper_center", loadImage(this.team == "Brazil" ? "characters/brazil/Goalkeeper_center.png" : "characters/brazil/Goalkeeper_center.png"));
        this.images.put("goalkeeper_left", loadImage(this.team == "Brazil" ? "characters/brazil/Goalkeeper_left.png" : "characters/brazil/Goalkeeper_left.png"));
        this.images.put("goalkeeper_right", loadImage(this.team == "Brazil" ? "characters/brazil/Goalkeeper_right.png" : "characters/brazil/Goalkeeper_right.png"));
    }
    
    protected void resizeImages() {
        PImage goalkeeperCenterImage, goalkeeperLeftImage, goalkeeperRightImage;
        float goalkeeperCenterHeight = 0.85*goalHeight;
        float goalkeeperSidewaysHeight = 0.75*goalHeight;
        
        goalkeeperCenterImage = this.images.get("goalkeeper_center");
        goalkeeperCenterImage.resize(0, int(goalkeeperCenterHeight));
        
        goalkeeperLeftImage = this.images.get("goalkeeper_left");
        goalkeeperLeftImage.resize(0, int(goalkeeperSidewaysHeight));
        
        goalkeeperRightImage = this.images.get("goalkeeper_right");
        goalkeeperRightImage.resize(0, int(goalkeeperSidewaysHeight));
    }
    
    protected void positionPlayer() {
        translate(width/2, (height-fieldHeight) + endFieldLineHeight + 32, 0.7*fieldDepth); // endline coordinates
        
        if (this.direction == '1' || this.direction == '2') {
            translate(0.15*goalWidth, -48, 0);
        }
        else if (this.direction == '4' || this.direction == '5') {
            translate(-0.15*goalWidth, -48, 0);
        }
    }
    
    public void updateCurrentImage() {
        if (this.direction == '1' || this.direction == '2') {
            this.currentImage = this.images.get("goalkeeper_right");
        }
        else if (this.direction == '4' || this.direction == '5') {
            this.currentImage = this.images.get("goalkeeper_left");
        }
        else {
            this.currentImage = this.images.get("goalkeeper_center");
        }
    }
    
    // Setter of the direction attribute
    public void setDirection(char newDirection) {
        this.direction = newDirection;
    }
    
    // Getter of the direction attribute
    public char getDirection() {
        return this.direction;
    }
    

    // Constructor
    public Goalkeeper(String team) {
        super(team);
    };
}


class Match {
    private int[] shotsA, shotsB;
    private Kicker kickerA, kickerB;
    private Goalkeeper goalkeeperA, goalkeeperB;
    
    public Kicker currentKicker;
    public Goalkeeper currentGoalkeeper;
    public int round, goalsA, goalsB;
    public char winner;

    
    // Updates match variables when a new shot is about to happen
    public void updateRound(char kicker_tx, int round_tx) {
        // Error conditions
        if ((round_tx < 0) || (round_tx > 16) || !((kicker_tx == 'A') || (kicker_tx == 'B'))) {
            println("ERRO: updateRound");
            println("round_tx: " + round_tx);
            println("kicker_tx: " + kicker_tx);
        }
        
        else {
            if (kicker_tx == 'A') {
                this.round = round_tx;  
            }
            
            this.currentKicker = (kicker_tx == 'A') ? kickerA : kickerB;
            this.currentGoalkeeper = (kicker_tx == 'A') ? goalkeeperB : goalkeeperA;
            this.setCurrentShot(1);
            
        }
    }
    
    // Updates match variables when a new shot is about to happen
    public void playPenalty(char kickerDirection_tx) {
        // Error conditions
        if (!((kickerDirection_tx == 'E') || (kickerDirection_tx == 'D'))) {
            println("ERRO: playPenalty");
            println("kickerDirection_tx: " + kickerDirection_tx);
        }
        
        else {
            currentKicker.updateKickCount(kickerDirection_tx);
            this.currentGoalkeeper.setDirection('1'); // DELETE THIS LATER
            this.currentGoalkeeper.updateCurrentImage();
            this.currentKicker.updateCurrentImage();
        }
    }
    
    // Updates match variables after a shot has happened
    void updateScore(int goalsA_tx, int goalsB_tx) {
        
        // Error conditions
        if ((goalsA_tx < 0 || goalsA_tx > 16 ) || (goalsB_tx < 0 || goalsB_tx > 16 )) {
            println("ERRO: updateScoreboard");
            println("goalsA_tx: " + goalsA_tx);
            println("goalsB_tx: " + goalsB_tx);
    
        } else {
            
            if (this.currentKicker.id == 'A') {
                this.setCurrentShot((goalsA_tx != this.goalsA) ? 2 : -1);
                this.goalsA = goalsA_tx;
            }
            else if (this.currentKicker.id == 'B') {
                this.setCurrentShot((goalsB_tx != this.goalsB) ? 2 : -1);
                this.goalsB = goalsB_tx;
            }
        }
    }
    
    public void endMatch() {
        this.winner = (this.goalsA > this.goalsB) ? 'A' : 'B';
        this.round += 1; // corrects num of rounds because it started at 0
    }
    
    public void setCurrentShot(int status) {
        int[] teamShots = currentKicker.id == 'A' ? this.shotsA : this.shotsB;
        teamShots[this.round] = status;
    }
    
    public int[] getShots(char team) {
        return team == 'A' ? this.shotsA : this.shotsB;
    }
    
    public Match() {
        this.kickerA = new Kicker("Brazil");
        this.kickerB = new Kicker("Argentina");
        this.goalkeeperA = new Goalkeeper("Brazil");
        this.goalkeeperB = new Goalkeeper("Argentina");
        this.currentKicker = this.kickerA;
        this.currentGoalkeeper = this.goalkeeperB;
        
        this.round = 0;
        this.goalsA = 0;
        this.goalsB = 0;
        
        this.shotsA = new int[16];
        this.shotsB = new int[16];
        for (int i = 0; i < shotsA.length; i += 1) {
            this.shotsA[i] = 0;
            this.shotsB[i] = 0;
        }
        
        this.winner = 'O';
    };
}


// Global drawing parameters variables
float fieldHeight, fieldDepth;
float goalHeight, goalWidth;
float endFieldLineHeight;
float advertHeight;

// Global object variables
Serial serialConnetion;
PostgresClient client;
Match currentMatch;

// Global hashmaps
HashMap<String,SoundFile> sounds = new HashMap<String,SoundFile>();
HashMap<String,PImage> otherImages = new HashMap<String,PImage>();


void setup() {
    //size(2400, 1800, P3D); // actual size to use
    size(1400, 1050, P3D); // size when adjusting window position
    
    configureSerialComm();
    client = new PostgresClient();
    currentMatch = new Match();

    loadOtherImages();
    loadSounds();

    sounds.get("background").loop();
}


// Configures serial port for communication
void configureSerialComm() {
    String port = "COM6";   // <-- change value depending on machine
    int baudrate = 115200;  // 115200 bauds
    char parity = 'E';      // even
    int databits = 7;       // 7 data bits
    float stopbits = 2.0;   // 2 stop bits
    
    int lf = 10;  // ASCII for linefeed -> actual value to use
    //int lf = 46;  // ASCII for . -> use this for debugging
    
    serialConnetion = new Serial(this, port, baudrate, parity, databits, stopbits);
    serialConnetion.bufferUntil(lf);
}


// Fills global hashmap variable with all the sound effects used in sketch
void loadSounds() {
    sounds.put("background", new SoundFile(this, "sounds/Crowd_background_noise.wav"));
    sounds.put("whistle", new SoundFile(this, "sounds/Whistle.wav"));
}


// Loads adverts images into global hashmap
void loadOtherImages() {
    otherImages.put("pcs_logo", loadImage("adverts/PCS_logo.png"));
    otherImages.put("qatar_logo", loadImage("adverts/Qatar_logo.jpg"));
    otherImages.put("crowd", loadImage("Crowd.jpg"));
}


void draw() {
    // Setting drawing variables
    fieldHeight = 0.6*height;
    fieldDepth = -0.2*width;
    goalHeight = height - fieldHeight;
    goalWidth = 0.666*width;
    endFieldLineHeight = 0.125*fieldHeight;
    advertHeight = 0.1*height;
    
    // lights();
    drawField();
    drawGoal();
    drawAdverts();
    drawScoreboard();
    drawCrowd();
    
    // For some reason, the order of drawing matters here:
    // to keep the background of characters transparent, render them last.
    currentMatch.currentKicker.drawPlayer();
    currentMatch.currentGoalkeeper.drawPlayer();
    
}


// Draws the football field on the screen: completely static
void drawField() {
    int NUM_OF_SUBFIELDS = 4; // Change this to have more/less subfields
    float subfieldWidth = (2*width)/float(NUM_OF_SUBFIELDS);
    float smallAreaLineHeight = 0.60*fieldHeight;
    int lineStroke = 8;

    pushMatrix();
    pushStyle();
  
    translate(0, (height-fieldHeight), 0);

    // Subfields: parts of field with different shades of green
    for (int i = 0; i < NUM_OF_SUBFIELDS; i += 1) {
        float subfieldStart = -0.5*width + i*subfieldWidth;
        float subfieldEnd = subfieldStart + subfieldWidth;
        
        beginShape();
            noStroke();
            fill(boolean(i % 2) ? #13A30D : #13930D);
            vertex(subfieldStart, 0, fieldDepth);
            vertex(subfieldEnd, 0, fieldDepth);
            vertex(subfieldEnd, fieldHeight, 0);
            vertex(subfieldStart, fieldHeight, 0);
        endShape();
    }
  
    noStroke();
    fill(#FFFFFF);
    
    // Line on the field: small area
    beginShape();
        vertex(-0.5*width, smallAreaLineHeight, 0.1*fieldDepth);
        vertex(1.5*width, smallAreaLineHeight, 0.1*fieldDepth);
        vertex(1.5*width, smallAreaLineHeight + lineStroke, 0.1*fieldDepth);
        vertex(-0.5*width, smallAreaLineHeight + lineStroke, 0.1*fieldDepth);
    endShape();
    
    // Line on the field: end of field
    beginShape();
        vertex(-0.5*width, endFieldLineHeight, 0.75*fieldDepth);
        vertex(1.5*width, endFieldLineHeight, 0.75*fieldDepth);
        vertex(1.5*width, endFieldLineHeight + lineStroke, 0.75*fieldDepth);
        vertex(-0.5*width, endFieldLineHeight + lineStroke, 0.75*fieldDepth);
    endShape();
    
    popStyle();
    popMatrix();
}


// Draws the goal on the screen: completely static
void drawGoal() {
    float goalThickness = 0.01*width;

    pushMatrix();
    pushStyle();
    
    translate(width/2, (height-fieldHeight) + endFieldLineHeight, 0.75*fieldDepth);
    stroke(#EEEEEE);
    
    // Goal structure
    strokeWeight(goalThickness);
    line((-goalWidth/2), 0, 0, (-goalWidth/2), -goalHeight, 0);
    line((goalWidth/2), 0, 0, (goalWidth/2), -goalHeight, 0);
    line((-(goalWidth + goalThickness)/2), -goalHeight, 0, ((goalWidth+goalThickness)/2), -goalHeight, 0);

    popStyle();
    popMatrix();
}


// Draws the football field on the screen: completely static
void drawAdverts() {
    int NUM_OF_ADS = 5; // Change this to have more/less adverts
    float advertWidth = (1.5*width)/float(NUM_OF_ADS);
    
    pushMatrix();
    pushStyle();
    
    translate(0, (height-fieldHeight), fieldDepth);
  
    for (int i = 0; i < NUM_OF_ADS; i += 1) {
        float adStart = -0.25*width + i*advertWidth;
        float adEnd = adStart + advertWidth;
        PImage currentImage = otherImages.get(boolean(i % 2) ? "pcs_logo" : "qatar_logo");
        currentImage.resize(int(advertWidth), 0);
        
        textureMode(NORMAL);
        beginShape();
            noStroke();
            texture(currentImage);
            vertex(adStart, -advertHeight, 0, 0, 0);
            vertex(adEnd, -advertHeight, 0, 1, 0);
            vertex(adEnd, 0, 0, 1, 1);
            vertex(adStart, 0, 0, 0, 1);
        endShape();
    }

    popStyle();
    popMatrix();
}


// Draws the crowd behind the goal on the screen: completely static
void drawCrowd() {
    PImage crowdImage;
    int crowdHeight;
    float crowdWidth = 1.55*width;

    // Crowd image from data folder
    crowdImage = otherImages.get("crowd");
    crowdImage.resize(int(crowdWidth), 0);
    crowdHeight = crowdImage.height;
    
    pushMatrix();
    pushStyle();
    
    translate(-0.27*width, -0.55*height, 1.7*fieldDepth);

    textureMode(NORMAL);
    beginShape();
        noStroke();
        texture(crowdImage);
        vertex(0, 0, 0, 0, 0);
        vertex(crowdWidth, 0, 0, 1, 0);
        vertex(crowdWidth, crowdHeight, 0, 1, 1);
        vertex(0, crowdHeight, 0, 0, 1);
    endShape();

    popStyle();
    popMatrix();
}


// Draws a dynamic scoreboard, showing the number of points
// for each team, as well as which shots were goals, etc.
void drawScoreboard() {
    float scoreboardX = 0.04 * width;
    float scoreBoardY = 0.04 * height;
    float teamScoreHeight = 0.045 * height;
    
    int teamNameBoxWidth = 120;
    int teamScoreBoxWidth = 40;
    int penaltyPointsBoxWidth = 240;
    
    int teamMarkerWidth = 8;
    int circleDiameter = 16;
    int circleMargin = 16;
    int dividerHeight = 1;
  
    float dividerWidth = teamNameBoxWidth + teamScoreBoxWidth + penaltyPointsBoxWidth;
    float lineOffset = teamNameBoxWidth + teamScoreBoxWidth + 5*(circleDiameter + circleMargin) + 1.5*circleMargin;

    pushMatrix();
    pushStyle();
    
    translate(scoreboardX, scoreBoardY, 0);
    textSize(28);
    
    for (int i = 0; i < 2; i += 1) {
        char currentScoreboard = boolean(i) ? 'B' : 'A';
        float scoreStart = i * teamScoreHeight;
        
        pushMatrix();
        pushStyle();

        translate(0, scoreStart, 0);
    
        // Draws divider between both teams' scores
        if (boolean(i)) {
            strokeWeight(dividerHeight);
            stroke(#00000077);
            line(-teamMarkerWidth, 0, 0, dividerWidth, 0, 0);
            translate(0, dividerHeight, 0);
        }
    
        // Draws a small rectangle on the left with the color of each team
        beginShape();
            noStroke();
            fill(boolean(i) ? #1981CE : #F58B20);
            vertex(-teamMarkerWidth, 0, 0);
            vertex(0, 0, 0);
            vertex(0, teamScoreHeight, 0);
            vertex(-teamMarkerWidth, teamScoreHeight, 0);
        endShape();
    
        // Draws the name of each team
        textInsideBox("Time " + currentScoreboard, teamNameBoxWidth, teamScoreHeight, #CBB75D, #443514);
        translate(teamNameBoxWidth, 0, 0);
        
        // Draws the current score for each team
        textInsideBox((currentScoreboard == 'A' ? str(currentMatch.goalsA) : str(currentMatch.goalsB)),
                       teamScoreBoxWidth, teamScoreHeight, #333333, #FFFFFF);
        translate(teamScoreBoxWidth, 0, 0);

        // Draws the box in which circles for each of the first 10 shots will be
        beginShape();
            noStroke();
            fill(#00000088);
            vertex(0, 0, 0);
            vertex(penaltyPointsBoxWidth, 0, 0);
            vertex(penaltyPointsBoxWidth, teamScoreHeight, 0);
            vertex(0, teamScoreHeight, 0);
        endShape();
    
        // Draws the circles for each of the first 5 shots, and color it based on its 'status'
        // 0 means the shot has not happened, 1 means it is happening right now;
        // 2 means the shot was a goal, and -1 means it was a miss
        translate(0, teamScoreHeight/2, 0);
        for (int j = 0; j < 5; j += 1) {
            int[] currentShots = currentMatch.getShots(currentScoreboard);
            color goalIndicatorColor = (currentShots[j] == 0 ? #FFFFFF : 
                                        currentShots[j] == 1 ? #FFFF00 :
                                        currentShots[j] == 2 ? #00FF00 :
                                        #FF0000);
            fill(goalIndicatorColor);
            translate((circleDiameter + circleMargin), 0, 0);
            circle(0, 0, circleDiameter);
        }
    

        // Draw the final circle for each team, indicating who won
        color winnerIndicatorColor = (currentMatch.winner == 'O' ? #FFFFFF : 
                                     (currentMatch.winner == currentScoreboard) ? #00FF00 :
                                      #FF0000);
                                      
        fill(winnerIndicatorColor);
        translate(3*circleMargin, 0, 0);
        circle(0, 0, circleDiameter);
        
        popStyle();
        popMatrix();
    }

    // Draws a line between the final circles and the other ones
    translate(lineOffset, teamScoreHeight/2, 0);
    strokeWeight(1);
    stroke(#FFFFFF);
    line(0, -8, 0, 0, teamScoreHeight + 8, 0);

    popStyle();
    popMatrix();
}


// Decodes message received with serial transmission
void serialEvent (Serial serialConnetion) {
    String message, segment1;
    int segment2;
    char header;
  
    try {
        message = serialConnetion.readString();
        println("Mensagem recebida é: " + message.substring(0, message.length() - 1));  // debug
        
        // Error in case the transmission cannot be interpreted
        if (message.length() != 4) {
            println("ERRO: mensagem tem tamanho diferente de 3");
        } else {
            
            // Conversions
            header = message.charAt(0);
            segment1 = message.substring(1, 2);
            segment2 = unhex(message.substring(2, 3));
            
            // If header is 0, the game has just been turned on
            if (header == '0') {
                println("JOGO COMEÇANDO");
                currentMatch = new Match();
            }
            
            // If header is 1, a match has just begun
            else if (header == '1') {
                println("RODADA " + segment2 + ": JOGADOR " + segment1 + " BATENDO");
                
                currentMatch.updateRound(segment1.charAt(0), segment2);
            }
            
            // If header is 2, the game is preparing itself for a new shot
            else if (header == '2') {
                println("JOGADOR JÁ PODE BATER");
                sounds.get("whistle").play();
            }
            
            else if (header == '3') {
                currentMatch.playPenalty(segment1.charAt(0));
            }
            
            // If header is 4, a shot has just happened, and we update the scoreboard
            else if (header == '4') {
                println("NOVO PLACAR:  A  |  B");
                println("              " + unhex(segment1) + "  |  " + segment2);
                
                currentMatch.updateScore(unhex(segment1), segment2);
            }
            
            // If header is 5, the match has ended, and we check who is the winner
            else if (header == '5') {
                println("FIM DO JOGO!!!!");
                println("PLACAR FINAL:  A  |  B");
                println("               " + unhex(segment1) + "  |  " + segment2);
                
                currentMatch.updateScore(unhex(segment1), segment2);
                currentMatch.endMatch();
                client.saveMatchToDatabase(currentMatch);
            }
            
            // If header is any other value, there is a transmission error
            else {
                println("ERRO: header é " + header);
            }
        }
    } catch(RuntimeException e) {
      e.printStackTrace();
    }
}


// Detects key press and sends it to the serial port
void keyPressed() {
    serialConnetion.write(key);
    println("Enviando tecla '" + key + "' para a porta serial.");
    
    if (key == '1' || key == '2' || key == '3' || key == '4' || key == '5') {
        // currentMatch.currentGoalkeeper.setDirection(key);
    }
}


// Helper function to draw a certain text inside a box of a different color
void textInsideBox(String text, float width, float height, color boxColor, color textColor) {
    pushStyle();
    
    beginShape();
        noStroke();
        fill(boxColor);
        vertex(0, 0, 0);
        vertex(width, 0, 0);
        vertex(width, height, 0);
        vertex(0, height, 0);
    endShape();
    
    fill(textColor);
    rectMode(CORNER);
    textAlign(CENTER, CENTER);
    text(text, 0, 0, width, height); 

    popStyle();
}
