// bibliotecas
import processing.serial.*;      // importa biblioteca de comunicacao serial
import java.awt.event.KeyEvent;  // importa biblioteca para leitura de dados da porta serial
import java.io.IOException;

// Constants
int lf = 10;  // ASCII linefeed

// Global variables for drawings
float fieldHeight;
float crowdHeight;
float endFieldLineHeight;
float advertHeight;
int fieldDepth;

// Global variables for Serial comm
String port = "COM3";  // <== acertar valor ***
int baudrate = 115200;  // 115200 bauds
char parity = 'E';     // par
int databits = 7;       // 7 bits de dados
float stopbits = 2.0;     // 2 stop bits


void setup() {
  size (1400, 1050, P3D);
 
  Serial serialConnetion = new Serial(this, port, baudrate, parity, databits, stopbits);
  serialConnetion.bufferUntil(lf);
}


void draw() {
  // Setting constants values based on size()
  fieldHeight = 0.6*height;
  fieldDepth = -400;
  endFieldLineHeight = 0.125*fieldHeight;
  advertHeight = 0.1*height;
  crowdHeight = (height - fieldHeight - advertHeight);
    
  // lights();
  drawField();
  drawGoal();
  drawAdverts();
  drawScoreboard();
  drawCrowd();
}


void drawField() {
  int NUM_OF_SUBFIELDS = 4;
  float subfieldWidth = (2*width)/float(NUM_OF_SUBFIELDS);
  float smallAreaLineHeight = 0.60*fieldHeight;

  pushMatrix();
  pushStyle();
  
  translate(0, (height-fieldHeight), 0);

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
  
  // Lines
  strokeWeight(4);
  stroke(#FFFFFF);
  line(-0.5*width, smallAreaLineHeight, 0.1*fieldDepth, 1.5*width, smallAreaLineHeight, 0.1*fieldDepth);
  line(-0.5*width, endFieldLineHeight, 0.75*fieldDepth, 1.5*width, endFieldLineHeight, 0.75*fieldDepth);
  
  popStyle();
  popMatrix();
}


void drawGoal() {
  float goalWidth = 0.666*width;
  float goalHeight = height - fieldHeight;
  float goalThickness = 0.01*width;

  pushMatrix();
  pushStyle();
  
  translate(width/2, (height-fieldHeight) + endFieldLineHeight, 0.75*fieldDepth);
  stroke(#EEEEEE);
  
  strokeWeight(goalThickness);
  line((-goalWidth/2), 0, 0, (-goalWidth/2), -goalHeight, 0);
  line((goalWidth/2), 0, 0, (goalWidth/2), -goalHeight, 0);
  line((-(goalWidth + goalThickness)/2), -goalHeight, 0, ((goalWidth+goalThickness)/2), -goalHeight, 0);

  popStyle();
  popMatrix();
}


void drawAdverts() {
  int NUM_OF_ADS = 5;
  PImage[] images = new PImage[2];
  float advertWidth = (1.5*width)/float(NUM_OF_ADS);
  
  images[0] = loadImage("PCS_logo.png");
  images[1] = loadImage("Qatar_logo.jpg");
  
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
    
    pushMatrix();
    pushStyle();
    float scoreStart = i * teamScoreHeight;
    translate(0, scoreStart, 0);
    
    if (boolean(i)) {
      strokeWeight(dividerHeight);
      stroke(#00000077);
      line(-teamMarkerWidth, 0, 0, dividerWidth, 0, 0);
      translate(0, dividerHeight, 0);
    }
    
    beginShape();
      noStroke();
      fill(boolean(i) ? #1981CE : #F58B20);
      vertex(-teamMarkerWidth, 0, 0);
      vertex(0, 0, 0);
      vertex(0, teamScoreHeight, 0);
      vertex(-teamMarkerWidth, teamScoreHeight, 0);
    endShape();
    
    textInsideBox("Time " + (boolean(i) ? "B" : "A"), teamNameBoxWidth, teamScoreHeight, #CBB75D, #443514);
    translate(teamNameBoxWidth, 0, 0);
    textInsideBox("0", teamScoreBoxWidth, teamScoreHeight, #333333, #FFFFFF);
    translate(teamScoreBoxWidth, 0, 0);
    beginShape();
      noStroke();
      fill(#00000088);
      vertex(0, 0, 0);
      vertex(penaltyPointsBoxWidth, 0, 0);
      vertex(penaltyPointsBoxWidth, teamScoreHeight, 0);
      vertex(0, teamScoreHeight, 0);
    endShape();
    
    translate(0, teamScoreHeight/2, 0);
    fill(#FF0000);
    for (int j = 1; j <= 5; j += 1) {
      translate((circleDiameter + circleMargin), 0, 0);
      circle(0, 0, circleDiameter);
    }
    

    translate(3*circleMargin, 0, 0);
    circle(0, 0, circleDiameter);
    
    popStyle();
    popMatrix();
  }
  
  
  translate(lineOffset, teamScoreHeight/2, 0);
  strokeWeight(1);
  stroke(#FFFFFF);
  line(0, -8, 0, 0, teamScoreHeight + 8, 0);

  popStyle();
  popMatrix();
}

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


void drawCrowd() {
  PImage crowdImage;

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
