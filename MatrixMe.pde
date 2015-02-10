import processing.serial.*;
import processing.opengl.*;
import SimpleOpenNI.*;

SimpleOpenNI kinect;
PImage kSM = new PImage(16,16,ARGB);
PImage kSmall = new PImage(640,480,ARGB);

byte g[] = new byte[256];

int userMap[];

int numUsers = 0;
int arduinoPort = -1;


Serial myPort;

void setup() {
  size(901, 800, P2D);
  kinect = new SimpleOpenNI(this);
  kinect.enableDepth();
  kinect.setMirror(true);
  kinect.enableUser(SimpleOpenNI.SKEL_PROFILE_NONE);
  String[] ports = Serial.list();
  for (int i=0;i<ports.length;i++) {
    println(ports[i]);
    ///////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////
    // THIS IS SPECIFIC TO THE PORT YOUR ARDUINO IS ON!!!
    ///////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////
    if (ports[i].indexOf("411") > -1 && ports[i].indexOf("tty") > -1) {
      arduinoPort = i;
    }
  }
  if (arduinoPort > -1) {
    myPort = new Serial(this, Serial.list()[arduinoPort], 57600);
  }

  background(128,0,0);

  // give some time to wake up arduino and kinect
  delay(3000);
}

void draw() {
    background(0);

  kinect.update();
  image(kinect.depthImage(), 20, 120);

  PVector[] depthPoints = kinect.depthMapRealWorld();

  for (int y=0;y<16;y++) {
    for (int x=0;x<16;x++) {
      PVector currentPoint = depthPoints[(x*floor(640/16)) + ((y * floor(480/16)) * kinect.depthImage().width)];
      if (currentPoint.z < 200 || currentPoint.z > 2000) {
        currentPoint.z = 0;
      }
      noStroke();
      fill(map(currentPoint.z, 0, 4000, 0, 255));
      ellipse(680+x, 120+y, 2, 2);
    }
  }

  numUsers = kinect.getNumberOfUsers();
  if (numUsers > 0) { 
    numUsers = 1;
    // find out which pixels have users in them
    userMap = kinect.getUsersPixels(SimpleOpenNI.USERS_ALL); 
    // populate the pixels array
    // from the sketch's current contents 
    kSmall.loadPixels();
    for (int i = 0; i < userMap.length; i++) { 
      // if the current pixel is on a user
      if (userMap[i] != 0) {
        // make it green
        kSmall.pixels[i] = color(0, 255, 0,255);
      } else {
        kSmall.pixels[i] = color(0,0);
      }
    } 
    // display the changed pixel array 
    kSmall.updatePixels(); 
  }
  
  kSM.copy(kSmall,80,0,480,480,0,0,16,16);
  image(kSM,680,120,64,64);
  
  fill(255,0,0);
  text("users: " + numUsers,10,10);
  
  for (int i=0;i<256;i++) {
    g[i] = kSM.pixels[i] == 0 ? (byte)0 : (byte)1;
  }
  
  // mask depth image to show what matrix will get
  noStroke();
  fill(0);
  rect(20,120,80,480);
  rect(580,120,80,480);
  
  // send the data to arduino
  //drawGrid();
  if (arduinoPort > -1) {
    sendToArduino();
  }
  numUsers = 0;
  delay(50);
}


void sendToArduino() {
  // send data to arduino
  
  // header
  int b1 = 0x81;
  int b2 = 0xc3;
  myPort.write(b1);
  myPort.write(b2);
  // number of users
  myPort.write((byte)numUsers);
  myPort.write((byte)255);
  // image bytes
  for (int offset=0;offset<32;offset++) {
    byte rb = 0x00;
    byte mask = 0x01;
    for (int i=0;i<8;i++) {
      if (g[i+(offset*8)] == 1) {
        rb = (byte)(rb | mask);
      }
      mask = (byte)(mask << 1);
    }
    myPort.write(rb);
  }
}
