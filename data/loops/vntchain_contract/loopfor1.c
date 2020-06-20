#include "vntlib.h"

 
KEY uint32 count = 0;

constructor For1(){}

MUTABLE
uint32 test1(){
    for (uint32 i = 0; i < 20000000000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }

    return count;
}
