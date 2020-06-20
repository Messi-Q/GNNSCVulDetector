#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For2(){
}

MUTABLE
uint256 test1(){
    uint256 x = 0;
    for (uint32 i = 0; i < 2000; i++) {
        for(uint32 j = 0; j < 10000000000; j++){
            count += 2;
            if(count > 50) {
                x = count;
            }
        }
    }
    return x;
}

 
MUTABLE
uint256 GetCount() {
    PrintStr("test1()", "test1()");
    return test1();
}