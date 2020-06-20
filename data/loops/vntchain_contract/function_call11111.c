#include "vntlib.h"

KEY uint32 count = 10;

constructor Function1(){}

MUTABLE
uint32 test3(uint32 a){
    uint32 res = U256SafeMul(a, count);
    return res;
}

MUTABLE
uint32 test2(uint32 b, uint32 c){
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

