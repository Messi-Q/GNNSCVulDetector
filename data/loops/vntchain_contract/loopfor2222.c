#include "vntlib.h"

 
KEY int32 count = 0;

constructor For2(){
}

MUTABLE
int32 test1(){
    int32 x = 0;
    for (uint32 i = 0; i < 2000; i++) {
        for(int32 j = 0; j < 100000000000; j++){
            count += 2;
            if(count > 50) {
                x = count;
            }
        }
    }
    return x;
}

 
MUTABLE
int32 GetCount() {
    PrintStr("test1()", "test1()");
    return test1();
}