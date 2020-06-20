#include "vntlib.h"

 
KEY uint64 count;

constructor For5(){
}

MUTABLE
uint64 test1(){

    for (uint32 k = -1; k == 1; k++) {
        count++;
    }

    return count;
}

void test2() {
    PrintStr("test()", "test()");
    test1();
}
