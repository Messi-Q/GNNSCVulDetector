#include "vntlib.h"

 
KEY uint32 count = 0;

constructor For6(){
}

MUTABLE
uint32 test1(){
    for (uint32 i =0; i < 254; i++) {
        count++;
    }

    return count;
}
