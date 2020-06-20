#include "vntlib.h"

KEY uint256 count = 0;
KEY string s1 = "qian";

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
uint32 test1(string s){
    bool isDone = Equal(s, s1);
    uint32 res = test2(isDone);
    return res;
}

