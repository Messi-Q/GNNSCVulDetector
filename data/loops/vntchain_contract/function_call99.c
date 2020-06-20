#include "vntlib.h"

KEY uint256 res = 0;

constructor Function5(){
    PrintUint256T("recurrent times:", res);
}

MUTABLE
void test3(uint256 a, uint256 i) {
    Assert(a < i, "require a < i");
    PrintUint256T("a < i", a);
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

MUTABLE
uint64 test1(uint256 a, uint256 i) {
    if (a >= i) {
        Revert("require a < i");
    }
    uint64 ai = test2();
    return ai;
}


