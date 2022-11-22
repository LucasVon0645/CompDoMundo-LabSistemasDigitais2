import processing.serial.*;      // serial comm lib
import processing.sound.*;       // sound lib
import java.awt.event.KeyEvent;  // keyboard reading lib
import java.sql.*;               // lib for interfacing with postgreSQL
import java.io.IOException;
import java.util.Map;


// Class to connect to PostgreSQL remote database
public class PostgresClient {

    // Database info in AWS RDS
    private final static String url =
            "jdbc:postgresql://comp-do-mundo.c0v17euafbbn.sa-east-1.rds.amazonaws.com:5432/processing";
    private final static String user = "processing";
    private final static String password = "hexa2022";

    public Connection conn = null;
    public PreparedStatement pstmt = null;

    // Save a match to the db using the latest match info
    public void saveMatch() {
        try {
            long now = System.currentTimeMillis();
            Timestamp timestamp = new Timestamp(now);
            
            String query = "INSERT INTO matches ";
            query += "(timestamp, winner, rounds, goals_by_a, goals_by_b, left_kicks_by_A, ";
            query += "left_kicks_by_B, right_kicks_by_A, right_kicks_by_B) ";
            query += "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
            
            pstmt = conn.prepareStatement(query);
            pstmt.setTimestamp(1, timestamp);
            pstmt.setString(2, String.valueOf(winner));
            pstmt.setInt(3, round);
            pstmt.setInt(4, goalsA);
            pstmt.setInt(5, goalsB);
            pstmt.setInt(6, leftKicksA);
            pstmt.setInt(7, leftKicksB);
            pstmt.setInt(8, rightKicksA);
            pstmt.setInt(9, rightKicksB);

            pstmt.executeUpdate();
            pstmt.close();
            conn.commit();
            
        } catch (Exception e) {
            println(e.getClass().getName() + ": " + e.getMessage());
        }

    }

    // Connect itself to the remote db
    public boolean connect() {
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
    public void disconnect() {
        try {
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
            println(e.getClass().getName() + ": " + e.getMessage());
        }
    }

    // Constructor
    public PostgresClient() {};
}


// Global constants
int lf = 10;  // ASCII linefeed -> CHANGE THIS TO 10 TO TEST WITH CIRCUIT, or 64 to debug

// Global drawing variables
float fieldHeight;
float goalHeight;
float crowdHeight;
float endFieldLineHeight;
float advertHeight;
int fieldDepth;

// Global variables for Serial comm
Serial serialConnetion;
String port = "COM6";   // <== change value depending on machine
int baudrate = 115200;  // 115200 bauds
char parity = 'E';      // even
int databits = 7;       // 7 data bits
float stopbits = 2.0;   // 2 stop bits
int whichKey = -1;      // keyboard key

// Global match variables
int[] shotsA = new int[16], shotsB = new int[16];
int round, goalsA, goalsB;
int leftKicksA, leftKicksB, rightKicksA, rightKicksB;
char currentPlayer, kickDirection, winner;

// Global PostgreSQL database variables
PostgresClient client;

// Global sounds hashmap
HashMap<String,SoundFile> sounds = new HashMap<String,SoundFile>();


void setup() {
    // size (1400, 1050, P3D); // size when adjusting window position
    size (2000, 1500, P3D); // actual size to use
    
    serialConnetion = new Serial(this, port, baudrate, parity, databits, stopbits);
    serialConnetion.bufferUntil(lf);
   
    client = new PostgresClient();
    createSounds();
    
    globalResetFunc();
}


void draw() {
    // Setting drawing variables
    fieldHeight = 0.6*height;
    fieldDepth = -400;
    goalHeight = height - fieldHeight;
    endFieldLineHeight = 0.125*fieldHeight;
    advertHeight = 0.1*height;
    crowdHeight = (height - fieldHeight - advertHeight);
    
    // lights();
    drawField();
    drawGoal();
    drawAdverts();
    drawScoreboard();
    drawCrowd();
    
    // For some reason, the order of drawing matters here:
    // to keep the background of characters transparent, render them last.
    drawGoalkeeper();
    drawKicker();
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
    float goalWidth = 0.666*width;
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


// Draws goalkeeper on screen
void drawGoalkeeper() {
    PImage goalkeeperCenter;
    float goalkeeperCenterHeight = 0.85*goalHeight;
    float goalkeeperCenterRatio, goalkeeperCenterWidth;
   

    // Goalkeeper standing image
    goalkeeperCenter = loadImage("characters/brazil/Goalkeeper_center.png");
    goalkeeperCenterRatio = goalkeeperCenter.width / float(goalkeeperCenter.height);
    goalkeeperCenterWidth = goalkeeperCenterRatio * goalkeeperCenterHeight;
    goalkeeperCenter.resize(int(goalkeeperCenterWidth), int(goalkeeperCenterHeight));
    
    pushMatrix();
    pushStyle();
    
    translate(width/2, (height-fieldHeight) + endFieldLineHeight + 32, 0.7*fieldDepth); // endline coordinates
    translate(-goalkeeperCenterWidth / 2, -goalkeeperCenterHeight, 0);

    textureMode(NORMAL);
    beginShape();
        noStroke();
        texture(goalkeeperCenter);
        vertex(0, 0, 0, 0, 0);
        vertex(goalkeeperCenterWidth, 0, 0, 1, 0);
        vertex(goalkeeperCenterWidth, goalkeeperCenterHeight, 0, 1, 1);
        vertex(0, goalkeeperCenterHeight, 0, 0, 1);
    endShape();

    popStyle();
    popMatrix();
}


// Draws kicker on screen
void drawKicker() {
    PImage kickerStill;
    float kickerStillHeight = 0.85*goalHeight;
    float kickerStillRatio, kickerStillWidth;
   

    // Kicker still image
    kickerStill = loadImage("characters/brazil/Kicker_still.png");
    kickerStillRatio = kickerStill.width / float(kickerStill.height);
    kickerStillWidth = kickerStillRatio * kickerStillHeight;
    kickerStill.resize(int(kickerStillWidth), int(kickerStillHeight));
    
    pushMatrix();
    pushStyle();
    
    translate(0.3*width, 1.01*height, 0);
    translate(-kickerStillWidth / 2, -kickerStillHeight, 0);

    textureMode(NORMAL);
    beginShape();
        noStroke();
        texture(kickerStill);
        vertex(0, 0, 0, 0, 0);
        vertex(kickerStillWidth, 0, 0, 1, 0);
        vertex(kickerStillWidth, kickerStillHeight, 0, 1, 1);
        vertex(0, kickerStillHeight, 0, 0, 1);
    endShape();

    popStyle();
    popMatrix();
}


// Draws the football field on the screen: completely static
void drawAdverts() {
    int NUM_OF_ADS = 5; // Change this to have more/less adverts
    PImage[] images = new PImage[2];
    float advertWidth = (1.5*width)/float(NUM_OF_ADS);
    
    // Images from data folder
    images[0] = loadImage("adverts/PCS_logo.png");
    images[1] = loadImage("adverts/Qatar_logo.jpg");
    
    pushMatrix();
    pushStyle();
    
    translate(0, (height-fieldHeight), fieldDepth);
  
    for (int i = 0; i < NUM_OF_ADS; i += 1) {
        float adStart = -0.25*width + i*advertWidth;
        float adEnd = adStart + advertWidth;
        PImage currentImage = images[i % 2];
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

    // Crowd image from data folder
    crowdImage = loadImage("Crowd.jpg");
    
    pushMatrix();
    pushStyle();
    translate(0, 0, 1.2*fieldDepth);
    circle(0, 0, 16);
    
    crowdImage.resize(width, 0);

    textureMode(NORMAL);
    beginShape();
        noStroke();
        texture(crowdImage);
        vertex(-1.3*width, -0.9*crowdHeight, 0, 0, 0);
        vertex(1.3*width, -0.9*crowdHeight, 0, 1, 0);
        vertex(1.3*width, crowdHeight, 0, 1, 1);
        vertex(-1.3*width, crowdHeight, 0, 0, 1);
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
        textInsideBox((currentScoreboard == 'A' ? str(goalsA) : str(goalsB)), teamScoreBoxWidth, teamScoreHeight, #333333, #FFFFFF);
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
            int[] currentShots = (currentScoreboard == 'A' ? shotsA : shotsB);
            color goalIndicatorColor = (currentShots[j] == 0 ? #FFFFFF : 
                                        currentShots[j] == 1 ? #FFFF00 :
                                        currentShots[j] == 2 ? #00FF00 :
                                        #FF0000);
            fill(goalIndicatorColor);
            translate((circleDiameter + circleMargin), 0, 0);
            circle(0, 0, circleDiameter);
        }
    

        // Draw the final circle for each team, indicating who won
        color winnerIndicatorColor = (winner == 'O' ? #FFFFFF : 
                                     (winner == currentScoreboard) ? #00FF00 :
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
    String message;
    char header, segment1;
    int segment2, segment3;
  
    try {
        message = serialConnetion.readString();
        println("Mensagem recebida é: " + message.substring(0, message.length() - 1));  // debug
        
        // Error in case the transmission cannot be interpreted
        if (message.length() != 5) {
            println("ERRO: mensagem tem tamanho diferente de 4");
        } else {
            
            // Conversions
            header = message.charAt(0);
            segment1 = message.charAt(1);
            segment2 = unhex(message.substring(2, 3));
            segment3 = unhex(message.substring(3, 4));
            
            // If header is 0, the game has just been turned on
            if (header == '0') {
                println("JOGO COMEÇANDO");
                
                globalResetFunc(); // Reset all data structure and global variables
            }
            
            // If header is 1, a match has just begun
            else if (header == '1') {
                println("RODADA " + segment2 + ": JOGADOR " + segment1 + " BATENDO");
                
                updateRound(segment1, segment2); // Updates global variables
            }
            
            // If header is 2, the game is preparing itself for a new shot
            else if (header == '2') {
                println("JOGADOR JÁ PODE BATER");
                sounds.get("whistle").play();
            }
            
            // If header is 3, a shot has just happened, and we update the scoreboard
            else if (header == '3') {
                println("NOVO PLACAR:  A  |  B");
                println("              " + segment2 + "  |  " + segment3);
                println("DIRECAO: " + segment1);
                
                updateScoreboard(segment1, segment2, segment3);
            }
            
            // If header is 4, the match has ended, and we check who is the winner
            else if (header == '4') {
                println("FIM DO JOGO!!!!");
                println("PLACAR FINAL:  A  |  B");
                println("               " + segment2 + "  |  " + segment3);
                println("DIRECAO: " + segment1);
                
                endGame(segment1, segment2, segment3);
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


// Detects key pres and sends it to the serial port
void keyPressed() {
    whichKey = key;
    serialConnetion.write(key);
    println("Enviando tecla '" + key + "' para a porta serial.");
}


// Resets all match variables to begin a match anew.
void globalResetFunc() {
    for (int i = 0; i < shotsA.length; i += 1) {
        shotsA[i] = 0;
        shotsB[i] = 0;
    }
  
    round = 0;
    goalsA = 0;
    goalsB = 0;
    leftKicksA = 0;
    leftKicksB = 0;
    rightKicksA = 0;
    rightKicksB = 0;
    
    currentPlayer = 'A';
    winner = 'O'; // value shows winner has not been decided yet
}


// Updates match variables when a new shot is about to happen
void updateRound(char player_tx, int round_tx) {
    
    // Error conditions
    if ((round_tx < 0) || (round_tx > 16) || !((player_tx == 'A') || (player_tx == 'B'))) {
        println("ERRO: updateRound");
        println("round_tx: " + round_tx);
        println("player_tx: " + player_tx);

    } else {
        if (player_tx == 'A') {
            round = round_tx;
            shotsA[round] = 1;
        }
        else if (player_tx == 'B') {
            shotsB[round] = 1;
        }
        
        currentPlayer = player_tx;
    }
}


// Updates match variables after a shot has happened
void updateScoreboard(char direction_tx, int goalsA_tx, int goalsB_tx) {
    
    // Error conditions
    if (!(direction_tx == 'D' || direction_tx == 'E')
        || (goalsA_tx < 0 || goalsA_tx > 16 )
        || (goalsB_tx < 0 || goalsB_tx > 16 )) {
        println("ERRO: updateScoreboard");
        println("direction_tx: " + direction_tx);
        println("goalsA_tx: " + goalsA_tx);
        println("goalsB_tx: " + goalsB_tx);

    } else {
        kickDirection = direction_tx;
        
        if (currentPlayer == 'A') {
            if (kickDirection == 'E') {leftKicksA += 1;} else {rightKicksA += 1;}
            
            shotsA[round] = (goalsA_tx != goalsA) ? 2 : -1;
            goalsA = goalsA_tx;
        }
        else if (currentPlayer == 'B') {
            if (kickDirection == 'E') {leftKicksB += 1;} else {rightKicksB += 1;}
            
            shotsB[round] = (goalsB_tx != goalsB) ? 2 : -1;
            goalsB = goalsB_tx;
        }
    }
}


// Updates match variables (inclusing winner) after a match has ended
void endGame(char direction_tx, int goalsA_tx, int goalsB_tx) {
    updateScoreboard(direction_tx, goalsA_tx, goalsB_tx);
    winner = goalsA > goalsB ? 'A' : 'B';
    round += 1; // corrects num of rounds because it started at 0
    saveMatchToDatabase();
}


// After a match has finished, open the database to save its info
void saveMatchToDatabase() {
    if (client.connect()) {
        println("Escrevendo dados ao banco de dados!");
        client.saveMatch();
        client.disconnect();
    }
    else {
        println("ERRO: Incapaz de se conectar ao servidor.");
    }
}


void createSounds() {
  sounds.put("whistle", new SoundFile(this, "sounds/whistle.wav"));
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
