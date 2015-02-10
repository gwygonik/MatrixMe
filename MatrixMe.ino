#include <Adafruit_GFX.h>
#include <Adafruit_NeoMatrix.h>
#include <Adafruit_NeoPixel.h>
#include <gamma.h>

#ifndef PSTR
 #define PSTR // Make Arduino Due happy
#endif

#define LPIN 6
#define NUMCOLS 8
#define NUMROWS 8

const byte HEADER1       = 0x81;
const byte HEADER2       = 0xc3;
const int  TOTAL_BYTES   = 36 ; // 2 headers + 2 numusers + 32 imagedata
byte inBytes[32];

Adafruit_NeoMatrix matrix = Adafruit_NeoMatrix(16, 16, LPIN, NEO_MATRIX_TOP + NEO_MATRIX_LEFT + NEO_MATRIX_ROWS + NEO_MATRIX_ZIGZAG, NEO_GRB + NEO_KHZ800);

String inString = "";

uint16_t curColor = matrix.Color(255,255,255);


void setup() {
  
  for (int i=0;i<32;i++) {
    inBytes[i] = (byte)0;
  }
  
  Serial.begin(57600);
  Serial.setTimeout(150);

  matrix.begin();
  matrix.setBrightness(25);
  
  // start with RGB tests (set all pixels to same color to look for bad LEDs)
  matrix.fillScreen(matrix.Color(255,0,0));
  matrix.show();
  delay(500);
  matrix.fillScreen(matrix.Color(0,255,0));
  matrix.show();
  delay(500);
  matrix.fillScreen(matrix.Color(0,0,255));
  matrix.show();
  delay(500);
  matrix.fillScreen(0);
  matrix.show();
  delay(500);
  
  // Show white corners just to make sure we're addressing LEDs by number correctly (0-15)
  matrix.drawPixel(0,0,matrix.Color(255,255,255));
  matrix.drawPixel(15,0,matrix.Color(255,255,255));
  matrix.drawPixel(0,15,matrix.Color(255,255,255));
  matrix.drawPixel(15,15,matrix.Color(255,255,255));
  matrix.show();
  
  delay(500);
}

void loop() {
  // wait for all bytes
  if ( Serial.available() >= TOTAL_BYTES)
  {
    if( Serial.read() == HEADER1)
    {
      if (Serial.read() == HEADER2) {
        // next byte is number of users
        // for now we only care if it's not 0 (zero)
        char inByte = Serial.read();
        int numUsers = inByte - '0'; // convert byte to number
        Serial.read(); // 255 byte
        
        // read rest of packet
        for (int j=0;j<32;j++) {
          inBytes[j] = Serial.read();
        }
        
        if (numUsers != 0) {
          drawUser();
          matrix.show();
        } else {
          // we have 0 users
          // clear the screen
          matrix.fillScreen(0);
          matrix.show();
        }
        
      }
    }
  } else {
    // no serial data...
  } 
}

void drawUser() {
  // clear matrix
  matrix.fillScreen(0);
  // iterate over byte array 
  // for each byte, check each bit and and turn pixels on where the bit is 1
  int x = 0;
  int y = 0;
  for (int j=0;j<32;j++) {
    byte b = inBytes[j];
    for (int i=0;i<8;i++) {
      if (bitRead(b,i) == 1) {
        matrix.drawPixel(x,y,matrix.Color(255,255,255));
      } else {
        matrix.drawPixel(x,y,0);
      }
      x++;
      if (x > 15) {
        y++;
        x = 0;
      }
    }
  }
}
