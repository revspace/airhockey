#include <Button.h>

byte digits[10][7] = {
#     0 1 2 3 4 5 6
#     T T B B B T -
#       R R   L L
    { 1,1,1,1,1,1,0 },  // = 0
    { 0,1,1,0,0,0,0 },  // = 1
    { 1,1,0,1,1,0,1 },  // = 2
    { 1,1,1,1,0,0,1 },  // = 3
    { 0,1,1,0,0,1,1 },  // = 4
    { 1,0,1,1,0,1,1 },  // = 5
    { 1,0,1,1,1,1,1 },  // = 6
    { 1,1,1,0,0,0,0 },  // = 7
    { 1,1,1,1,1,1,1 },  // = 8
    { 1,1,1,0,0,1,1 }   // = 9
};

const byte SEGMENT_MID = 19;
const byte SEGMENT_LTOP = 20;
const byte SEGMENT_LBOT = 2;
const byte SEGMENT_BOT = 3;
const byte SEGMENT_RBOT = 4;
const byte SEGMENT_RTOP = 5;
const byte SEGMENT_TOP = 6;

void setsegment(byte plus, byte digit) {
    digitalWrite(plus, HIGH);
    digitalWrite(SEGMENT_MID,  !digits[digit][6]);
    digitalWrite(SEGMENT_LTOP, !digits[digit][5]);
    digitalWrite(SEGMENT_LBOT, !digits[digit][4]);
    digitalWrite(SEGMENT_BOT,  !digits[digit][3]);
    digitalWrite(SEGMENT_RBOT, !digits[digit][2]);
    digitalWrite(SEGMENT_RTOP, !digits[digit][1]);
    digitalWrite(SEGMENT_TOP,  !digits[digit][0]);
}

const byte P1D1 = 9;
const byte P1D2 = 10;
const byte P2D1 = 11;
const byte P2D2 = 12;
const byte SPECIAL = 13;
const byte TD1 = 14;

Button start7(7);  //  7 points
Button start10(8); // 10 minutes; future
Button goal1(21);
Button goal2(22);
PowerPin beeper(23);

byte score1;
byte score2;

void show() {
    setsegment(P1D2, score1);
    setsegment(P2D2, score2);
}

void setup() {
    score1 = 0;
    score2 = 0;
    show();
}

void loop() {
    if (start7.pressed()) setup();

    if (score1 >= 7 || score2 >= 7) return;

    if (goal1.pressed()) { beeper.on(200); score1++; }
    if (goal2.pressed()) { beeper.on(200); score2++; }

    show();

    start7.check();
    start10.check();
    beeper.check();
}
