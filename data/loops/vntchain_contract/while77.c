#include "vntlib.h"

KEY uint64 count = 0;

EVENT EVENT_GETFINALCOUNT(uint64 count);

constructor While7(){}

MUTABLE
uint64 test(uint64 res) {
    PrintStr("while", "while");

    while(res == 100) {
        count++;
    }
    EVENT_GETFINALCOUNT(count);
    return count;
}
MUTABLE
uint64 getFinalCount() {
    uint256 x = 100;
    uint256 res = U256SafeAdd(x, x);
    return test(res);
}

