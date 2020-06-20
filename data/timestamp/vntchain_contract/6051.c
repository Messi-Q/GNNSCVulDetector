#include "vntlib.h"

KEY uint64 time;
KEY uint64 timeWindow;

constructor a6051(){
    time=GetTimestamp();
    timeWindow=time+14;
}

MUTABLE
string BirthdayBoy(){
    Require(time < timeWindow, "");
    return "Happy Birthday Harrison! Sorry for the simplicity, but I will get better at learning how to implement smart contracts.";
}

