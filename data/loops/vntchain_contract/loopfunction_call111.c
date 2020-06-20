#include "vntlib.h"

constructor Function1(){}

MUTABLE
uint256 test3(uint256 a){
    uint256 res1 = U256SafeAdd(a, a);
    uint256 res2 = test3(res1);
    return res2;
}

MUTABLE
uint256 test2(uint256 b, uint256 c){
    uint256 e = U256SafeAdd(b, c);
    uint256 res = test3(e);
    return res;
}

MUTABLE
uint256 test1(uint256 amount){
    uint256 v = amount;
    PrintStr("v = amount", "v = amount");
    uint256 c = test2(amount, v);
    return c;
}

