#include "vntlib.h"

KEY uint32 count = 0;

constructor Fallback4() {}

MUTABLE
uint32 test1(uint256 amount){

    for(uint32 i = 0; i< amount; i++) {
        count += i;
    }

}

 
_(){
   uint32 res = test1(count);
   PrintInt16T("res", res);
}