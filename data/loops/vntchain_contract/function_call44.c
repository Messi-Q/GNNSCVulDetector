#include "vntlib.h"

constructor Test1(){}

 
CallParams params = {Address("0xaaaa"), U256(10000), 100000};

MUTABLE
uint256 test2() {
    uint256 a = 20;
    PrintUint256T("a:", a);
    uint256 i = U256SafeMul(a, a);
    while(i > a) {
        a++;
    }

    return i;
}


MUTABLE
uint256 test1(){
    uint256 res = test2();
    PrintUint256T("res:", res);
    return res;
}



