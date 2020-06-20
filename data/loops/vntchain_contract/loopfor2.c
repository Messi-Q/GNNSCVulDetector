#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For2(){
}

MUTABLE
uint32 test1(){
    uint32 x = 0;
    for (uint32 i = 0; i < 2000; i++) {
        for(uint32 j = 0; j < 1000000000000; j++){
            count += 2;
            if(count > 50) {
                x = count;
            }
        }
    }
    return x;
}

 
MUTABLE
uint32 GetCount() {
    return test1();
}