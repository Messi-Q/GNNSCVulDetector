#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For8(){
}

MUTABLE
uint256 test1(){
    for (uint64 i = 100; i > 0; i--) {
        for (uint64 j = i; j < 50; j++) {
            if (j > 100) {
                count = j;
                PrintUint256T("remark", j);
            }
        }
    }

    return count;
}
