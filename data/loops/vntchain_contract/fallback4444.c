#include "vntlib.h"

KEY uint64 count = 0;

constructor Fallback4() {}

MUTABLE
void test1(uint64 amount){

    for(uint32 i = 1; i< amount; i++) {
        count += i;
    }

}

 
_(){
    PrintStr("fallback", "fallback");
    test1(count);
}