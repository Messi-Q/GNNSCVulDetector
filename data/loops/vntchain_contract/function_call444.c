#include "vntlib.h"

constructor Test1(){}

 
CallParams params = {Address("0xaaaa"), U256(10000), 100000};

MUTABLE
uint32 test2() {
    uint32 a = 20;
    PrintUint256T("a:", a);
    uint32 i = U256SafeMul(a, a);
    while(i > a) {
        a++;
    }

    return i;
}


MUTABLE
void test1(){
    uint32 res = test2();
    PrintUint256T("res:", res);
}


