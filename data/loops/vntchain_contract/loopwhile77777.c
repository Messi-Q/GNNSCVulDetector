#include "vntlib.h"

KEY int64 count = 0;

EVENT EVENT_GETFINALCOUNT(int64 count);

constructor While7(){
}

MUTABLE
int64 test1(int64 res) {
    while(res = 200) {
        count++;
    }
    EVENT_GETFINALCOUNT(count);
    return count;
}

MUTABLE
int64 getFinalCount() {
    int64 x = 100;
    int64 res = U256SafeAdd(x, x);
    return test1(res);
}