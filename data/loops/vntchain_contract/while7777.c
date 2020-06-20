#include "vntlib.h"

KEY uint32 count = 0;

EVENT EVENT_GETFINALCOUNT(uint32 count);

constructor While7(){
}

MUTABLE
uint64 test1(uint64 res) {
    while(res == 100) {
        count++;
    }
    EVENT_GETFINALCOUNT(count);
    return count;
}

MUTABLE
uint32 getFinalCount() {
    uint64 x = 100;
    uint64 res = U256SafeAdd(x, x);
    return test1(res);
}