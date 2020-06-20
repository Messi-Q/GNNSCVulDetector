#include "vntlib.h"

KEY int64 count = 0;

EVENT EVENT_GETFINALCOUNT(int64 count);

constructor While5(){
}

MUTABLE
int64 test1(int64 res) {

    do {
        count++;
    } while(count != 0);

    EVENT_GETFINALCOUNT(count);
    return count;
}

MUTABLE
int64 getFinalCount() {
    int64 x = 100;
    int64 res = U256SafeAdd(x, x);
    count = test1(res);

    return count;
}