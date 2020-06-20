#include "vntlib.h"

KEY uint64 count = 0;
KEY string ss = "qian";

constructor While3(){
}

MUTABLE
uint32 test2(bool isDone){
     while(count < 3) {
        if(isDone) {
            count++;
            continue;
        }
        count++;
     }
     return count;
}

 
MUTABLE
uint64 test1(string s){
    bool isDone = Equal(s, ss);
    uint256 res = test2(isDone);
    return res;
}


