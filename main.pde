// Includes
#include <Servo.h>

// Variable declaration
#define DEBUG false

byte iByte = 0;	// for incoming serial data
byte cCmd = 255;   // Our current command (used for multi-byte cmds, -1 = no current cmd)
boolean FLAG_FM = true;
boolean FLAG_MISC = false;  // A misc flag
boolean FLAG_MISC2 = false;  // Another misc flag

byte REG[8];  // Sets up some registers for code use/reuse
int INTREG[8];  // Sets up some registers for code use/reuse

Servo SERVO[8];

// Setup
void setup() {
  Serial.begin(9600);	// opens serial port, sets data rate to 9600 bps

  // Setup the servos
  SERVO[0].attach(9);
  
  SERVO[0].writeMicroseconds(1500);
}

// Loop
void loop() {
  if (Serial.available() > 0) {

    iByte = Serial.read(); // read the incoming byte

    if (DEBUG) Serial.print("In: ");
    if (DEBUG) Serial.print(iByte,BIN);

    if (cCmd == 255)      // If the last command "complete" set it to the new command
    {
      cCmd = iByte >> 4;
      if (DEBUG) Serial.print("-Parsed: ");
      if (DEBUG) Serial.println(cCmd,BIN);
    }
    else
    {
      if (DEBUG) Serial.println(" - Mot parsing"); 
    }




    switch (cCmd)
    {
    case 0: // PRG
      {
        cCmd = 255;  // this cmd doesn't use more than 1 byte
        if (DEBUG) Serial.println("Got PRG command");
        boolean M = ((iByte >> 3) & 1);
        if (M)
        {
          if (DEBUG) Serial.println("Got SET MODE (M=1)");
          FLAG_FM = ((iByte >> 2) & 1);
        }
        else
        {
          if (DEBUG) Serial.println("Got GET MODE (M=0)");
          if (DEBUG) Serial.println(FLAG_FM, DEC);
        }
        if (FLAG_FM)
        {
          if (!DEBUG) Serial.print(0, BYTE);
          else Serial.print(0, DEC);
        }
        break;
      }
    case 1: // JOG
      {
        cCmd = 255;  // this cmd doesn't use more than 1 byte
        if (DEBUG) Serial.println("Got JOG command");

        REG[1] = (iByte >> 1) & B111;  // Grab the destination servo number and store it
        boolean DIR = iByte & 1;  // Grab the direction bit and store it

        if (DEBUG) Serial.print("Servo number: ");
        if (DEBUG) Serial.print(REG[1],DEC);
        if (DEBUG) Serial.print(" Direction = ");
        if (DEBUG) Serial.println(DIR, DEC);

        if (DIR == 0) SERVO[REG[1]].writeMicroseconds(SERVO[REG[1]].readMicroseconds() + 5);
        else  SERVO[REG[1]].writeMicroseconds(SERVO[REG[1]].readMicroseconds() - 5);
        
        if (FLAG_FM)
        {
          if (!DEBUG) Serial.print(0, BYTE);
          else Serial.print(0, DEC);
        }
        break;
      }

    case 2: // SET
      {
        if (REG[0] == 0)  // The is the first time through this command. 
        {
          if (DEBUG) Serial.println("Got SET command, waiting for value");
          FLAG_MISC = iByte & 1;  // Grab the relative bit and store it
          REG[1] = (iByte >> 1) & B111;  // Grab the destination servo number and store it
          if (DEBUG) Serial.print("Servo number: ");
          if (DEBUG) Serial.print(REG[1],DEC);
          if (DEBUG) Serial.print(" Relative = ");
          if (DEBUG) Serial.println(FLAG_MISC, DEC);
          REG[0]++;
        }
        else
        {
          if (REG[0] == 1)  // This is the second time thorugh this command. Grabbing the MSB now
          {
            if (DEBUG) Serial.print("Got MSB of ");
            if (DEBUG) Serial.println(iByte, BIN);
            INTREG[0] = iByte;
            INTREG[0] = INTREG[0] << 8;
            if (DEBUG) Serial.print("INTREG = ");
            if (DEBUG) Serial.println(INTREG[0], BIN);
            REG[0]++;
          }
          else
          {
            if (DEBUG) Serial.print("Got LSB of ");
            if (DEBUG) Serial.println(iByte, BIN);
            INTREG[0] |= iByte;

            if (DEBUG) Serial.print("INTREG = ");
            if (DEBUG) Serial.println(INTREG[0], BIN);
            if (DEBUG) Serial.println(INTREG[0], DEC);


            if (DEBUG) Serial.print("Moving servo ");
            if (DEBUG) Serial.print(REG[1], DEC);
            if (FLAG_MISC)  // Relative is set
            {
              if (DEBUG) Serial.print(" ");
              if (DEBUG) Serial.print(INTREG[0], DEC);
              if (DEBUG) Serial.println(" relative to it's current position");
              SERVO[REG[1]].writeMicroseconds(SERVO[REG[1]].readMicroseconds() + INTREG[0]);
            }
            else
            {
              if (DEBUG) Serial.print(" to ");
              if (DEBUG) Serial.print(INTREG[0], DEC);
              SERVO[REG[1]].writeMicroseconds(INTREG[0]);
            }
            if (FLAG_FM)
            {
              if (!DEBUG) Serial.print(0, BYTE);
              else Serial.print(0, DEC);
            }
            REG[0] = 0; // cleanup is good
            cCmd = 255;  // cleanup is good
          }
        }
        break;
      }

      // The Get command. Status: DONE
    case 3: // GET
      {
        cCmd = 255;  // this cmd doesn't use more than 1 byte
        REG[1] = (iByte >> 1) & B111;  // Grab the source servo number and store it

        int servoVal = SERVO[REG[1]].readMicroseconds();
        byte MSB = servoVal >> 8;
        byte LSB = servoVal;

        if (DEBUG) Serial.println("Got GET command");
        if (DEBUG) Serial.print("Servo number: ");
        if (DEBUG) Serial.print(REG[1],DEC);
        if (DEBUG) Serial.print(" Value: ");
        if (DEBUG) Serial.print(servoVal, DEC);
        if (DEBUG) Serial.print(" MSB: ");
        if (DEBUG) Serial.print(MSB, DEC);
        if (DEBUG) Serial.print(" LSB: ");
        if (DEBUG) Serial.print(LSB, DEC);

        if (!DEBUG) Serial.print(MSB,BYTE);
        if (!DEBUG) Serial.print(LSB,BYTE);
        break;
      }
    }

  }
}
















