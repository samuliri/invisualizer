/**
  * Invisualizer
  * - Processing input audio visualizer
  *
  * Red color: Low sound
  * Green color: Middle sound
  * Blue: High sound
  * 
  * Speed and color depends on the volume
  *
  * Samuli Ristimäki
  * https://github.com/samuliri/invisualizer
  */

// import minim library
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput input;
FFT fft;

// init sound spectrum
float low = 0.06; // 6%
float mid = 0.14; // 14%
float high = 0.19; // 19%

// init sound value
float lowVal, midVal, highVal = 0;

// init cubes
int nbCubes;
Cube[] cubes;

// init walls
int nbWalls;
Wall[] walls;

void setup() {
  // fullscreen 3d
  fullScreen(P3D);

  // setup minim
  minim = new Minim(this);
  
  // use the getLineIn method of the Minim object to get an AudioInput
  input = minim.getLineIn(Minim.STEREO, 2048); 

  // create the FFT object to analyze the input
  fft = new FFT(input.bufferSize(), input.sampleRate());
  
  // setup cubes
  nbCubes = (int)(fft.specSize()*low);
  cubes = new Cube[nbCubes];
  
  for (int i = 0; i < nbCubes; i++) {
   cubes[i] = new Cube(); 
  }
  
  // setup walls
  nbWalls = 2000;
  walls = new Wall[nbWalls];

  // left
  for (int i = 0; i < nbWalls; i+=4) {
    walls[i] = new Wall(0, height/2, 10, height);
  }

  // right
  for (int i = 1; i < nbWalls; i+=4) {
    walls[i] = new Wall(width, height/2, 10, height);
  }

  // bottom
  for (int i = 2; i < nbWalls; i+=4) {
    walls[i] = new Wall(width/2, height, width, 10);
  }

  // top
  for (int i = 3; i < nbWalls; i+=4) {
    walls[i] = new Wall(width/2, 0, width, 10);
  }
  
  // setup black background
  background(255);
}

void draw() {
  // forward the audio input, draw for each "frame" of the sound
  fft.forward(input.mix);

  // reset old values
  lowVal = 0;
  midVal = 0;
  highVal = 0;

  // calculate the new values
  for (int i = 0; i < fft.specSize()*low; i++) {
    lowVal += fft.getBand(i);
  }

  for (int i = (int)(fft.specSize()*low); i < fft.specSize()*mid; i++) {
    midVal += fft.getBand(i);
  }

  for (int i = (int)(fft.specSize()*mid); i < fft.specSize()*high; i++) {
    highVal += fft.getBand(i);
  }

  // sum values
  float scoreGlobal = 0.66*lowVal + 0.8*midVal + 1*highVal;
  
  // change of background color
  background(lowVal/10, midVal/10, highVal/10);

  // display cubes
  for(int i = 0; i < nbCubes; i++) {
    cubes[i].display(lowVal, midVal, highVal);
  }
  
  // display walls
  for (int i = 0; i < nbWalls; i++) {
    float intensity = fft.getBand(i%((int)(fft.specSize()*high)));
    walls[i].display(lowVal, midVal, highVal, intensity, scoreGlobal);
  }
}

class Cube {
  // position values
  float startingZ = -10000;
  float maxZ = 1000;
  float x, y, z;
  float rotX, rotY, rotZ;
  float sumRotX, sumRotY, sumRotZ;
  
  Cube() {
    // random cube placement
    x = random(0, width);
    y = random(0, height);
    z = random(startingZ, maxZ);
 
    // random cube rotation
    rotX = random(0, 1);
    rotY = random(0, 1);
    rotZ = random(0, 1);
  }
 
  void display(float lowVal, float midVal, float highVal) {
    
    // box color
    color displayColor = color(lowVal*0.67, midVal*0.67, highVal*0.67, 50);
    fill(displayColor);
 
    // box lines
    stroke(255);
    strokeWeight(1);
 
    // transformation matrix
    pushMatrix();
 
    // shifting
    translate(x, y, z);
 
    // rotation
    rotateX(rotX);
    rotateY(rotY);
    rotateZ(rotZ);
 
    // random box size
    box(rotX*100);
 
    // application of the matrix
    popMatrix();
 
    // add z
    z += 10;
 
    // replace the box at the back when it is no longer visible
    if (z >= maxZ) {
      x = random(0, width);
      y = random(0, height);
      z = startingZ;
    }
  }
}

class Wall {
  // position values
  float startingZ = -10000;
  float maxZ = 50;
  float x, y, z;
  float sizeX, sizeY;
 
  Wall(float x, float y, float sizeX, float sizeY) {
    this.x = x;
    this.y = y;
    this.z = random(startingZ, maxZ);  
 
    this.sizeX = sizeX;
    this.sizeY = sizeY;
  }
  
  void display(float lowVal, float midVal, float highVal, float intensity, float scoreGlobal) {
    
    // 1st wall layer color determined by low, medium and high sounds
    color displayColor = color(lowVal*0.67, midVal*0.67, highVal*0.67);
    fill(displayColor);
    noStroke();
 
    // transformation matrix
    pushMatrix();
   
    // shifting
    translate(x, y, z);
 
    // extension
    if (intensity > 100) intensity = 100;
    scale(sizeX*(intensity/100), sizeY*(intensity/100), 20);
 
    // "box"
    box(1);
    
    // application of the matrix
    popMatrix();
 
    // 2nd wall layer color determined by low, medium and high sounds
    displayColor = color(lowVal*0.5, midVal*0.5, highVal*0.5);
    fill(displayColor, 10);
    
    // transformation matrix
    pushMatrix();
 
    // shifting
    translate(x, y, z);
 
    // extension
    scale(sizeX, sizeY, 10);
 
    // "box"
    box(1);
    
    // application of the matrix
    popMatrix();
 
    // z placement
    z += (pow((scoreGlobal/150), 2));
    if (z >= maxZ) {
      z = startingZ;  
    }
  }
}
