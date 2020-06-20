#include "vntlib.h"

 
KEY int64 count = 0;

constructor For7(){
}

MUTABLE
int64 test1(){
    for (uint32 i = 1000; i > 0; i++) {
        count++;
    }

    return count;
}
