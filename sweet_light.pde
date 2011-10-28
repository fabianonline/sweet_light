#include "pins_arduino.h"

// How many settings do we have
#define SET_COUNT 5
// Number of channels to use
#define CHANNELS 5
// How many and which channels are used in the settings
#define SET_CHANNELS_COUNT 3
// How long should a fade take in ms
#define FADE_TIME 10000
#define DEBOUNCE_TICKS 10

#define DMX_PIN 11


const int SET_CHANNELS[] = {2, 3, 4};

// Channel settings
const int SETS[][SET_CHANNELS_COUNT] = {
  {255, 128,  80},
  {128,   0,  60},
  {128, 128,  60},
  {  0,   0,   0},
  {128,   0,  60}
};

#define _start 0
#define _current 1
#define _target 2
#define _time_remaining 4

int channels[CHANNELS][4];

int last_pressed_button = 255; // non-existing button
int pressed_for = 0;
boolean channel_changed;




void setup() {
  cli();
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
  
  
  // set all channels to black
  for (int i=0; i<CHANNELS; i++) channels[i][_current] = 0;
  
  // load first set
  for (int i=0; i<SET_CHANNELS_COUNT; i++) channels[SET_CHANNELS[i]][_current] = SETS[0][i];
  
  // target == start == current
  for (int i=0; i<CHANNELS; i++) {
    channels[i][_target] = channels[i][_current];
    channels[i][_start] = channels[i][_current];
    channels[i][_time_remaining] = 0;
  }
}

void loop() {
  int button = checkButtons();
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
    if (channels[i][_time_remaining] == 0) {
      if (channels[i][_current] != channels[i][_target]) {
        channel_changed=true;
        channels[i][_current] = channels[i][_target];
      }
    } else {
      channel_changed = true;
      channels[i][_current] = channels[i][_start] + ((channels[i][_target] - channels[i][_start]) / FADE_TIME * (FADE_TIME-channels[i][_time_remaining]));
      channels[i][_time_remaining] = channels[i][_time_remaining] - 1;
    }
  }
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
  PORTC = PORTC & B11100000;
}

void stopFades() {
  for (int i=0; i<CHANNELS; i++) {
    channels[i][_target] == channels[i][_current];
    channels[i][_time_remaining] = 0;
  }
}

void setAllChannelsImmediately(int value) {
  for (int i=0; i<CHANNELS; i++) {
    channels[i][_target] == value;
    channels[i][_time_remaining] = 0;
  }
}

int checkButtons() {
  int old_last_pressed_button = last_pressed_button;
  last_pressed_button = 255;
  
  for (int i=0; i<=9; i++) {
    if (digitalRead(i) == HIGH) {
      last_pressed_button = i;
    }
  }
  
  if (last_pressed_button == old_last_pressed_button) pressed_for++;
  else pressed_for = 0;
  
  if (pressed_for == DEBOUNCE_TICKS) return last_pressed_button;
  
  return 255;
}

void toggleChannel(int i) {
  int target = (channels[i][_current]>127 ? 0 : 255);
  int button = (i==0 ? 12 : 13);
  digitalWrite(button, target==255?HIGH:LOW);
  channels[i][_start] = channels[i][_current];
  channels[i][_target] = target;
  channels[i][_time_remaining] = FADE_TIME;
}

void fadeToSet(int set_id) {
  // load set
  for (int j=0; j<SET_CHANNELS_COUNT; j++) {
    int i = SET_CHANNELS[j];
    channels[i][_start] = channels[i][_current];
    channels[i][_target] = SETS[set_id][i];
    channels[i][_time_remaining] = FADE_TIME;
  }
  clearSetLEDs();
  // not quite sure if this works...
  digitalWrite(A0 + set_id, HIGH);
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
  // cli();

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
  //sei();
}
