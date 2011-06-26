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

const byte SPECIAL = 2;
const byte SEGMENT_MID  = 11;
const byte SEGMENT_LTOP = 12;
const byte SEGMENT_LBOT = 13;
const byte SEGMENT_BOT  = A0;
const byte SEGMENT_RBOT = A1;
const byte SEGMENT_RTOP = A2;
const byte SEGMENT_TOP  = A3;

const byte P1D1 = 4;
const byte P1D2 = 3;
const byte P2D1 = 10;
const byte P2D2 = 9;

const byte TD1 = 8;
const byte TD2 = 7;
const byte TD3 = 6;
const byte TD4 = 5;

PowerPin beeper(0);
Button start(1);  //  7 points
Button goal1(A4);
Button goal2(A5);


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

byte score1;
byte score2;
boolean win;
byte gamemode = 0;
unsigned long endtime = 0;
byte overtime = 0;  // 1 = overtime, 2 = sudden death

void show() {


    if (!gamemode) {
      setdigit(P1D1, 11); 
      setdigit(P1D2, 11); 
      setdigit(P2D1, 11); 
      setdigit(P2D2, 11); 
      return;
    }

    boolean blink = (millis() % 1000) < 500;
    if (!win || blink) {
      setdigit(P1D1, (score1 >= 10) ? (score1 / 10) : 10);
      setdigit(P1D2, score1 % 10);
      setdigit(P2D1, (score2 >= 10) ? (score2 / 10) : 10);
      setdigit(P2D2, score2 % 10);
    } else {
      setdigit(P1D1, 10);
      setdigit(P1D2, 10);
      setdigit(P1D1, 10);
      setdigit(P2D2, 10);
    }
    
    setsegments(SPECIAL, 0, (gamemode == 10 ? (win ? 1 : blink) : 0), 0, (overtime == 2 ? blink : overtime), win, gamemode == 10, gamemode == 7);


    if (gamemode != 10) return;
    
    unsigned long timeleft = (win || overtime == 2) ? 0 : (1 + (endtime - millis()) / 1000);
    byte digit1 = (timeleft / 600) % 10;
    setdigit(TD1, digit1 ? digit1 : 10);
    setdigit(TD2, (timeleft / 60) % 10);
    setdigit(TD3, (timeleft % 60) / 10);
    setdigit(TD4, (timeleft % 10));

}

void setup() {
    pinMode(SEGMENT_MID,  OUTPUT);
    pinMode(SEGMENT_LTOP, OUTPUT);
    pinMode(SEGMENT_LBOT, OUTPUT);
    pinMode(SEGMENT_BOT,  OUTPUT);
    pinMode(SEGMENT_RBOT, OUTPUT);
    pinMode(SEGMENT_RTOP, OUTPUT);
    pinMode(SEGMENT_TOP,  OUTPUT);
    pinMode(P1D1, OUTPUT);
    pinMode(P1D2, OUTPUT);
    pinMode(P2D1, OUTPUT);
    pinMode(P2D2, OUTPUT);
    pinMode(TD1, OUTPUT);
    pinMode(TD2, OUTPUT);
    pinMode(TD3, OUTPUT);
    pinMode(TD4, OUTPUT);
    digitalWrite(P1D1, HIGH);
    digitalWrite(P1D2, HIGH);
    digitalWrite(P2D1, HIGH);
    digitalWrite(P2D2, HIGH);
    digitalWrite(TD1, HIGH);
    digitalWrite(TD2, HIGH);
    digitalWrite(TD3, HIGH);
    digitalWrite(TD4, HIGH);
    pinMode(SPECIAL, OUTPUT);
    digitalWrite(SPECIAL, HIGH);

}



void setup7() {
    score1 = 0;
    score2 = 0;
    gamemode = 7;
    overtime = 0;
    win = false;
    show();
}

void setup10() {
    score1 = 0;
    score2 = 0;
    gamemode = 10;
    overtime = 0;
    win = false;
    endtime = millis() + 600000;
    show();
}

void winner() {
  win = 1;
  beeper.on(2000);
}

void loop() {
    if (start.pressed()) {
      if (win) gamemode == 10 ? setup10() : setup7();
      else gamemode == 7 ? setup10() : setup7();
      beeper.on(200);
    }

    show();

    if (!gamemode) return;
    beeper.check();
    
    if (win) return;
    
    if (gamemode == 7 && (score1 >= 7 || score2 >= 7)) {
        winner();
        return;
    }
    if (overtime != 2 && gamemode == 10 && (millis() >= endtime)) {
        if (score1 == score2) {
          if (overtime == 1) {
            overtime = 2;
          } else {
            overtime = 1;
            endtime = millis() + 120000;
          }
          return;
        }
        winner();
        return;
    }
    if (overtime == 2 && (score1 != score2)) {
      winner();
      return;
    }
    
    if (goal1.pressed()) { beeper.on(800); score1++; }
    if (goal2.pressed()) { beeper.on(800); score2++; }
}
