/*
 * RevSpace Air Hockey
 * by Juerd <#####@juerd.nl>
 * CC0
 */

#include <Button.h>
#include <PowerPin.h>

byte digits[12][7] = {
//    0 1 2 3 4 5 6
//    T T B B B T -
//      R R   L L
    { 1,1,1,1,1,1,0 },  // = 0
    { 0,1,1,0,0,0,0 },  // = 1
    { 1,1,0,1,1,0,1 },  // = 2
    { 1,1,1,1,0,0,1 },  // = 3
    { 0,1,1,0,0,1,1 },  // = 4
    { 1,0,1,1,0,1,1 },  // = 5
    { 1,0,1,1,1,1,1 },  // = 6
    { 1,1,1,0,0,0,0 },  // = 7
    { 1,1,1,1,1,1,1 },  // = 8
    { 1,1,1,0,0,1,1 },  // = 9
    { 0,0,0,0,0,0,0 },  // = off
    { 0,0,0,0,0,0,1 }   // = -
};
#define BLANK 10
#define DASH  11

// PIN ASSIGNMENTS

const byte SPECIAL = 2;
const byte SEGMENT_MID  = 11;
const byte SEGMENT_LTOP = 12;
const byte SEGMENT_LBOT = 13;
const byte SEGMENT_BOT  = A0;
const byte SEGMENT_RBOT = A1;
const byte SEGMENT_RTOP = A2;
const byte SEGMENT_TOP  = A3;

const byte P1D1 = 4;   // Player one, digit one (leftmost)
const byte P1D2 = 3;
const byte P2D1 = 10;
const byte P2D2 = 9;

const byte TD1 = 8;  // Time, digit one (leftmost)
const byte TD2 = 7;
const byte TD3 = 6;
const byte TD4 = 5;

PowerPin buzzer(A5);
Button   startbutton(A4);
Button   goal1(0);
Button   goal2(1);

void setup() {
  pinMode(SPECIAL,      OUTPUT);
  pinMode(SEGMENT_MID,  OUTPUT);
  pinMode(SEGMENT_LTOP, OUTPUT);
  pinMode(SEGMENT_LBOT, OUTPUT);
  pinMode(SEGMENT_BOT,  OUTPUT);
  pinMode(SEGMENT_RBOT, OUTPUT);
  pinMode(SEGMENT_RTOP, OUTPUT);
  pinMode(SEGMENT_TOP,  OUTPUT);
  pinMode(P1D1,         OUTPUT);
  pinMode(P1D2,         OUTPUT);
  pinMode(P2D1,         OUTPUT);
  pinMode(P2D2,         OUTPUT);
  pinMode(TD1,          OUTPUT);
  pinMode(TD2,          OUTPUT);
  pinMode(TD3,          OUTPUT);
  pinMode(TD4,          OUTPUT);
  digitalWrite(SPECIAL, HIGH);
  digitalWrite(P1D1,    HIGH);
  digitalWrite(P1D2,    HIGH);
  digitalWrite(P2D1,    HIGH);
  digitalWrite(P2D2,    HIGH);
  digitalWrite(TD1,     HIGH);
  digitalWrite(TD2,     HIGH);
  digitalWrite(TD3,     HIGH);
  digitalWrite(TD4,     HIGH);
}

// DISPLAY

void setsegments(byte plus, boolean a, boolean b, boolean c, boolean d, boolean e, boolean f, boolean g) {
  digitalWrite(plus, LOW);
  digitalWrite(SEGMENT_MID,  !a);
  digitalWrite(SEGMENT_LTOP, !b);
  digitalWrite(SEGMENT_LBOT, !c);
  digitalWrite(SEGMENT_BOT,  !d);
  digitalWrite(SEGMENT_RBOT, !e);
  digitalWrite(SEGMENT_RTOP, !f);
  digitalWrite(SEGMENT_TOP,  !g);
  delay(2);
  digitalWrite(plus, HIGH);
}

void setdigit(byte plus, byte digit) {
  setsegments(plus, digits[digit][6], digits[digit][5], digits[digit][4], digits[digit][3], digits[digit][2], digits[digit][1], digits[digit][0]);
}

// GAME

byte          score1;
byte          score2;
boolean       gameover;
byte          gamemode = 0;
unsigned long begintime;
unsigned long endtime;
unsigned long lastgoal = 0;
byte          overtime;

#define suddendeath (overtime == 2)

void show() {
  if (!gamemode) {
    setdigit(P1D1, DASH);
    setdigit(P1D2, DASH);
    setdigit(P2D1, DASH);
    setdigit(P2D2, DASH);
    return;
  }

  boolean blink = (millis() % 1000) < 500;
  if (gameover && blink) {
    setdigit(P1D1, BLANK);
    setdigit(P1D2, BLANK);
    setdigit(P1D1, BLANK);
    setdigit(P2D2, BLANK);
  }
  else {
    setdigit(P1D1, (score1 >= 10) ? (score1 / 10) : BLANK);
    setdigit(P1D2, score1 % 10);
    setdigit(P2D1, (score2 >= 10) ? (score2 / 10) : BLANK);
    setdigit(P2D2, score2 % 10);
  }

  setsegments(SPECIAL,
    /* nothing   */ 0,
    /* colon     */ (gameover || suddendeath || blink),
    /* nothing   */ 0,
    /* overtime  */ (suddendeath ? blink : overtime),
    /* gameover  */ gameover,
    /* 10minutes */ gamemode == 10,
    /* 7points   */ gamemode == 7
  );

  unsigned long time;
  if (gamemode == 10) {
    time = (gameover || suddendeath)
      ? 0
      : (1 + (endtime - millis()) / 1000);
  }
  else {
    time = gameover
      ? (endtime  - begintime) / 1000
      : (millis() - begintime) / 1000;
  }

  byte digit1 = (time / 600) % 10;
  setdigit(TD1, digit1 ? digit1 : BLANK);
  setdigit(TD2, (time / 60) % 10);
  setdigit(TD3, (time % 60) / 10);
  setdigit(TD4, (time % 10));
}


void start(byte newmode) {
  buzzer.on(200);
  score1   = 0;
  score2   = 0;
  gamemode = newmode;
  overtime = 0;
  if (gamemode == 10) {
    endtime = millis() + 600000;
  }
  else {
    begintime = millis();
    endtime = 0;
  }
  gameover = false;
}

void stop() {
  buzzer.on(2000);
  gameover = true;
}

void loop() {
  buzzer.check();
  if (startbutton.pressed()) start((score1 || score2) ? gamemode : (gamemode == 7 ? 10 : 7));

  show();

  if (gameover || !gamemode) return;

  if ((millis() - lastgoal) > 2000) {  // debounce thoroughly
    if (goal1.pressed()) { buzzer.on(800); score1++; lastgoal = millis(); }
    if (goal2.pressed()) { buzzer.on(800); score2++; lastgoal = millis(); }
  }

  if (gamemode == 7 && (score1 >= 7 || score2 >= 7)) {
    endtime = millis();
    stop();
  }

  if (suddendeath && score1 != score2) stop();

  if (gamemode == 10 && !suddendeath && (millis() >= endtime)) {
    if (score1 == score2) {
      buzzer.on(200);
      overtime++;
      endtime = millis() + 120000;
    }
    else stop();
  }
}
