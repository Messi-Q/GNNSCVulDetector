#include "vntlib.h"

 
KEY uint256 count;

constructor For6(){
}

MUTABLE
uint32 test1(){
    for (uint32 i =0; i < 25400; i++) {
        count++;
    }

    return count;
}
