#include "vntlib.h"

 
KEY int64 count = 0;

constructor For2(){
}

MUTABLE
int64 test1(){
    int64 x = 0;
    for (uint32 i = 0; i < 2000; i++) {
        for(int32 j = 0; j < 1000000000000; j++){
            count += 2;
            if(count > 50) {
                x = count;
            }
        }
    }
    return x;
}

 
MUTABLE
int64 GetCount() {
    return test1();
}