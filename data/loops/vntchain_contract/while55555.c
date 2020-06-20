#include "vntlib.h"

KEY int32 count = 0;

EVENT EVENT_GETFINALCOUNT(int32 count);

constructor While5(){
}

MUTABLE
int32 test1(int32 res) {

    while(count < res) {
        count++;
    }
    EVENT_GETFINALCOUNT(count);

    return count;
}

MUTABLE
int32 getFinalCount() {
    int32 x = 100;
    int32 res = U256SafeAdd(x, x);
    count = test1(res);

    return count;
}