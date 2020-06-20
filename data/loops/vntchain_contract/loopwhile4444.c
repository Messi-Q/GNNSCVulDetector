#include "vntlib.h"

KEY uint256 count = 0;

EVENT EVENT_GETFINALCOUNT(uint256 count);

constructor While4(){
}

MUTABLE
int32 test1(uint256 res) {
    while(count < res) {
        count++;
        if(count > 100) {
            count = 0;
        }
    }

    EVENT_GETFINALCOUNT(count);

    return count;
}

MUTABLE
int32 getFinalCount() {
    int32 x = 100;
    int32 res = U256SafeAdd(x, x);

    return test1(res);
}