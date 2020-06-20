#include "vntlib.h"

constructor Function8(){}

MUTABLE
uint32 test2(uint32 b, uint32 c){
    uint32 i = 0;
    uint64 e = U256SafeAdd(b, c);
    do {
        i++;
        e -= i;
    } while(e > 0);

    return i;
}

MUTABLE
uint32 test1(uint32 amount){
    uint64 v =amount;
    uint64 c = test2(amount, v);
    return c;
}




