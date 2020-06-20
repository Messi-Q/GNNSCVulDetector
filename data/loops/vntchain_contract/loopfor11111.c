#include "vntlib.h"

 
KEY int64 count = 0;

constructor For1(){}

MUTABLE
int64 test1(){
    for (int64 i = 0; i < 2000000000000000000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }

    return count;
}
