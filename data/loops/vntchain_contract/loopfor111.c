#include "vntlib.h"

 
KEY uint256 count = 0;

constructor For1(){}

MUTABLE
uint256 test1(){
    PrintStr("uint256", "uint256");

    for (uint32 i = 0; i < 20000000000; i++) {
        count++;
        if(count >= 2100){
            break;
        }
    }

    return count;
}
