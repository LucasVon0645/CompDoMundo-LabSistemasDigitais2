import processing.serial.*;      // serial comm lib
import processing.sound.*;       // sound lib
import java.awt.event.KeyEvent;  // keyboard reading lib
import java.sql.*;               // lib for interfacing with postgreSQL
import peasy.*;                  // cam lib
import java.io.IOException;
import java.util.Map;
import java.util.Random;


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

    private String createQuery(String column, int numMatches) {
        String query = "SELECT SUM(" + column + ") FROM (";
        query += "SELECT " + column + " FROM matches_statistics ";
        query += "ORDER BY match_id DESC LIMIT " + str(numMatches);
        query += ") AS last_matches";

        return query;
    }

    // Get suggestion variables from the db using the previous matches info
    public void getSuggestionsFromDatabase(int numMatches) {
        if (this.connect()) {
            println("Lendo dados do banco de dados!");
            
            try {     
                String[] queries = new String[4];
                ResultSet rs;
                int[] results = new int[4];

                queries[0] = createQuery("left_kicks", numMatches);
                queries[1] = createQuery("right_kicks", numMatches);
                queries[2] = createQuery("goals_with_left_kicks", numMatches);
                queries[3] = createQuery("goals_with_right_kicks", numMatches);

                for (int i = 0; i < 4; i++) {
                    pstmt = conn.prepareStatement(queries[i]);    
                    rs = pstmt.executeQuery();

                    while (rs.next()) {
                        results[i] = rs.getInt(1);
                    }

                    pstmt.close();
                }
                
                conn.commit();

                int leftKicks = results[0];
                int rightKicks = results[1];
                int goalsWithLeftKicks = results[2];
                int goalsWithRightKicks = results[3];

                float leftKickProb = 100 * goalsWithLeftKicks / (leftKicks + rightKicks);
                float rightKickProb = 100 * goalsWithRightKicks / (leftKicks + rightKicks);

                hitProb = (leftKickProb >= rightKickProb) ? leftKickProb : rightKickProb;
                suggestedDirection = (leftKickProb >= rightKickProb) ? "esquerda" : "direita";
                
            } catch (Exception e) {
                println(e.getClass().getName() + ": " + e.getMessage());
            }
            
            this.disconnect();
        }
        else {
            println("ERRO: Incapaz de se conectar ao servidor.");
        }
    }
    
    // Save a match to the db using the latest match info
    public void saveMatchToDatabase(Match match) {
        if (this.connect()) {
            println("Escrevendo dados ao banco de dados!");
            
            try {
                long now = System.currentTimeMillis();
                Timestamp timestamp = new Timestamp(now);
                
                String query = "INSERT INTO matches_statistics ";
                query += "(timestamp, winner, rounds, goals_by_a, goals_by_b, left_kicks, ";
                query += "right_kicks, goals_with_left_kicks, goals_with_right_kicks) ";
                query += "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
                
                pstmt = conn.prepareStatement(query);
                pstmt.setTimestamp(1, timestamp);
                pstmt.setString(2, String.valueOf(match.winner));
                pstmt.setInt(3, match.round);
                pstmt.setInt(4, match.goalsA);
                pstmt.setInt(5, match.goalsB);
                pstmt.setInt(6, match.leftKicks);
                pstmt.setInt(7, match.rightKicks);
                pstmt.setInt(8, match.goalsWithLeftKicks);
                pstmt.setInt(9, match.goalsWithRightKicks);
    
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
    private Random rand = new Random();
    
    protected float ANIMATION_SPEED = 1.6;
    protected float RANDOM_FLOAT;
    
    protected HashMap<String,PImage> images;
    protected PImage currentImage;
    protected boolean isMoving, completedMovement;
    protected float initialX, initialY, initialZ;
    protected float xPos, yPos, zPos;
    protected float movementPct;
        
    protected abstract void loadImages(); // Loads images based on team
    protected abstract void updateCurrentImage(); // Updates current image of player   
    protected abstract void moveObject(); // Animates object trajectory
    
    protected void updateRandomFloat() {
        this.RANDOM_FLOAT = this.rand.nextFloat();
    }
    
    protected void resetDrawing() {
        this.xPos = this.initialX;
        this.yPos = this.initialY;
        this.zPos = this.initialZ;

        this.isMoving = false;
        this.completedMovement = false;
        this.movementPct = 0.0;
        
        this.updateCurrentImage();
        this.updateRandomFloat();
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
        this.updateRandomFloat();
    }
}


// Abtract class for creating players, such as Kickers or Goalkeepers
abstract class Player extends AnimatedObject {
    protected String team;

    protected abstract void resetPlayer();
    
    public Player(String team, float initialX, float initialY, float initialZ) {
        super(initialX, initialY, initialZ);
        
        this.team = team;
        this.loadImages();
        this.resetDrawing();
    }
}


// Class to draw and keep info about Goalkeeper
class Kicker extends Player {
    
    private IntDict kicks;
    public char id;
    
    protected void loadImages() {
        PImage kickerStillImage = loadImage(
                                    this.team == "Brazil" 
                                    ? "characters/brazil/Kicker_still.png" 
                                    : "characters/argentina/Kicker_still.png"
        );
        PImage kickerMovingImage = loadImage(
                                        this.team == "Brazil" 
                                        ? "characters/brazil/Kicker_moving.png" 
                                        : "characters/argentina/Kicker_moving.png"
        );
        
        float kickerHeight = 0.18*height;

        
        kickerStillImage.resize(0, int(kickerHeight));
        this.images.put("kicker_still", kickerStillImage);
        
        kickerMovingImage.resize(0, int(kickerHeight));
        this.images.put("kicker_moving", kickerMovingImage);
    }
    
    protected void moveObject() {
        float STEP = 0.01 * this.ANIMATION_SPEED;  // Size of each step along the path
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

    protected void resetPlayer() {
        this.kicks.set("D", 0);
        this.kicks.set("E", 0);
        this.resetDrawing();
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
        PImage goalkeeperCenterImage = loadImage(
                                        this.team == "Brazil" 
                                        ? "characters/brazil/Goalkeeper_center.png" 
                                        : "characters/argentina/Goalkeeper_center.png"
        );
        PImage goalkeeperLeftImage = loadImage(
                                        this.team == "Brazil" 
                                        ? "characters/brazil/Goalkeeper_left.png" 
                                        : "characters/argentina/Goalkeeper_left.png"
        );
        PImage goalkeeperRightImage = loadImage(
                                        this.team == "Brazil" 
                                        ? "characters/brazil/Goalkeeper_right.png" 
                                        : "characters/argentina/Goalkeeper_right.png"
        );
                                       
        float goalkeeperCenterHeight = 0.2*height;
        float goalkeeperSidewaysHeight = 0.18*height;
        
        goalkeeperCenterImage.resize(0, int(goalkeeperCenterHeight));
        this.images.put("goalkeeper_center", goalkeeperCenterImage);
        
        goalkeeperLeftImage.resize(0, int(goalkeeperSidewaysHeight));
        this.images.put("goalkeeper_left", goalkeeperLeftImage);
        
        goalkeeperRightImage.resize(0, int(goalkeeperSidewaysHeight));
        this.images.put("goalkeeper_right", goalkeeperRightImage);
    }
    
    protected void moveObject() {
        float STEP = 0.01 * this.ANIMATION_SPEED;  // Size of each step along the path
        float EXP = 2;  // Determines the curve
        int directionOffset = (this.direction == '1' || this.direction == '2')
                              ? 1
                              : (this.direction == '4' || this.direction == '5')
                              ? -1
                              : 0;
        float xDistanceToJumpPos = (0.3 + this.RANDOM_FLOAT * 0.40)*directionOffset*(goalWidth/2 - this.initialX);
        float yDistanceToJumpPos = (0.05 + this.RANDOM_FLOAT * 0.15)*(directionOffset != 0 ? 1 : 0)*(goalHeight - this.initialY);
        
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
    }

    protected void resetPlayer() { // Redundant, but keeps things organized
        this.resetDrawing();
    }
    
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
        this.direction = '3';
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
        PImage ballTexture = loadImage("others/Pixel_football.png");
        ballTexture.resize(0, int(5*this.ballRadius));
        this.images.put("ball_texture", ballTexture);
    }
    
    protected void moveObject() {
        float STEP = 0.01 * this.ANIMATION_SPEED;  // Size of each step along the path
        float EXP = 2;  // Determines the curve
        float xDistanceToGoal = (0.55 + this.RANDOM_FLOAT * 0.40)*(this.trajectoryDirection == 'E' ? 1 : -1)*(goalWidth/2 - this.initialX);
        float yDistanceToGoal = (0.45 + this.RANDOM_FLOAT * 0.40)*(goalHeight - this.initialY);
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
    public int round, leftKicks, rightKicks, goalsA, goalsB, goalsWithLeftKicks, goalsWithRightKicks;
    public char winner, lastKickerDirection;

    
    private void resetDrawings() {
        this.currentKicker.resetDrawing();
        this.currentGoalkeeper.resetDrawing();
        this.ball.resetDrawing();
    }

    public boolean detectGoalOfA(int goalsA_tx) {
        return (goalsA_tx > this.goalsA);
    }

    public boolean detectGoalOfB(int goalsB_tx) {
        return (goalsB_tx > this.goalsB);
    }

    public void updateGoalsByDirection(int goalsA_tx, int goalsB_tx) {
        if (detectGoalOfA(goalsA_tx) || detectGoalOfB(goalsB_tx)) {
            this.goalsWithLeftKicks += (this.lastKickerDirection == 'E') ? 1 : 0;
            this.goalsWithRightKicks += (this.lastKickerDirection == 'D') ? 1 : 0;
        }
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
            this.leftKicks += (kickerDirection_tx == 'E') ? 1 : 0;
            this.rightKicks += (kickerDirection_tx == 'D') ? 1 : 0;
            this.lastKickerDirection = kickerDirection_tx;

            this.currentKicker.updateKickCount(kickerDirection_tx);
            this.ball.trajectoryDirection = kickerDirection_tx;

            this.currentKicker.isMoving = true;
        }
    }
    
    // Updates match variables after a shot has happened
    public void updateScore(int goalsA_tx, int goalsB_tx) {
        
        // Error conditions
        if ((goalsA_tx < 0 || goalsA_tx > 16 ) || (goalsB_tx < 0 || goalsB_tx > 16 )) {
            println("ERRO: updateScoreboard");
            println("goalsA_tx: " + goalsA_tx);
            println("goalsB_tx: " + goalsB_tx);
    
        } else {
            if (this.currentKicker.id == 'A') {
                this.setCurrentShot(detectGoalOfA(goalsA_tx) ? 2 : -1);
                this.goalsA = goalsA_tx;
            }
            else if (this.currentKicker.id == 'B') {
                this.setCurrentShot(detectGoalOfB(goalsB_tx) ? 2 : -1);
                this.goalsB = goalsB_tx;
            }
        }
    }
    
    public void endMatch(int goalsA_tx, int goalsB_tx) {
        this.updateScore(goalsA_tx, goalsB_tx);
        
        this.winner = (this.goalsA > this.goalsB) ? 'A' : 'B';
        this.round += 1; // corrects num of rounds because it started at 0
        
        this.resetDrawings();
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
    
    public void resetMatch() {
        this.round = 0;
        this.goalsA = 0;
        this.goalsB = 0;

        for (int i = 0; i < shotsA.length; i += 1) {
            this.shotsA[i] = 0;
            this.shotsB[i] = 0;
        }

        this.kickerA.resetPlayer();
        this.kickerB.resetPlayer();
        this.goalkeeperA.resetPlayer();
        this.goalkeeperB.resetPlayer();
        this.ball.resetDrawing();
        
        this.currentKicker = this.kickerA;
        this.currentGoalkeeper = this.goalkeeperB;
        
        this.winner = 'O';
    }
    

    public Match() {        
        this.round = 0;
        this.leftKicks = 0;
        this.rightKicks = 0;
        this.goalsA = 0;
        this.goalsB = 0;
        this.goalsWithLeftKicks = 0;
        this.goalsWithRightKicks = 0;
        
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

abstract class Banner {
    protected boolean isShowing;
    protected float showPct;
    protected HashMap<String,PImage> images;
    protected float bannerHeight = 0.4*height;
    
    protected abstract void loadImages();
    protected abstract void drawBannerContent();
    
    protected void drawBanner() {
        float STEP = 0.02;

        if (this.isShowing && this.showPct < 1.0) {
            this.showPct += STEP;
        }
        else if (!this.isShowing && this.showPct > 0) {
            this.showPct -= STEP;
        }
        
        this.drawBannerContent();
    }
    
    public Banner(boolean isShowing) {
        this.isShowing = isShowing;
        this.showPct = (isShowing ? 1.0 : 0.0);
        this.images = new HashMap<String,PImage>();
    }
}


class StartBanner extends Banner {
    private float imageHeight = 0.8*this.bannerHeight;
    
    protected void loadImages() {
        PImage compDoMundoLogo = loadImage("logos/Comp_logo.png");
        compDoMundoLogo.resize(0, int(this.imageHeight));
        this.images.put("comp_do_mundo_logo", compDoMundoLogo);
    }
    
    public void drawBannerContent() {
        PImage startLogo = this.images.get("comp_do_mundo_logo");
        float logoWidth = startLogo.width;
        
        pushMatrix();
        pushStyle();
        
        translate(width/2, height/2, 0);
        
        beginShape();
            noStroke();
            fill(64, 64, 64, this.showPct*200);
            vertex(-width/2.0, this.bannerHeight/2, 0);
            vertex(width/2.0, this.bannerHeight/2, 0);
            vertex(width/2.0, -this.bannerHeight/2, 0);
            vertex(-width/2.0, -this.bannerHeight/2, 0);
        endShape();
        
        textureMode(NORMAL);
        beginShape();
            noStroke();
            tint(255, this.showPct*255);
            texture(startLogo);
            vertex(-logoWidth/2, -this.imageHeight/2, 0, 0, 0);
            vertex(logoWidth/2, -this.imageHeight/2, 0, 1, 0);
            vertex(logoWidth/2, this.imageHeight/2, 0, 1, 1);
            vertex(-logoWidth/2, this.imageHeight/2, 0, 0, 1);
        endShape();
        
        popStyle();
        popMatrix();
    }
    
    public StartBanner() {
        super(true);
        this.loadImages();
    }
}


class ScoreBanner extends Banner {
    private float imageHeight = 0.8*this.bannerHeight;
    private Match matchToShow;
    
    protected void loadImages() {
        PImage cbfLogo = loadImage("logos/CBF_logo.png");
        cbfLogo.resize(0, int(this.imageHeight));
        this.images.put("cbf_logo", cbfLogo);
        
        PImage afaLogo = loadImage("logos/AFA_logo.png");
        afaLogo.resize(0, int(this.imageHeight));
        this.images.put("afa_logo", afaLogo);
    }
    
    public void drawBannerContent() {
        PImage cbfLogo = this.images.get("cbf_logo");
        PImage afaLogo = this.images.get("afa_logo");
        float cbfLogoWidth = cbfLogo.width;
        float afaLogoWidth = afaLogo.width;
        
        pushMatrix();
        pushStyle();
        
        translate(width/2, height/2, 0);
        
        beginShape();
            noStroke();
            fill(64, 64, 64, this.showPct*200);
            vertex(-width/2.0, bannerHeight/2, 0);
            vertex(width/2.0, bannerHeight/2, 0);
            vertex(width/2.0, -bannerHeight/2, 0);
            vertex(-width/2.0, -bannerHeight/2, 0);
        endShape();
        
        textSize(0.75*this.imageHeight);
        
        // Brazil side
        pushMatrix();
        pushStyle();
            translate(-width/3, 0, 0);
            
            textureMode(NORMAL);
            beginShape();
                noStroke();
                tint(255, this.showPct*255);
                texture(cbfLogo);
                vertex(-cbfLogoWidth/2, -this.imageHeight/2, 0, 0, 0);
                vertex(cbfLogoWidth/2, -this.imageHeight/2, 0, 1, 0);
                vertex(cbfLogoWidth/2, this.imageHeight/2, 0, 1, 1);
                vertex(-cbfLogoWidth/2, this.imageHeight/2, 0, 0, 1);
            endShape();
        
            translate(0.18*width, 0, 0);
            fill(255, this.showPct*255);
            rectMode(CENTER);
            textAlign(CENTER, CENTER);
            text(str(matchToShow.goalsA), 0, 0, width, height);
        popStyle();
        popMatrix();
        
        // x in the middle
        pushStyle();
            textSize(0.6*this.imageHeight);
            fill(255, this.showPct*255);
            rectMode(CENTER);
            textAlign(CENTER, CENTER);
            text("x", 0, 0, width, height); 
        popStyle();
        
        // Argentina side
        pushMatrix();
        pushStyle();
            translate(width/3, 0, 0);
            
            textureMode(NORMAL);
            beginShape();
                noStroke();
                tint(255, this.showPct*255);
                texture(afaLogo);
                vertex(-afaLogoWidth/2, -this.imageHeight/2, 0, 0, 0);
                vertex(afaLogoWidth/2, -this.imageHeight/2, 0, 1, 0);
                vertex(afaLogoWidth/2, this.imageHeight/2, 0, 1, 1);
                vertex(-afaLogoWidth/2, this.imageHeight/2, 0, 0, 1);
            endShape();
            
            translate(-0.18*width, 0, 0);
            fill(255, this.showPct*255);
            rectMode(CENTER);
            textAlign(CENTER, CENTER);
            text(str(matchToShow.goalsB), 0, 0, width, height);
        popStyle();
        popMatrix();
        
        popStyle();
        popMatrix();
    }
    
    public ScoreBanner(Match match) {
        super(false);
        this.matchToShow = match;
        this.loadImages();
    }
}


class GoalBanner extends Banner {
    private float goalBannerHeight = 0.2*height;
    private float goalTextX, proxGoalTextX;
    private int exibitionTime;
    
    protected void loadImages() {};

    protected void drawBannerContent() {
        int TIME_LIMIT = 300;

        int goalTextSize = int(0.8*this.goalBannerHeight);
        float goalTextY = this.goalBannerHeight/4;
        float goalTextVx = width/80;
        String goalText = "GOOOOOL!!!";
        
        if (this.isShowing) {
            if (this.exibitionTime >= TIME_LIMIT) {
                this.isShowing = false;
            } else {
                this.exibitionTime += 1;
            }
        }

        pushMatrix();
        pushStyle();

        translate(0, height/2, 0);

        // Goal banner text box
        beginShape();
            noStroke();
            fill(64, 64, 64, this.showPct*200);
            vertex(0, this.goalBannerHeight/2, 0);
            vertex(width, this.goalBannerHeight/2, 0);
            vertex(width, -this.goalBannerHeight/2, 0);
            vertex(0, -this.goalBannerHeight/2, 0);
        endShape();

        // Goal banner text            
        fill(255, 255, 255, this.showPct*255);
        textMode(SHAPE);
        textSize(goalTextSize);
        text(goalText, goalTextX, goalTextY);

        proxGoalTextX = goalTextX + goalTextVx;
        goalTextX = (proxGoalTextX > width) ? -textWidth(goalText) : proxGoalTextX;

        popStyle();
        popMatrix();
    }

    public GoalBanner() {
        super(false);
        this.goalTextX = 0;
        this.exibitionTime = 0;
    }
}


class HUD {   
    private Match match;
    private StartBanner startBanner;
    private ScoreBanner endmatchBanner;
    private GoalBanner goalBanner;

    private boolean isShowingSuggestion;
    private float showSuggestionPct;

    // Draws a dynamic scoreboard, showing the number of points
    // for each team, as well as which shots were goals, etc.
    private void drawScoreboard() { 
        float scoreboardX = 0.06 * width;
        float scoreBoardY = 0.06 * height;
        float teamScoreHeight = 0.045 * height;
        
        float teamNameBoxWidth = 5*teamScoreHeight;
        float teamScoreBoxWidth = teamScoreHeight;
        float penaltyPointsBoxWidth = 5.2*teamScoreHeight;
        
        float teamMarkerWidth = 0.2*teamScoreHeight;
        float circleDiameter = 0.35*teamScoreHeight;
        float circleMargin = circleDiameter;
        int dividerHeight = 1;
      
        float dividerWidth = teamNameBoxWidth + teamScoreBoxWidth + penaltyPointsBoxWidth;
        float lineOffset = teamNameBoxWidth 
                         + teamScoreBoxWidth 
                         + 5*(circleDiameter + circleMargin) 
                         + 1.5*circleMargin;
        
        pushMatrix();
        pushStyle();
        
        translate(scoreboardX, scoreBoardY, 0);
        textSize(0.5*teamScoreHeight);
        
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
                 ? str(this.match.goalsA) 
                 : str(this.match.goalsB)
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
                fill(64, 64, 64, 200);
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
                int[] currentShots = this.match.getShots(currentScoreboard);
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
                this.match.winner == 'O' 
                ? #FFFFFF 
                : ((this.match.winner == currentScoreboard) 
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
        strokeWeight(0.1*circleDiameter);
        stroke(#FFFFFF);
        line(0, -8, 0, 0, teamScoreHeight + 8, 0);
    
        popStyle();
        popMatrix();
    }

    // Draws a suggestion banner, showing kick direction and goal
    // occurrence stats in previous matches
    void drawSuggestion() {
        float STEP = 0.05;
        float suggestionX = 0.50 * width;
        float suggestionY = 0.06 * height;
        float suggestionWidth = 0.44 * width;
        float suggestionHeight = 0.045 * height;
        color textColor = #443514;
        String text = "Chute para a " + suggestedDirection + " (" + str(hitProb) + "% de chance de acerto)";
       
        if (this.isShowingSuggestion && this.showSuggestionPct < 1.0) {
            this.showSuggestionPct += STEP;
        }
        else if (!this.isShowingSuggestion && this.showSuggestionPct > 0) {
            this.showSuggestionPct -= STEP;
        }
        
        pushMatrix();
        pushStyle();

        translate(suggestionX, suggestionY, 0);

        fill(203, 183, 93, this.showSuggestionPct*225);
        noStroke();
        rect(0, 0, suggestionWidth, suggestionHeight, (suggestionWidth/100));
        
        fill(textColor, this.showSuggestionPct*255);
        rectMode(CORNER);
        textAlign(CENTER, CENTER);
        textSize(0.02*height);
        text(text, 0, 0, suggestionWidth, suggestionHeight); 

        popStyle();
        popMatrix();
    }
    
    public void zoomOut() {
       cam.lookAt(width/2, -0.20*height, 0, 0.25*width, 2000);
       this.startBanner.isShowing = false;
       this.endmatchBanner.isShowing = false;
    }
    
    public void zoomIn() {
       this.endmatchBanner.isShowing = true;
       cam.reset(2000);
    }

    public void showGoalBanner() {
        this.goalBanner.goalTextX = -width/2;
        this.goalBanner.exibitionTime = 0;
        this.goalBanner.isShowing = true;
    }

    public void showSuggestionHUD() {
        this.isShowingSuggestion = true;
    }

    public void hideSuggestionHUD() {
        this.isShowingSuggestion = false;
    }
    
    public void drawHUD() {
        cam.beginHUD();
        
        this.drawScoreboard();
        this.drawSuggestion();

        this.startBanner.drawBanner();
        this.endmatchBanner.drawBanner();
        this.goalBanner.drawBanner();
        
        cam.endHUD();
    }
    
    public void loadBanners() {
        this.startBanner = new StartBanner();
        this.endmatchBanner = new ScoreBanner(this.match);
        this.goalBanner = new GoalBanner();
    }

    public HUD(Match match) {
        this.isShowingSuggestion = false;
        this.match = match;
    }
}


// Global drawing parameters variables
float fieldWidth, fieldDepth;
float goalHeight, goalWidth, goalDepth;
float endFieldLineDepth, smallAreaLineDepth;
float ballMarkerDiameter, ballMarkerDepth;
float advertHeight;
float crowdWidth, crowdHeight;
boolean isFirstRender;
String suggestedDirection;
float hitProb;

// Global object variables
PeasyCam cam;
HUD hud;
Serial serialConnetion;
PostgresClient client;
Match currentMatch;
PFont qatarFont;

// Global hashmaps
HashMap<String,SoundFile> sounds = new HashMap<String,SoundFile>();
HashMap<String,PImage> otherImages = new HashMap<String,PImage>();


void setup() {
    //size(3600, 1800, P3D);    // size for biger full screens
    size(2400, 1800, P3D);    // size for bigger screens
    //size(1400, 1050, P3D);  // size for medium size screens
    //size(800, 600, P3D);    // size for smaller screens
    
    qatarFont = createFont("Qatar2022 Arabic Heavy", 320);
    textFont(qatarFont);
    
    
    cam = new PeasyCam(this, width/2, -0.1*height, 0, 0.04*width);
    // Uncomment this for different camera positionS
    //cam = new PeasyCam(this, width/2, -0.20*height, 0, 0.25*width);
    //
    //cam = new PeasyCam(this, width/2, -0.21*height, 0, 0.25*width);
    //cam.rotateX(0.1);
    cam.setMaximumDistance(3*width);

    currentMatch = new Match();
    hud = new HUD(currentMatch);
    client = new PostgresClient();

    configureSerialComm();
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
    SoundFile brasil = new SoundFile(this, "sounds/Brasil_sil_sil.wav");

    whistle.amp(0.1);
    brasil.amp(0.1);
    
    sounds.put("background", new SoundFile(this, "sounds/Crowd_background_noise.wav"));
    sounds.put("whistle", whistle);
    sounds.put("brasil", brasil);
}


// Loads adverts images into global hashmap
void loadOtherImages() {
    otherImages.put("pcs_logo", loadImage("adverts/PCS_logo.png"));
    otherImages.put("comp_logo", loadImage("adverts/CompDoMundo_ad.png"));
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
    advertHeight = 0.094*height;
    crowdWidth = 2.4*width;

    background(100);
    //lights();
    
    firstRender();
    
    drawField();
    drawGoal();
    drawAdverts();
    drawCrowd();

    currentMatch.drawPlayers();

    hud.drawHUD();
}


// Draws the football field on the screen: completely static
void drawField() {
    int NUM_OF_SUBFIELDS = 4; // Change this to have more/less subfields
    float subfieldWidth = fieldWidth/float(NUM_OF_SUBFIELDS);
    int lineStroke = 16;
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

    
    // Line on the field: large area
    beginShape();
        noStroke();
        fill(#FFFFFF);
        vertex(-fieldWidth/3.0, -1, largeAreaLineDepth);
        vertex(-fieldWidth/3.0 + lineStroke, -1, largeAreaLineDepth);
        vertex(-fieldWidth/3.0 + lineStroke, -1, endFieldLineDepth);
        vertex(-fieldWidth/3.0, -1, endFieldLineDepth);
    endShape();
    
    beginShape();
        noStroke();
        fill(#FFFFFF);
        vertex(fieldWidth/3.0 + lineStroke, -1, largeAreaLineDepth);
        vertex(fieldWidth/3.0, -1, largeAreaLineDepth);
        vertex(fieldWidth/3.0, -1, endFieldLineDepth);
        vertex(fieldWidth/3.0 + lineStroke, -1, endFieldLineDepth);
    endShape();
    
    beginShape();
        noStroke();
        fill(#FFFFFF);
        vertex(-fieldWidth/3.0, -1, largeAreaLineDepth + lineStroke);
        vertex(fieldWidth/3.0, -1, largeAreaLineDepth + lineStroke);
        vertex(fieldWidth/3.0, -1, largeAreaLineDepth);
        vertex(-fieldWidth/3.0, -1, largeAreaLineDepth);
    endShape();
    
    beginShape();
        noStroke();
        fill(#FFFFFF);
        vertex(-fieldWidth/3.0, -1, endFieldLineDepth + lineStroke);
        vertex(fieldWidth/3.0, -1, endFieldLineDepth + lineStroke);
        vertex(fieldWidth/3.0, -1, endFieldLineDepth);
        vertex(-fieldWidth/3.0, -1, endFieldLineDepth);
    endShape();

    // Small square
    beginShape();
        noStroke();
        fill(#FFFFFF);
        vertex(fieldWidth/3.0, -1, largeAreaLineDepth);
        vertex(fieldWidth/3.0 + lineStroke, -1, largeAreaLineDepth);
        vertex(fieldWidth/3.0 + lineStroke, -1, largeAreaLineDepth + lineStroke);
        vertex(fieldWidth/3.0, -1, largeAreaLineDepth + lineStroke);
    endShape();

    
    // Line on the field: small area    
    beginShape();
        noStroke();
        fill(#FFFFFF);
        vertex(-(goalWidth/2 + 0.05*width), -1, smallAreaLineDepth);
        vertex(-(goalWidth/2 + 0.05*width) + lineStroke, -1, smallAreaLineDepth);
        vertex(-(goalWidth/2 + 0.05*width) + lineStroke, -1, endFieldLineDepth);
        vertex(-(goalWidth/2 + 0.05*width), -1, endFieldLineDepth);
    endShape();
    
    beginShape();
        noStroke();
        fill(#FFFFFF);
        vertex((goalWidth/2 + 0.05*width) + lineStroke, -1, smallAreaLineDepth);
        vertex((goalWidth/2 + 0.05*width), -1, smallAreaLineDepth);
        vertex((goalWidth/2 + 0.05*width), -1, endFieldLineDepth);
        vertex((goalWidth/2 + 0.05*width) + lineStroke, -1, endFieldLineDepth);
    endShape();
    
    beginShape();
        noStroke();
        fill(#FFFFFF);
        vertex(-(goalWidth/2 + 0.05*width), -1, smallAreaLineDepth + lineStroke);
        vertex((goalWidth/2 + 0.05*width), -1, smallAreaLineDepth + lineStroke);
        vertex((goalWidth/2 + 0.05*width), -1, smallAreaLineDepth);
        vertex(-(goalWidth/2 + 0.05*width), -1, smallAreaLineDepth);
    endShape();

    // Small square
    beginShape();
        noStroke();
        fill(#FFFFFF);
        vertex((goalWidth/2 + 0.05*width), -1, smallAreaLineDepth);
        vertex((goalWidth/2 + 0.05*width) + lineStroke, -1, smallAreaLineDepth);
        vertex((goalWidth/2 + 0.05*width) + lineStroke, -1, smallAreaLineDepth + lineStroke);
        vertex((goalWidth/2 + 0.05*width), -1, smallAreaLineDepth + lineStroke);
    endShape();
    
    
    // Line on the field: end of field    
    beginShape();
        noStroke();
        fill(#FFFFFF);
        vertex(-fieldWidth/2.0, -1, endFieldLineDepth + lineStroke);
        vertex(fieldWidth/2.0, -1, endFieldLineDepth + lineStroke);
        vertex(fieldWidth/2.0, -1, endFieldLineDepth);
        vertex(-fieldWidth/2.0, -1, endFieldLineDepth);
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

void drawGoalLine(
    float x1, float y1, float z1, 
    float x2, float y2, float z2, 
    float thickness, String principalDirection, String depthAspect
) {
    if (principalDirection == "width") {
        beginShape();
            noStroke();
            fill(#EEEEEE);
            vertex(x1, y1, z1);
            vertex(x1, y1-thickness, z1);
            vertex(x2, y2-thickness, z2);
            vertex(x2, y2, z2);
        endShape();  
    } else if (principalDirection == "height") {
        beginShape();
            noStroke();
            fill(#EEEEEE);
            vertex(x1, y1, z1);
            vertex(x1+thickness, y1, z1);
            vertex(x2+thickness, y2, z2);
            vertex(x2, y2, z2);
        endShape();
    } else {
        if (depthAspect == "up") {
            beginShape();
                noStroke();
                fill(#EEEEEE);
                vertex(x1, y1, z1);
                vertex(x1+thickness, y1, z1);
                vertex(x2+thickness, y1, z2);
                vertex(x2, y2, z2);
            endShape();
        } else if (depthAspect == "side") {
            beginShape();
                noStroke();
                fill(#EEEEEE);
                vertex(x1, y1, z1);
                vertex(x1, y1-thickness, z1);
                vertex(x2, y2-thickness, z2);
                vertex(x2, y2, z2);
            endShape();
        }
    }
}


// Draws the goal on the screen: completely static
void drawGoal() {
    float goalPostThickness = 0.004*width;
    float goalNetThickness = 0.1*goalPostThickness;

    float d, h, w;
    float netSpace = (goalHeight*goalWidth*goalDepth)/8000000;

    pushMatrix();
    pushStyle();
    
    translate(width/2, 0, endFieldLineDepth);

    // Goal structure

    drawGoalLine(
        (-goalWidth/2), 0, 0, 
        (-goalWidth/2), -goalHeight, 0, 
        goalPostThickness, "height", ""
    );
    drawGoalLine(
        (goalWidth/2), 0, 0, 
        (goalWidth/2), -goalHeight, 0, 
        goalPostThickness, "height", ""
    );
    drawGoalLine(
        (-goalWidth/2), -goalHeight, 0, 
        (goalWidth/2), -goalHeight, 0,
        goalPostThickness, "width", ""
    );

    // Goal net

    h = 0;
    d = -goalDepth;
    while (d <= 0) {
        if (d < -goalDepth/2) {
            drawGoalLine(
                (-goalWidth/2), h, d, 
                (goalWidth/2), h, d, 
                goalNetThickness, "width", ""
            );

            drawGoalLine(
                (-goalWidth/2), h-(goalHeight/goalDepth)*netSpace, d+netSpace/2, 
                (goalWidth/2), h-(goalHeight/goalDepth)*netSpace, d+netSpace/2,
                goalNetThickness, "width", ""
            );

            drawGoalLine(
                (-goalWidth/2), 0, d, 
                (-goalWidth/2), h, d, 
                goalNetThickness, "height", ""
            );
            drawGoalLine(
                (goalWidth/2), 0, d, 
                (goalWidth/2), h, d, 
                goalNetThickness, "height", ""
            );

            drawGoalLine(
                (-goalWidth/2), h, 0, 
                (-goalWidth/2), h, d, 
                goalNetThickness, "depth", "side"
            );
            drawGoalLine(
                (goalWidth/2), h, 0, 
                (goalWidth/2), h, d, 
                goalNetThickness, "depth", "side"
            );

            drawGoalLine(
                (-goalWidth/2), h-(goalHeight/goalDepth)*netSpace, 0, 
                (-goalWidth/2), h-(goalHeight/goalDepth)*netSpace, d+netSpace/2,
                goalNetThickness, "depth", "side"
            );
            drawGoalLine(
                (goalWidth/2), h-(goalHeight/goalDepth)*netSpace, 0, 
                (goalWidth/2), h-(goalHeight/goalDepth)*netSpace, d+netSpace/2,
                goalNetThickness, "depth", "side"
            );

            h -= (2*goalHeight/goalDepth)*netSpace;
        } else { // if (d >= -goalDepth/2)
            drawGoalLine(
                (-goalWidth/2), -goalHeight, d, 
                (goalWidth/2), -goalHeight, d, 
                goalNetThickness, "width", ""
            );
            drawGoalLine(
                (-goalWidth/2), 0, d, 
                (-goalWidth/2), -goalHeight, d, 
                goalNetThickness, "height", ""
            );
            drawGoalLine(
                (goalWidth/2), 0, d, 
                (goalWidth/2), -goalHeight, d, 
                goalNetThickness, "height", ""
            );
        }
        d += netSpace; 
    }

    h += (goalHeight/goalDepth)*netSpace;
    drawGoalLine(
        (-goalWidth/2), h, (-goalDepth/2), 
        (-goalWidth/2), 0, -goalDepth,
        goalNetThickness, "height", ""
    );
    drawGoalLine(
        (goalWidth/2), h, (-goalDepth/2), 
        (goalWidth/2), 0, -goalDepth,
        goalNetThickness, "height", ""
    );

    w = -goalWidth/2+netSpace;
    while (w <= goalWidth/2) {
        drawGoalLine(
            w, -goalHeight, 0, 
            w, -goalHeight, (-goalDepth/2),
            goalNetThickness, "depth", "up"
        );
        drawGoalLine(
            w, -goalHeight, (-goalDepth/2), 
            w, 0, -goalDepth,
            goalNetThickness, "height", ""
        );
        w += netSpace;
    }

    beginShape();
        noStroke();
        fill(#EEEEEE);
        vertex(goalWidth/2, -goalHeight, 0);
        vertex(goalWidth/2, -goalHeight-goalPostThickness, 0);
        vertex(goalWidth/2+goalPostThickness, -goalHeight-goalPostThickness, 0);
        vertex(goalWidth/2+goalPostThickness, -goalHeight, 0);
    endShape();

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
            !boolean(i % 2) 
            ? "pcs_logo" 
            : "comp_logo"
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
            currentMatch.resetMatch();

            hud.zoomOut();
            client.getSuggestionsFromDatabase(100);
        }
        
        // If header is 1, a match has just begun
        else if (header == '1') {
            println("RODADA " + segment2 + ": JOGADOR " + segment1 + " BATENDO");
            currentMatch.updateRound(segment1.charAt(0), segment2);
            hud.showSuggestionHUD();
        }
        
        // If header is 2, the game is preparing itself for a new shot
        else if (header == '2') {
            println("JOGADOR JÁ PODE BATER");
            //sounds.get("whistle").play();
        }
        
        else if (header == '3') {
            currentMatch.playPenalty(segment1.charAt(0));
        }
        
        // If header is 4, a shot has just happened, and we update the scoreboard
        else if (header == '4') {
            println("NOVO PLACAR:  A  |  B");
            println("              " + unhex(segment1) + "  |  " + segment2);

            if (currentMatch.detectGoalOfA(unhex(segment1)) || currentMatch.detectGoalOfB(segment2)) {
                if (currentMatch.detectGoalOfA(unhex(segment1))) {
                    sounds.get("brasil").play();
                }
                hud.showGoalBanner();
            }

            currentMatch.updateGoalsByDirection(unhex(segment1), segment2);
            currentMatch.updateScore(unhex(segment1), segment2);
        }
        
        // If header is 5, the match has ended, and we check who is the winner
        else if (header == '5') {
            println("FIM DO JOGO!!!!");
            println("PLACAR FINAL:  A  |  B");
            println("               " + unhex(segment1) + "  |  " + segment2);
            
            currentMatch.endMatch(unhex(segment1), segment2);
            client.saveMatchToDatabase(currentMatch);
            hud.hideSuggestionHUD();
            hud.zoomIn();
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
    else if (key == 'P') {
        float[] camCoords = cam.getLookAt();
        println(camCoords[0], camCoords[1], camCoords[2], cam.getDistance());
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

        hud.loadBanners();
    
        isFirstRender = false;
    }
}
