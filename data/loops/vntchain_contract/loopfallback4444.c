#include "vntlib.h"

KEY uint256 count = U256(1000);

constructor Fallback4() {}

MUTABLE
uint64 test1(uint64 amount){
    PrintStr("count", "amount");

    for(uint32 i = 0; i< amount; i++) {
        count += i;
    }

    return count;
}

 
_(){
   uint64 res = test1(count);
   PrintUint64T("res", res);
}