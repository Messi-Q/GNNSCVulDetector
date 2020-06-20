#include "vntlib.h"

constructor Function5(){

}

MUTABLE
void test2(uint256 a, uint256 i) {
    Assert(a < i, "require a < i");
    PrintUint128T("a < i", a);
}

MUTABLE
uint32 test1() {
    uint32 a = 20;
    uint64 i = U256SafeMul(a, a);
    Require(i > a, "i > a");
    test2(a, i);

    return i;
}



MUTABLE
void test3(uint256 a, uint256 i) {
    if (a >= i) {
        Revert("require a < i");
    }
    test1();
}