#include "vntlib.h"

constructor Function8(){}

MUTABLE
uint64 test2(uint256 b, uint256 c){
    uint32 i = 0;
    uint32 e = U256SafeAdd(b, c);
    do {
        i++;
        e -= i;
    } while(e > 0);

    return i;
}


MUTABLE
uint32 test1(uint32 a){
    PrintStr("v = a", "v = a");
    uint64 v = a;
    uint64 c = test2(a, v);
    return c;
}



