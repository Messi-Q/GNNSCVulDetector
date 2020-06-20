#include "vntlib.h"

KEY int64 count = 0;

EVENT EVENT_GETFINALCOUNT(int64 count);

constructor While4(){
}

MUTABLE
int64 test1(int64 res) {

    while(count < res) {
        count++;
        if(count > 100) {
            count = 0;
        }
    }

    return count;
}

MUTABLE
int64 getFinalCount() {
    int64 x = 100;
    int64 res = U256SafeAdd(x, x);
    EVENT_GETFINALCOUNT(count);
    return test1(res);
}