#include "vntlib.h"

 
KEY uint64 count = 0;

constructor For7(){
}

MUTABLE
uint64 test1(){
    for (uint32 i = 1000; i > 0; i-=2) {
        count++;
    }

    return count;
}
