#include "vntlib.h"

KEY uint64 count = 10;

constructor Function2(){}

MUTABLE
uint32 test2(uint256 b, uint256 c){
    uint64 e = U256SafeAdd(b, c);
    uint32 res = U256SafeSub(e, count);
    return res;
}

MUTABLE
uint32 test1(uint32 a){
    uint64 v = a;
    uint32 c = test2(a, v);
    return c;
}




