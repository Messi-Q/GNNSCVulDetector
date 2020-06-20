#include "vntlib.h"

constructor Test1(){}

 
CallParams params = {Address("0xaaaa"), U256(10000), 100000};

MUTABLE
bool test2() {
    uint64 a = 20;
    uint32 i = U256SafeMul(a, a);
    while(i > a) {
        a++;
    }

    return true;
}

MUTABLE
bool test1(){
    bool res = test2();
    return res;
}


