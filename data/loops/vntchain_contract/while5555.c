#include "vntlib.h"

KEY uint32 count = 0;

EVENT EVENT_GETFINALCOUNT(uint64 count);

constructor While5(){
}

MUTABLE
uint32 test1(uint64 res) {

    while(count < res) {
        count++;
    }
    EVENT_GETFINALCOUNT(count);

    return count;
}

MUTABLE
uint64 getFinalCount() {
    uint256 x = 100;
    uint64 res = U256SafeAdd(x, x);
    count = test1(res);

    return count;
}