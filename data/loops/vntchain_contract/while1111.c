#include "vntlib.h"

KEY uint32 count = 0;

constructor While1(){

}

MUTABLE
uint64 test1(uint256 x){

    count = x;

    while (count < 100) {
        count++;
    }

    return count;
}
