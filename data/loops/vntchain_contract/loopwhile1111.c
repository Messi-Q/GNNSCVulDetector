#include "vntlib.h"

KEY int32 count = 0;

constructor While1(){}

MUTABLE
int32 test1(uint256 x){
     
    while(1 == 1) {
        count = x;
    }

     
    while(true) {
        count = x;
    }

    return count;
}
