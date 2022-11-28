import processing.serial.*;      // serial comm lib
import processing.sound.*;       // sound lib
import java.awt.event.KeyEvent;  // keyboard reading lib
import java.sql.*;               // lib for interfacing with postgreSQL
import peasy.*;                  // cam lib
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


abstract class AnimatedObject {
    protected HashMap<String,PImage> images;
    protected PImage currentImage;
    
    protected boolean isMoving, completedMovement;
    protected float initialX, initialY, initialZ;
    protected float xPos, yPos, zPos;
    protected float movementPct;
        
    protected abstract void loadImages(); // Loads images based on team
    protected abstract void resizeImages(); // Resize images proportionally
    protected abstract void updateCurrentImage(); // Updates current image of player   
    protected abstract void moveObject(); // Animates object trajectory
    
    
    protected void resetDrawing() {
        this.xPos = this.initialX;
        this.yPos = this.initialY;
        this.zPos = this.initialZ;

        this.isMoving = false;
        this.completedMovement = false;
        this.movementPct = 0.0;
        
        this.updateCurrentImage();
    }
    
    protected void drawCurrentImage() {        
        float currentHeight = this.currentImage.height;
        float currentWidth = this.currentImage.width;
        
        pushMatrix();
        pushStyle();
        
        translate(this.xPos, this.yPos, this.zPos);
        translate(-currentWidth/2, -currentHeight, 0);
        
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
    
    public void drawObject() {
        if (this.isMoving) {
            this.moveObject();
        }
        
        this.drawCurrentImage();
    }
    
    public AnimatedObject(float initialX, float initialY, float initialZ) {        
        this.initialX = initialX;
        this.initialY = initialY;
        this.initialZ = initialZ;

        this.isMoving = false;
        this.completedMovement = false;
        
        this.images = new HashMap<String,PImage>();
    }
}


// Abtract class for creating players, such as Kickers or Goalkeepers
abstract class Player extends AnimatedObject {
    protected String team;
    
    public Player(String team, float initialX, float initialY, float initialZ) {
        super(initialX, initialY, initialZ);
        
        this.team = team;
        this.loadImages();
        this.resizeImages();
        this.resetDrawing();
    }
}


// Class to draw and keep info about Goalkeeper
class Kicker extends Player {
    
    private IntDict kicks;
    public char id;
    
    protected void loadImages() {
        this.images.put(
            "kicker_still", 
            loadImage(
                this.team == "Brazil" 
                ? "characters/brazil/Kicker_still.png" 
                : "characters/argentina/Kicker_still.png"
            )
        );
        this.images.put(
            "kicker_moving", 
            loadImage(
                this.team == "Brazil" 
                ? "characters/brazil/Kicker_moving.png" 
                : "characters/argentina/Kicker_moving.png"
            )
        );
    }
    
    protected void resizeImages() {
        float kickerHeight = 0.18*height;

        this.images.get("kicker_still").resize(0, int(kickerHeight));
        this.images.get("kicker_moving").resize(0, int(kickerHeight));
    }
    
    protected void moveObject() {
        float STEP = 0.01;  // Size of each step along the path
        float EXP = 4;  // Determines the curve
        float xDistanceToBall = 0.7*(width/2 - this.initialX);
        float zDistanceToBall = 0.9*(ballMarkerDepth - this.initialZ);
        
          this.movementPct += STEP;
          if (this.movementPct < 1.0) {
              this.xPos = this.initialX + (this.movementPct * xDistanceToBall);
              this.zPos = this.initialZ + (pow(this.movementPct, EXP) * zDistanceToBall);
          }
          else {
              this.completedMovement = true;
              this.updateCurrentImage();
          }
    }
    
    public void updateCurrentImage() {
        this.currentImage = this.images.get(this.completedMovement ? "kicker_moving" : "kicker_still");
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
        super(team, 0.35*width, 0, 0);
        
        this.id = (team == "Brazil") ? 'A' : 'B';
        this.kicks = new IntDict();
        this.kicks.set("D", 0);
        this.kicks.set("E", 0);
    };
}


// Class to draw and keep info about Goalkeeper
class Goalkeeper extends Player {
    
    private char direction; // ranges from 1 to 5
    
    protected void loadImages() {
        this.images.put(
            "goalkeeper_center", 
            loadImage(
                this.team == "Brazil" 
                ? "characters/brazil/Goalkeeper_center.png" 
                : "characters/argentina/Goalkeeper_center.png"
            )
        );
        this.images.put(
            "goalkeeper_left", 
            loadImage(
                this.team == "Brazil" 
                ? "characters/brazil/Goalkeeper_left.png" 
                : "characters/argentina/Goalkeeper_left.png"
            )
        );
        this.images.put(
            "goalkeeper_right", 
            loadImage(
                this.team == "Brazil" 
                ? "characters/brazil/Goalkeeper_right.png" 
                : "characters/argentina/Goalkeeper_right.png"
            )
        );
    }
    
    protected void resizeImages() {
        PImage goalkeeperCenterImage, goalkeeperLeftImage, goalkeeperRightImage;
        float goalkeeperCenterHeight = 0.2*height;
        float goalkeeperSidewaysHeight = 0.18*height;
        
        goalkeeperCenterImage = this.images.get("goalkeeper_center");
        goalkeeperCenterImage.resize(0, int(goalkeeperCenterHeight));
        
        goalkeeperLeftImage = this.images.get("goalkeeper_left");
        goalkeeperLeftImage.resize(0, int(goalkeeperSidewaysHeight));
        
        goalkeeperRightImage = this.images.get("goalkeeper_right");
        goalkeeperRightImage.resize(0, int(goalkeeperSidewaysHeight));
    }
    
    
    protected void moveObject() {
        float STEP = 0.01;  // Size of each step along the path
        float EXP = 2;  // Determines the curve
        int directionOffset = (this.direction == '1' || this.direction == '2')
                              ? 1
                              : (this.direction == '4' || this.direction == '5')
                              ? -1
                              : 0;
        float xDistanceToJumpPos = 0.65*directionOffset*(goalWidth/2 - this.initialX);
        float yDistanceToJumpPos = 0.15*(directionOffset != 0 ? 1 : 0)*(goalHeight - this.initialY);
        
          this.movementPct += STEP;
          if (this.movementPct < 1.0) {
              
              if (this.movementPct < 2*STEP) { // Only happens first time
                  this.updateCurrentImage();
              }
              
              this.xPos = this.initialX + (pow(this.movementPct, EXP) * xDistanceToJumpPos);
              this.yPos = this.initialY - (this.movementPct * yDistanceToJumpPos);
          }
    }
    
    protected void resetDrawing() {
        this.direction = '3';
        super.resetDrawing();
    };
    
    public void updateCurrentImage() {                         
        this.currentImage = this.images.get(
                            (this.direction == '1' || this.direction == '2')
                            ? "goalkeeper_left"
                            : (this.direction == '4' || this.direction == '5')
                            ? "goalkeeper_right"
                            : "goalkeeper_center"
        );
    }
    
    // Setter of the direction attribute
    public void setDirection(char newDirection) {
        this.direction = newDirection;
    }
    

    // Constructor
    public Goalkeeper(String team) {
        super(team, width/2, 0, endFieldLineDepth + 40);
    };
}


class Ball extends AnimatedObject {
    private PShape sphere;
    private float ballRadius = 0.01*width;
    private char trajectoryDirection;
    
    protected void drawCurrentImage() {        
        pushMatrix();
        pushStyle();
        
        translate(this.xPos, this.yPos, this.zPos);
        translate(0, -this.ballRadius, 0);

        shape(this.sphere);
    
        popStyle();
        popMatrix();
    }
    
    protected void loadImages() {
        this.images.put("ball_texture", loadImage("others/Pixel_football.png"));
    }
    
    protected void resizeImages() {
        PImage ballTexture = this.images.get("ball_texture");
        ballTexture.resize(0, int(5*this.ballRadius));
    }
    
    protected void moveObject() {
        float STEP = 0.01;  // Size of each step along the path
        float EXP = 2;  // Determines the curve
        float xDistanceToGoal = 0.85*(this.trajectoryDirection == 'E' ? 1 : -1)*(goalWidth/2 - this.initialX);
        float yDistanceToGoal = 0.70*(goalHeight - this.initialY);
        float zDistanceToGoal = 0.95*(endFieldLineDepth - this.initialZ);
        
          this.movementPct += STEP;
          if (this.movementPct < 1.0) {
              this.xPos = this.initialX + (pow(this.movementPct, EXP) * xDistanceToGoal);
              this.yPos = this.initialY - (pow(this.movementPct, EXP) * yDistanceToGoal);
              this.zPos = this.initialZ + (this.movementPct * zDistanceToGoal);
          }
    }
    
    public void updateCurrentImage() {
        sphere.setTexture(this.images.get("ball_texture"));
    }

    public Ball(float initialX, float initialY, float initialZ) {
        super(initialX, initialY, initialZ);
        
        pushStyle();
        noStroke();
        this.sphere = createShape(SPHERE, this.ballRadius);
        popStyle();
        
        this.loadImages();
        this.resizeImages();
        this.resetDrawing();
    }
}


class Match {
    private Kicker kickerA, kickerB;
    private Goalkeeper goalkeeperA, goalkeeperB;
    private int[] shotsA, shotsB;
    private boolean firstRender;
    
    public Kicker currentKicker;
    public Goalkeeper currentGoalkeeper;
    public Ball ball;
    public int round, goalsA, goalsB;
    public char winner;

    
    private void resetDrawings() {
        this.currentKicker.resetDrawing();
        this.currentGoalkeeper.resetDrawing();
        this.ball.resetDrawing();
    }


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
            
            serialConnetion.write('3'); // reset goalkeeper in digital circuit to middle position
            
            this.resetDrawings();
            
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
            this.currentKicker.updateKickCount(kickerDirection_tx);
            this.ball.trajectoryDirection = kickerDirection_tx;

            this.currentKicker.isMoving = true;
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
    
    public void drawPlayers() {
        if (this.firstRender) {
            this.kickerA = new Kicker("Brazil");
            this.kickerB = new Kicker("Argentina");
            this.goalkeeperA = new Goalkeeper("Brazil");
            this.goalkeeperB = new Goalkeeper("Argentina");
            this.ball = new Ball(width/2, 0, smallAreaLineDepth/2);
            
            this.currentKicker = this.kickerA;
            this.currentGoalkeeper = this.goalkeeperB;
            
            this.firstRender = false;
        }
        
        if (this.currentKicker.completedMovement) {
            this.ball.isMoving = true;
            this.currentGoalkeeper.isMoving = true;
            this.currentKicker.completedMovement = false;
        }
        
        this.ball.drawObject();
        this.currentGoalkeeper.drawObject();
        this.currentKicker.drawObject();
    }
    

    public Match() {        
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
        this.firstRender = true;
    };
}


// Global drawing parameters variables
float fieldWidth, fieldDepth;
float goalHeight, goalWidth, goalDepth;
float endFieldLineDepth, smallAreaLineDepth;
float ballMarkerDiameter, ballMarkerDepth;
float advertHeight;
float crowdWidth, crowdHeight;
boolean isFirstRender;

// Global object variables
PeasyCam cam;
Serial serialConnetion;
PostgresClient client;
Match currentMatch;

// Global hashmaps
HashMap<String,SoundFile> sounds = new HashMap<String,SoundFile>();
HashMap<String,PImage> otherImages = new HashMap<String,PImage>();


void setup() {
    // size(2400, 1800, P3D); // actual size to use
    // size(1400, 1050, P3D); // size when adjusting window position
    size(800, 600, P3D); // size for Palmiro's screen
    
    cam = new PeasyCam(this, width/2, -0.2*height, 0, 0.25*width);
    cam.setMaximumDistance(3*width);
    
    configureSerialComm();
    client = new PostgresClient();
    currentMatch = new Match();

    loadOtherImages();
    loadSounds();
    
    // sounds.get("background").loop();
    
    isFirstRender = true;
}


// Configures serial port for communication
void configureSerialComm() {
    String port = "COM3";   // <-- change value depending on machine
    int baudrate = 115200;  // 115200 bauds
    char parity = 'E';      // even
    int databits = 7;       // 7 data bits
    float stopbits = 2.0;   // 2 stop bits
    
    //int lf = 10;  // ASCII for linefeed -> actual value to use
    int lf = 46;  // ASCII for . -> use this for debugging
    
    serialConnetion = new Serial(this, port, baudrate, parity, databits, stopbits);
    serialConnetion.bufferUntil(lf);
}


// Fills global hashmap variable with all the sound effects used in sketch
void loadSounds() {
    SoundFile whistle = new SoundFile(this, "sounds/Whistle.wav");
    whistle.amp(0.1);
    
    sounds.put("background", new SoundFile(this, "sounds/Crowd_background_noise.wav"));
    sounds.put("whistle", whistle);
}


// Loads adverts images into global hashmap
void loadOtherImages() {
    otherImages.put("pcs_logo", loadImage("adverts/PCS_logo.png"));
    otherImages.put("qatar_logo", loadImage("adverts/Qatar_logo.jpg"));
    otherImages.put("crowd", loadImage("others/Pixel_crowd.jpg"));
}


void draw() {
    // Setting drawing variables
    fieldWidth = 2*width;
    fieldDepth = -0.8*width;
    endFieldLineDepth = 0.8*fieldDepth;
    smallAreaLineDepth = 0.4*fieldDepth;
    ballMarkerDiameter = 0.015*width;
    ballMarkerDepth = smallAreaLineDepth/2.0;
    goalHeight = 0.25*height;
    goalWidth = 0.55*width;
    goalDepth = -0.18*fieldDepth;
    advertHeight = 0.08*height;
    crowdWidth = 2.4*width;

    background(100);
    //lights();
    
    firstRender();
    
    drawField();
    drawGoal();
    drawAdverts();
    drawCrowd();
    drawScoreboardHUD();

    // For some reason, the order of drawing matters here:
    // to keep the background of characters transparent, render them last.
    currentMatch.drawPlayers(); 
}


// Draws the football field on the screen: completely static
void drawField() {
    int NUM_OF_SUBFIELDS = 4; // Change this to have more/less subfields
    float subfieldWidth = fieldWidth/float(NUM_OF_SUBFIELDS);
    int lineStroke = 6;
    float largeAreaLineDepth = 0.04*fieldDepth;

    pushMatrix();
    pushStyle();
    
    translate(width/2, 0, 0);

    // Subfields: parts of field with different shades of green
    for (int i = 0; i < NUM_OF_SUBFIELDS; i += 1) {
        float subfieldStart = -fieldWidth/2.0 + i*subfieldWidth;
        float subfieldEnd = subfieldStart + subfieldWidth;
        
        beginShape();
            noStroke();
            fill(boolean(i % 2) ? #13A30D : #13930D);
            vertex(subfieldStart, 0, fieldDepth);
            vertex(subfieldEnd, 0, fieldDepth);
            vertex(subfieldEnd, 0, -0.5*fieldDepth);
            vertex(subfieldStart, 0, -0.5*fieldDepth);
        endShape();
    }
    
    noFill();
    strokeWeight(lineStroke);
    stroke(#FFFFFF);
    
    // Line on the field: large area
    beginShape();
        vertex(-fieldWidth/3.0, 0, largeAreaLineDepth);
        vertex(fieldWidth/3.0, 0, largeAreaLineDepth);
        vertex(fieldWidth/3.0, 0, endFieldLineDepth);
        vertex(-fieldWidth/3.0, 0, endFieldLineDepth);
    endShape(CLOSE);
    
    // Line on the field: small area
    beginShape();
        vertex(-(goalWidth/2 + 0.05*width), 0, smallAreaLineDepth);
        vertex((goalWidth/2 + 0.05*width), 0, smallAreaLineDepth);
        vertex((goalWidth/2 + 0.05*width), 0, endFieldLineDepth);
        vertex(-(goalWidth/2 + 0.05*width), 0, endFieldLineDepth);
    endShape(CLOSE);
    
    // Line on the field: end of field
    beginShape();
        vertex(-fieldWidth/2.0, 0, endFieldLineDepth);
        vertex(fieldWidth/2.0, 0, endFieldLineDepth);
        vertex(fieldWidth/2.0, 0, endFieldLineDepth);
        vertex(-fieldWidth/2.0, 0, endFieldLineDepth);
    endShape();
     
    // Marking where ball should be
    pushMatrix();
        fill(#FFFFFF);
        translate(0, -1, ballMarkerDepth);
        rotateX(PI/2);
        circle(0, 0, ballMarkerDiameter);
    popMatrix();
    
    popStyle();
    popMatrix();
}


// Draws the goal on the screen: completely static
void drawGoal() {
    float goalPostThickness = 0.004*width;
    float goalNetThickness = 0.1*goalPostThickness;

    float d, h, w;
    float netSpace = (goalHeight*goalWidth*goalDepth)/1000000;

    pushMatrix();
    pushStyle();
    
    translate(width/2, 0, endFieldLineDepth);
    stroke(#EEEEEE);

    // Goal structure
    strokeWeight(goalPostThickness);

    line((-goalWidth/2), 0, 0, (-goalWidth/2), -goalHeight, 0);
    line((goalWidth/2), 0, 0, (goalWidth/2), -goalHeight, 0);
    line(
        (-goalWidth/2), -goalHeight, 0, 
        (goalWidth/2), -goalHeight, 0
    );

    // Goal net
    strokeWeight(goalNetThickness);

    h = 0;
    d = -goalDepth;
    while (d <= 0) {
        if (d < -goalDepth/2) {
            line((-goalWidth/2), h, d, (goalWidth/2), h, d);

            line((-goalWidth/2), h-(goalHeight/goalDepth)*netSpace, d+netSpace/2, (goalWidth/2), h-(goalHeight/goalDepth)*netSpace, d+netSpace/2);

            line((-goalWidth/2), 0, d, (-goalWidth/2), h, d);
            line((goalWidth/2), 0, d, (goalWidth/2), h, d);

            line((-goalWidth/2), h, 0, (-goalWidth/2), h, d);
            line((goalWidth/2), h, 0, (goalWidth/2), h, d);

            line((-goalWidth/2), h-(goalHeight/goalDepth)*netSpace, 0, (-goalWidth/2), h-(goalHeight/goalDepth)*netSpace, d+netSpace/2);
            line((goalWidth/2), h-(goalHeight/goalDepth)*netSpace, 0, (goalWidth/2), h-(goalHeight/goalDepth)*netSpace, d+netSpace/2);

            h -= (2*goalHeight/goalDepth)*netSpace;
        } else { // if (d >= -goalDepth/2)
            line((-goalWidth/2), -goalHeight, d, (goalWidth/2), -goalHeight, d);
            line((-goalWidth/2), 0, d, (-goalWidth/2), -goalHeight, d);
            line((goalWidth/2), 0, d, (goalWidth/2), -goalHeight, d);
        }
        d += netSpace; 
    }

    h += (goalHeight/goalDepth)*netSpace;
    line((-goalWidth/2), h, (-goalDepth/2), (-goalWidth/2), 0, -goalDepth);
    line((goalWidth/2), h, (-goalDepth/2), (goalWidth/2), 0, -goalDepth);

    w = -goalWidth/2+netSpace;
    while (w <= goalWidth/2) {
        line(w, -goalHeight, 0, w, -goalHeight, (-goalDepth/2));
        line(w, -goalHeight, (-goalDepth/2), w, 0, -goalDepth);
        w += netSpace;
    }

    // Triangle
    // h = 0;
    // d = -goalDepth;
    // while (d <= 0) {
    //     line((-goalWidth/2), h, d, (goalWidth/2), h, d);

    //     line((-goalWidth/2), 0, d, (-goalWidth/2), h, d);
    //     line((goalWidth/2), 0, d, (goalWidth/2), h, d);

    //     line((-goalWidth/2), h, 0, (-goalWidth/2), h, d);
    //     line((goalWidth/2), h, 0, (goalWidth/2), h, d);

    //     h -= (goalHeight/goalDepth)*netSpace;
    //     d += netSpace; 
    // }

    // w = -goalWidth/2;
    // while (w <= goalWidth/2) {
    //     line(w, -goalHeight, 0, w, 0, -goalDepth);
    //     w += netSpace;
    // }
    // line((goalWidth/2), -goalHeight, 0, (goalWidth/2), 0, -goalDepth);

    // line((-goalWidth/2), 0, 0, (-goalWidth/2), 0, -goalDepth);
    // line((goalWidth/2), 0, 0, (goalWidth/2), 0, -goalDepth);

    popStyle();
    popMatrix();
}


// Draws the football field on the screen: completely static
void drawAdverts() {
    int NUM_OF_ADS = 7; // Change this to have more/less adverts
    float advertWidth = (2*width)/float(NUM_OF_ADS);
    
    pushMatrix();
    pushStyle();
    
    translate(0, 0, fieldDepth);
  
    for (int i = 0; i < NUM_OF_ADS; i += 1) {
        float adStart = -0.5*width + i*advertWidth;
        float adEnd = adStart + advertWidth;
        PImage currentImage = otherImages.get(
            boolean(i % 2) 
            ? "pcs_logo" 
            : "qatar_logo"
        );
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
    PImage crowdTile = otherImages.get("crowd");
    
    pushMatrix();
    pushStyle();
    
    translate(width/2, 0, 1.2*fieldDepth);

    textureMode(NORMAL);
    beginShape();
        noStroke();
        textureWrap(REPEAT);
        texture(crowdTile);
        vertex(-crowdWidth/2, -2*crowdHeight, 0, 0, 0);
        vertex(crowdWidth/2, -2*crowdHeight, 0, 3, 0);
        vertex(crowdWidth/2, 0, 0, 3, 2);
        vertex(-crowdWidth/2, 0, 0, 0, 2);
    endShape();

    popStyle();
    popMatrix();
}


// Draws a dynamic scoreboard, showing the number of points
// for each team, as well as which shots were goals, etc.
void drawScoreboardHUD() {

    float scoreboardX = 0.06 * width;
    float scoreBoardY = 0.06 * height;
    float teamScoreHeight = 0.045 * height;
    
    int teamNameBoxWidth = 120;
    int teamScoreBoxWidth = 40;
    int penaltyPointsBoxWidth = 240;
    
    int teamMarkerWidth = 8;
    int circleDiameter = 16;
    int circleMargin = 16;
    int dividerHeight = 1;
  
    float dividerWidth = teamNameBoxWidth + teamScoreBoxWidth + penaltyPointsBoxWidth;
    float lineOffset = teamNameBoxWidth 
                     + teamScoreBoxWidth 
                     + 5*(circleDiameter + circleMargin) 
                     + 1.5*circleMargin;

    cam.beginHUD();
    
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
        textInsideBox(
            (currentScoreboard == 'A' ? "Brasil" : "Argentina"), 
            teamNameBoxWidth, 
            teamScoreHeight, 
            #CBB75D, 
            #443514
        );
        translate(teamNameBoxWidth, 0, 0);
        
        // Draws the current score for each team
        textInsideBox(
            (currentScoreboard == 'A' 
             ? str(currentMatch.goalsA) 
             : str(currentMatch.goalsB)
            ),
            teamScoreBoxWidth, 
            teamScoreHeight, 
            #333333, 
            #FFFFFF
        );
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
        color winnerIndicatorColor = (
            currentMatch.winner == 'O' 
            ? #FFFFFF 
            : ((currentMatch.winner == currentScoreboard) 
               ? #00FF00 
               : #FF0000
            )
        );
                                      
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
    
    cam.endHUD();
}


// Decodes message received with serial transmission
void serialEvent (Serial serialConnetion) {
    int MSG_SIZE = 3;
    String buffer, message, segment1;
    int segment2;
    char header;
  
    try {
        // Reads last 3 characters from buffer as the intended message
        buffer = serialConnetion.readString();
        
        if (buffer.length() < MSG_SIZE + 1) {throw new Exception("ERRO: mensagem tem tamanho menor que 3.");}
        
        message = buffer.substring(buffer.length() - (MSG_SIZE + 1), buffer.length() - 1);
        
        // Debug
        println("Mensagem recebida é: " + message);
        
        // Conversions
        header = message.charAt(0);
        segment1 = message.substring(1, 2);
        segment2 = unhex(message.substring(2, 3));
        
        // If header is 0, the game has just been turned on
        if (header == '0') {
            println("PARTIDA COMEÇANDO");
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
    } catch(Exception e) {
      e.printStackTrace();
    }
}


// Detects key press and sends it to the serial port
void keyPressed() {

    
    // Use this during real games
    //if (key == '1' || key == '2' || key == '3' || key == '4' || key == '5') {
    //    println("Enviando tecla '" + key + "' para a porta serial.");
    //    serialConnetion.write(key);
    //    currentMatch.currentGoalkeeper.setDirection(key);
    //}
    
    // Debug
    println("Enviando tecla '" + key + "' para a porta serial.");
    serialConnetion.write(key);
    if (key == 'G') {
        currentMatch.currentGoalkeeper.setDirection('1');
    }
    else if (key == 'H') {
        currentMatch.currentGoalkeeper.setDirection('2');
    }
    else if (key == 'J') {
        currentMatch.currentGoalkeeper.setDirection('3');
    }
    else if (key == 'K') {
        currentMatch.currentGoalkeeper.setDirection('4');
    }
    else if (key == 'L') {
        currentMatch.currentGoalkeeper.setDirection('5');
    }
}


// Helper function to draw a certain text inside a box of a different color
void textInsideBox(
    String text, 
    float width, 
    float height, 
    color boxColor, 
    color textColor
) {
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


void firstRender() {
    if (isFirstRender) {
        // Crowd image from data folder
        PImage crowdImage = otherImages.get("crowd");
        crowdImage.resize(int(crowdWidth/3), 0);
        crowdHeight = crowdImage.height;
        otherImages.put("crowd", crowdImage);
    
        isFirstRender = false;
    }
}
