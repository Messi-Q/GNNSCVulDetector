#include "vntlib.h"

 
KEY int64 count = 0;

constructor For3(){
}

MUTABLE
int64 test1(){

    for(int32 i = 10; i < 100; i--) {
        count++;
        PrintUint64T("count:", count);
    }

    return count;
}
