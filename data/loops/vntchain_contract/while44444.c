#include "vntlib.h"

KEY int32 count = 0;

EVENT EVENT_GETFINALCOUNT(int32 count);

constructor While4(){
}

MUTABLE
int32 test1(int32 res) {

    while(count < res) {
        count += 2;
    }

    return count;
}

MUTABLE
int32 getFinalCount() {
    int32 x = 1000;
    int32 res = U256SafeAdd(x, x);
    EVENT_GETFINALCOUNT(count);
    return test1(res);
}