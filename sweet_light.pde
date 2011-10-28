// How many settings do we have
#define SET_COUNT 5
// Number of channels to use
#define CHANNELS 5
// How many and which channels are used in the settings
#define SET_CHANNELS_COUNT 3
// How long should a fade take in ms
#define FADE_TIME 10000


const int SET_CHANNELS[] = {2, 3, 4};

// Channel settings
const int SETS[][SET_CHANNELS_COUNT] = {
  {255, 128,  80},
  {128,   0,  60},
  {128, 128,  60},
  {  0,   0,   0},
  {128,   0,  60}
};

int channel_values_current[CHANNELS];
int channel_values_target[CHANNELS];
int fade_time_remaining;




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
  for (int i=0; i<CHANNELS; i++) channel_values_current[i] = 0;
  
  // load first set
  for (int i=0; i<SET_CHANNELS_COUNT; i++) channel_values_current[SET_CHANNELS[i]] = SETS[0][i];
  
  // target == current
  for (int i=0; i<CHANNELS; i++) channel_values_target[i] = channel_values_current[i];
  
  // no fade time remaining => don't fade
  fade_time_remaining = 0;
}

void loop() {
  int button = checkButtons();
  if (button>=0 && button<SET_COUNT) fadeToSet(button);
}

int checkButtons() {
  
}

void fadeToSet(int set_id) {
  // load set
  for (int i=0; i<SET_CHANNELS_COUNT; i++) channel_values_target[SET_CHANNELS[i]] = SETS[set_id][i];
  fade_time_remaining = FADE_TIME;
}


