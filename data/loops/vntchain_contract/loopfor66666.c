#include "vntlib.h"

 
KEY int64 count = 0;

constructor For6(){
}

MUTABLE
int64 test1(){
    for (; ;) {
        count++;
    }

    return count;
}
