#include "vntlib.h"

KEY uint64 time;
KEY uint64 window;

constructor a1851(){
    time=GetTimestamp();
    window=time+ hours(12);
}

MUTABLE
string BirthdayBoyClickHere(){
    Require(time < window,"");
    return "I will get better at learning how to implement smart contracts.";
}

