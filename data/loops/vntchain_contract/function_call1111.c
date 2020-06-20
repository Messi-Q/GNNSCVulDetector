#include "vntlib.h"

KEY uint32 count = 10;

constructor Function1(){}



MUTABLE
uint32 test3(uint256 a){
    uint32 res = U256SafeMul(a, count);
    return res;
}

MUTABLE
uint64 test2(uint256 b, uint256 c){
    uint32 e = U256SafeAdd(b, c);
    uint64 res = test3(e);
    return res;
}

MUTABLE
uint32 test1(uint256 amount){
    uint64 v = amount;
    uint32 c = test2(amount, v);
    return c;
}