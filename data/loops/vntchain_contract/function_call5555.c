#include "vntlib.h"

constructor Function5(){}



MUTABLE
void test3(uint256 a, uint256 i) {
    Assert(a < i, "require a < i");
}

MUTABLE
uint32 test2() {
    uint32 a = 20;
    uint256 i = U256SafeMul(a, a);

    while(i > a) {
        Require(i > a, "i > a");
        test3(a, i);
        i--;
    }

    return i;
}

MUTABLE
void test1(){
    uint64 res = test2();
    PrintUint64T("recurrent times:", res);
}