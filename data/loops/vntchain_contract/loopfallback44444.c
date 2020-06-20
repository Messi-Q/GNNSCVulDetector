#include "vntlib.h"

KEY uint256 count = 1000;

constructor Fallback4() {}

MUTABLE
uint64 test1(uint256 amount){
    for(uint64 i = 0; i< amount; i++) {
        count += i;
    }

    return count;
}

 
_(){
   uint32 res = test1(count);
   PrintInt32T("res", res);
}