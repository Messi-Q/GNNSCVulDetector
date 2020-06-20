#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For4(){
}

MUTABLE
uint32 test1() {

    for(uint32 i = 0; i < 100000000000000; i++) {
        count++;
        PrintStr("uint16:", "uint32 < 1000000000000");
    }

    return count;
}

MUTABLE
uint32 test3() {

    uint32 res = test1();

    while(res != 0) {
        res--;
        count += res;
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