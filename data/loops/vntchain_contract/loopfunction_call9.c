#include "vntlib.h"

constructor Function5(){}

MUTABLE
uint256 test1(){
    uint32 res = test1();
    PrintUint256T("recurrent times:", res);
    return res;
}

MUTABLE
void test3(uint256 a, uint256 i) {
    Assert(a < i, "require a < i");
    if (a >= i) {
        Revert("require a < i");
    }
    test1();
}

MUTABLE
uint256 test2() {
    uint256 a = 20;
    PrintUint256T("a:", a);
    uint256 i = U256SafeMul(a, a);
    Require(i > a, "i > a");
    test3(a, i);

    return i;
}



