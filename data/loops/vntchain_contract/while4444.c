#include "vntlib.h"

KEY uint64 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While4(){
}

MUTABLE
uint32 test1(uint256 res) {
    EVENT_GETFINALCOUNT(count);

    while(count < res) {
        count += 2;
    }

    return count;
}

MUTABLE
uint64 getFinalCount() {
    uint32 x = 1000;
    uint32 res = U256SafeAdd(x, x);
    return test1(res);
}