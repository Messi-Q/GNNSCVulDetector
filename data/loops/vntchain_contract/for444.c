#include "vntlib.h"

 
KEY uint256 count;
KEY uint256 max = 65535;

constructor For4(){
}

MUTABLE
uint256 test1() {
    Require(max <= 65535, "max < 65535");

    for(uint32 i = 0; i < max; i++) {
        count++;
        PrintStr("uint32:", "uint32 > 1000000000");
    }

    return count;
}

MUTABLE
uint256 test3() {
    uint256 res = test1();
    while(res != 0) {
        res--;
        count = U256_Add(count, res);
    }

    return count;
}

MUTABLE
void test2() {
    PrintUint256T("count:", count);
    test3();
}



_() {
    test3();
}