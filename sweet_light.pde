// How many settings do we have
#define SET_COUNT 5
// Number of channels to use
#define CHANNELS 5
// How many and which channels are used in the settings
#define SET_CHANNELS_COUNT 3
// How long should a fade take in ms
#define FADE_TIME 10000
#define DEBOUNCE_TICKS 10


const int SET_CHANNELS[] = {2, 3, 4};

// Channel settings
const int SETS[][SET_CHANNELS_COUNT] = {
  {255, 128,  80},
  {128,   0,  60},
  {128, 128,  60},
  {  0,   0,   0},
  {128,   0,  60}
};

struct Channel {
  int start;
  int current;
  int target;
  int time_remaining;
};

Channel channels[CHANNELS];

int last_pressed_button = 255; // non-existing button
int pressed_for = 0;




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
  
  // set all channels to black
  for (int i=0; i<CHANNELS; i++) channels[i].current = 0;
  
  // load first set
  for (int i=0; i<SET_CHANNELS_COUNT; i++) channels[SET_CHANNELS[i]].current = SETS[0][i];
  
  // target == start == current
  for (int i=0; i<CHANNELS; i++) {
    Channel channel = channels[i];
    channel.target = channel.current;
    channel.start = channel.current;
    channel.time_remaining = 0;
  }
}

void loop() {
  int button = checkButtons();
  if (button>=0 && button<SET_COUNT) fadeToSet(button);
  else if(button==5) toggleChannel(4);
  else if(button==6) toggleChannel(0);
  else if(button==7) stopFades();
  else if(button==8) setAllChannelsImmediately(255);
  else if(button==9) setAllChannelsImmediately(0);
  
  fade();
}

void fade() {
  for (int i=0; i<CHANNELS; i++) {
    Channel channel = channels[i];
    if (channel.time_remaining == 0) {
      channel.current = channel.target;
    } else {
      channel.current = channel.start + ((channel.target - channel.start) / FADE_TIME * (FADE_TIME-channel.time_remaining));
      channel.time_remaining -= 1;
    }
  }
}

void stopFades() {
  for (int i=0; i<CHANNELS; i++) {
    Channel channel = channels[i];
    channel.target == channel.current;
    channel.time_remaining = 0;
  }
}

void setAllChannelsImmediately(int value) {
  for (int i=0; i<CHANNELS; i++) {
    channels[i].target == value;
    channels[i].time_remaining = 0;
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

void toggleChannel(int chan) {
  Channel channel = channels[chan];
  int target = (channel.current>127 ? 0 : 255);
  channel.start = channel.current;
  channel.target = target;
  channel.time_remaining = FADE_TIME;
}

void fadeToSet(int set_id) {
  // load set
  for (int i=0; i<SET_CHANNELS_COUNT; i++) {
    Channel channel = channels[SET_CHANNELS[i]];
    channel.start = channel.current;
    channel.target = SETS[set_id][i];
    channel.time_remaining = FADE_TIME;
  }
}


