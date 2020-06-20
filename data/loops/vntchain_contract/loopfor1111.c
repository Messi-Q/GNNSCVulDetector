#include "vntlib.h"

 
KEY uint64 count = 0;

constructor For1(){}

MUTABLE
uint64 test1(){
    PrintStr("uint64", "uint64");

    for (uint32 i = 0; i < 20000000000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }

    return count;
}
