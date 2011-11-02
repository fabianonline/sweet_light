#include "pins_arduino.h"

// How many settings do we have
#define SET_COUNT 5
// Number of channels to use
#define CHANNELS 5
// How many and which channels are used in the settings
#define SET_CHANNELS_COUNT 3
// How long should a fade take in ms
#define FADE_TIME 6000

#define DMX_PIN 11

// uncomment to activate debug mode
//#define DEBUG
#define DEBUG_FADES

#ifndef DEBUG
  #undef DEBUG_FADES
#endif

#ifdef DEBUG_FADES
  #define FADE_TIME 50
#endif

const int SET_CHANNELS[] = {1, 2, 3};

// Channel settings
const int SETS[][SET_CHANNELS_COUNT] = {
  {100, 100,  100},
  {50,   50,  0},
  {50, 50,  100},
  {  0,   0,   0},
  {50,  50,  0}
};

// Button Settings
// PinNumber, MinPressTime
#define BUTTONS_COUNT 10
const int BUTTONS[BUTTONS_COUNT][2] = {
  {0, 50},
  {1, 50},
  {2, 50},
  {3, 50},
  {4, 50},
  {5, 50},
  {6, 50},
  {7, 50},
  {8, 1000},
  {9, 1000}
};
#define _number 0
#define _delay 1

#define _start 0
#define _current 1
#define _target 2
#define _time_remaining 3
#define _current_set 4
#define _target_set 5
#define _min 6
#define _max 7

int channels[CHANNELS][8] = {
  {0, 0, 0, 0, -1, -1, 0, 220},
  {0, 0, 0, 0, -1, -1, 0, 220},
  {0, 0, 0, 0, -1, -1, 0, 65},
  {0, 0, 0, 0, -1, -1, 0, 128},
  {0, 0, 0, 0, -1, -1, 0, 190}
};

int last_pressed_button = -1; // non-existing button
int pressed_for = 0;
boolean channel_changed;
long debounce_time = 0;
int last_returned_button = -1;
int button = -1;




void setup() {
  // set pins to input and activate pull-up resistors
  pinMode(0, INPUT);
  pinMode(1, INPUT);
  pinMode(2, INPUT);
  pinMode(3, INPUT);
  pinMode(4, INPUT);
  pinMode(5, INPUT);
  pinMode(6, INPUT);
  pinMode(7, INPUT);
  pinMode(8, INPUT);
  pinMode(9, INPUT);
  digitalWrite(0, HIGH);
  digitalWrite(1, HIGH);
  digitalWrite(2, HIGH);
  digitalWrite(3, HIGH);
  digitalWrite(4, HIGH);
  digitalWrite(5, HIGH);
  digitalWrite(6, HIGH);
  digitalWrite(7, HIGH);
  digitalWrite(8, HIGH);
  digitalWrite(9, HIGH);
  
  // set pins to output and set all except for first to high
  pinMode(12, OUTPUT);
  pinMode(13, OUTPUT);
  pinMode(A0, OUTPUT);
  pinMode(A1, OUTPUT);
  pinMode(A2, OUTPUT);
  pinMode(A3, OUTPUT);
  pinMode(A4, OUTPUT);
  digitalWrite(12, LOW);
  digitalWrite(13, LOW);
  clearSetLEDs();
  digitalWrite(A0, HIGH);
  
  // set pin 11 (DMX pin) to output
  pinMode(11, OUTPUT);
  
  #ifdef DEBUG
    Serial.begin(9600);
    Serial.println("Start.");
  #endif
  
  // load first set and skip the fade
  fadeToSet(0);
  for (int i=0; i<SET_CHANNELS_COUNT; i++) {
    channels[SET_CHANNELS[i]][_time_remaining] = 0;
  }
  
  channel_changed = true;
  #ifdef DEBUG
    debugChannels();
  #endif
}

void loop() {
  button = checkButtons();
  if (button>=0 && button<SET_COUNT) {
    fadeToSet(button);
  } else if(button==5) {
    toggleChannel(4);
  } else if(button==6) {
    toggleChannel(0);
  } else if(button==7) {
    stopFades();
  } else if(button==8) {
    setAllChannelsImmediately(255);
    digitalWrite(12, HIGH);
    digitalWrite(13, HIGH);
  } else if(button==9) {
    setAllChannelsImmediately(0);
    clearSetLEDs();
    digitalWrite(12, LOW);
    digitalWrite(13, LOW);
  }
  
  fade();
  if (channel_changed) send_dmx();
  
  delay(1);
}

void fade() {
  for (int i=0; i<CHANNELS; i++) {
    if (channels[i][_time_remaining] > 0) {
      channel_changed = true;
      channels[i][_time_remaining]--;
      channels[i][_current] = channels[i][_start] + (int)((float)(channels[i][_target] - channels[i][_start]) / (float)FADE_TIME * (float)(FADE_TIME-channels[i][_time_remaining]));
    } else {
      if (channels[i][_current] != channels[i][_target]) {
        channel_changed=true;
        channels[i][_current] = channels[i][_target];
        channels[i][_current_set] = channels[i][_target_set];
      }
    }
  }
  
  #ifdef DEBUG_FADES
    if (channel_changed) {
      Serial.print("Fade:    ");
      for (int i=0; i<CHANNELS; i++) {
        Serial.print(channels[i][_current]);
        Serial.print("   ");
      }
      Serial.println();
    }
  #endif
}

void send_dmx() {
  digitalWrite(DMX_PIN, LOW);
  delayMicroseconds(100);
  // send the start byte
  shiftDmxOut(DMX_PIN, 0);
  for(int i=0; i<CHANNELS; i++) {
    shiftDmxOut(DMX_PIN, channels[i][_current]);
  }
  channel_changed = false;
}

void clearSetLEDs() {
  digitalWrite(A0, LOW);
  digitalWrite(A1, LOW);
  digitalWrite(A2, LOW);
  digitalWrite(A3, LOW);
  digitalWrite(A4, LOW);
}

void stopFades() {
  for (int i=0; i<CHANNELS; i++) {
    channels[i][_target] = channels[i][_current];
    channels[i][_time_remaining] = 0;
  }
  #ifdef DEBUG
    debugChannels();
  #endif
}

void setAllChannelsImmediately(int value) {
  for (int i=0; i<CHANNELS; i++) {
    channels[i][_target] = value;
    channels[i][_time_remaining] = 0;
    channels[i][_target_set] = -1;
    channels[i][_current_set] = -1;
    // This should also be set by fade() - but better save than sorry.
    channel_changed = true;
  }
  #ifdef DEBUG
    debugChannels();
  #endif
}

#ifdef DEBUG
  void debugChannels() {
    Serial.print("             ");
    for (int i=0; i<CHANNELS; i++) {
      Serial.print(i);
      Serial.print("    ");
    }
    Serial.println();
    
    Serial.print("Start:       ");
    for (int i=0; i<CHANNELS; i++) {
      Serial.print(channels[i][_start]);
      Serial.print("    ");
    }
    Serial.println();
    
    Serial.print("Current:     ");
    for (int i=0; i<CHANNELS; i++) {
      Serial.print(channels[i][_current]);
      Serial.print("    ");
    }
    Serial.println();
    
    Serial.print("Target:     ");
    for (int i=0; i<CHANNELS; i++) {
      Serial.print(channels[i][_target]);
      Serial.print("    ");
    }
    Serial.println();
    
    Serial.print("Time:       ");
    for (int i=0; i<CHANNELS; i++) {
      Serial.print(channels[i][_time_remaining]);
      Serial.print("    ");
    }
    Serial.println();
    
    Serial.print("Current Set: ");
    for (int i=0; i<CHANNELS; i++) {
      Serial.print(channels[i][_current_set]);
      Serial.print("    ");
    }
    Serial.println();
    
    Serial.print("Target Set:  ");
    for (int i=0; i<CHANNELS; i++) {
      Serial.print(channels[i][_target_set]);
      Serial.print("    ");
    }
    Serial.println();
  }
#endif

int checkButtons() {
  int old_last_pressed_button = last_pressed_button;
  last_pressed_button = -1;
  
  
  for (int i=0; i<BUTTONS_COUNT; i++) {
    if (digitalRead(BUTTONS[i][_number]) == LOW) {
      last_pressed_button = i;
    }
  }
  
  if (last_pressed_button==-1 || old_last_pressed_button!=last_pressed_button) {
    debounce_time = millis();
  }
  
  if ((millis()-debounce_time)>BUTTONS[last_pressed_button][_delay] && last_pressed_button != last_returned_button) {
    last_returned_button = last_pressed_button;
    #ifdef DEBUG
      Serial.print("Button pressed: ");
      Serial.println(last_pressed_button);
    #endif
    return last_pressed_button;
  } else {
    last_returned_button = -1;
    return -1;
  }
}

void toggleChannel(int i) {
  int target = (channels[i][_current]>(channels[i][_min]+((channels[i][_max]-channels[i][_min])/2)) ? 0 : 255);
  int button = (i==0 ? 12 : 13);
  digitalWrite(button, target==255?HIGH:LOW);
  channels[i][_start] = channels[i][_current];
  channels[i][_target] = target*channels[i][_max]/100;
  channels[i][_time_remaining] = FADE_TIME;
  channels[i][_current_set] = -1;
  channels[i][_target_set] = -1;
  #ifdef DEBUG
    debugChannels();
  #endif
}

void fadeToSet(int set_id) {
  // load set
  for (int j=0; j<SET_CHANNELS_COUNT; j++) {
    int i = SET_CHANNELS[j];
    channels[i][_start] = channels[i][_current];
    channels[i][_target] = channels[i][_min] + (SETS[set_id][j]*(channels[i][_max]-channels[i][_min])/100);
    channels[i][_time_remaining] = FADE_TIME;
    if(channels[i][_target_set]==set_id) {
      // skip fade for this channel
      channels[i][_time_remaining] = 0;
    }
    channels[i][_target_set] = set_id;
    channels[i][_current_set] = -1;
    
  }
  clearSetLEDs();
  // not quite sure if this works...
  digitalWrite(A0 + set_id, HIGH);
  #ifdef DEBUG
    debugChannels();
  #endif
}






/* Sends a DMX byte out on a pin.  Assumes a 16 MHz clock.
 * Disables interrupts, which will disrupt the millis() function if used
 * too frequently. 
 * 
 * Source: Peter Szakal and Gabor Papp
 * http://iad.projects.zhdk.ch/physicalcomputing/hardware/arduino/dmx-shield-fur-arduino/
 */
void shiftDmxOut(int pin, int theByte)
{
  int port_to_output[] = {
    NOT_A_PORT,
    NOT_A_PORT,
    _SFR_IO_ADDR(PORTB),
    _SFR_IO_ADDR(PORTC),
    _SFR_IO_ADDR(PORTD)
    };

    int portNumber = port_to_output[digitalPinToPort(pin)];
  int pinMask = digitalPinToBitMask(pin);

  // the first thing we do is to write te pin to high
  // it will be the mark between bytes. It may be also
  // high from before
  _SFR_BYTE(_SFR_IO8(portNumber)) |= pinMask;
  delayMicroseconds(10);

  // disable interrupts, otherwise the timer 0 overflow interrupt that
  // tracks milliseconds will make us delay longer than we want.
  cli();

  // DMX starts with a start-bit that must always be zero
  _SFR_BYTE(_SFR_IO8(portNumber)) &= ~pinMask;

  // we need a delay of 4us (then one bit is transfered)
  // this seems more stable then using delayMicroseconds
  asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");
  asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");

  asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");
  asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");

  asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");
  asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");

  for (int i = 0; i < 8; i++)
  {
    if (theByte & 01)
    {
      _SFR_BYTE(_SFR_IO8(portNumber)) |= pinMask;
    }
    else
    {
      _SFR_BYTE(_SFR_IO8(portNumber)) &= ~pinMask;
    }

    asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");
    asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");

    asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");
    asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");

    asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");
    asm("nop\n nop\n nop\n nop\n nop\n nop\n nop\n nop\n");

    theByte >>= 1;
  }

  // the last thing we do is to write the pin to high
  // it will be the mark between bytes. (this break is have to be between 8 us and 1 sec)
  _SFR_BYTE(_SFR_IO8(portNumber)) |= pinMask;

  // reenable interrupts.
  sei();
}
