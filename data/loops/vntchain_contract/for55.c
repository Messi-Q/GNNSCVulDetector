#include "vntlib.h"

 
KEY uint64 count;

constructor For5(){
}

MUTABLE
uint64 test2(){

    for (int32 k = -1; k == 1; k++) {
        count++;
    }

    return count;
}

void test1() {
    PrintStr("test1()", "test1()");
    test2();
}




