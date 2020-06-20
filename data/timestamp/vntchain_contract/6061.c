#include "vntlib.h"

KEY uint64 time;
KEY uint64 timeWindow;
KEY address owner;
constructor a6061(){
    time=GetTimestamp();
    timeWindow=time+14;
    owner = GetSender();
}

MUTABLE
string BirthdayBoy(){
    Require(time <= timeWindow, "error");
    return "Happy Birthday Harrison! Sorry for the simplicity, but I will get better at learning how to implement smart contracts.";
}

