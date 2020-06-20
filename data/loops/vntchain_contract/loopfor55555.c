#include "vntlib.h"

 
KEY int64 count = 0;

constructor For5(){
}

MUTABLE
int64 test1(){

    for (int32 k = -1; k = 1; k++) {
        count++;
    }

    return count;
}

void test2() {
    test1();
}
