#include "vntlib.h"

 
KEY uint64 count = 1;

constructor For4(){}

MUTABLE
uint64 test2() {

    for(uint32 i = 0; i < 100000000000000; i++) {
        count++;
        PrintStr("uint16:", "uint32 < 1000000000");
    }

    return count;
}

MUTABLE
uint32 test1() {

    uint32 res = test2();

    while(res > 0) {
        res--;
        count += res;
    }

    return count;
}


_() {
    test1();
}