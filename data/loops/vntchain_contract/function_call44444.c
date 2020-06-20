#include "vntlib.h"

constructor Test1(){}

 
CallParams params = {Address("0xaaaa"), U256(10000), 100000};

MUTABLE
uint32 test2() {
    uint32 a = 20;
    uint64 i = U256SafeMul(a, a);
    while(i > a) {
        a++;
    }
    return a;
}

MUTABLE
uint64 test1(){
    uint32 res = test2(params);
    PrintUint16T("res:", res);
    return res;
}


