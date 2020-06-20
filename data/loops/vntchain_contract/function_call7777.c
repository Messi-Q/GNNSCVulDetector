#include "vntlib.h"

constructor Function7(){}


MUTABLE
uint32 test3(uint256 a){
    uint32 minutes = 0;
    do {
        PrintStr("How long is your shower(in minutes)?:", "do...while");
        minutes += 1;
    } while (minutes < 1);

    return minutes;
}

MUTABLE
uint32 test2(uint256 b, uint256 c){
    uint32 e = U256SafeAdd(b, c);
    uint32 res = test3(e);
    return res;
}

MUTABLE
uint32 test1(uint32 a){
    uint32 v = a;
    uint32 c = test2(a, v);
    return c;
}

