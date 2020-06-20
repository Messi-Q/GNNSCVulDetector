#include "vntlib.h"

 
KEY int64 count = 0;

constructor For4(){
}

MUTABLE
int64 test1() {

    for(int64 i = 0; i < 1000000000; i++) {
        count++;
        PrintStr("uint16:", "uint16 < 1000000000");
    }

    return count;
}

MUTABLE
int64 test3() {

    int64 res = test1();

    while(res != 0) {
        res--;
        count = U256_Add(res, count);
    }

    return count;
}

MUTABLE
void test2() {
    PrintUint64T("count:", count);
    test3();
}



_() {
    test3();
}