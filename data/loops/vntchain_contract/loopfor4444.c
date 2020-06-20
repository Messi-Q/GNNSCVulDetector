#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For4(){
}

MUTABLE
uint256 test1() {
    for(uint32 i = 0; i < 1000000000000; i++) {
        count++;
        PrintStr("uint32:", "uint32 < 1000000000");
    }

    return count;
}

MUTABLE
uint256 test3() {
    uint256 res = test1();

    while(res != 0) {
        res--;
        count = U256_Add(res, count);
    }

    return count;
}

MUTABLE
uint256 test2() {
    PrintStr("test3()", "test3()");
    return test3();
}



_() {
    test3();
}