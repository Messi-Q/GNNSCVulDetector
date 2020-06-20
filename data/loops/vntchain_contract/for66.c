#include "vntlib.h"

 
KEY uint64 count;

constructor For6(){}

MUTABLE
uint64 test1(){
    PrintStr("uint8", "uint8 > 250");

    for (uint32 i =0; i < 250; i++) {
        count++;
    }

    return count;
}
