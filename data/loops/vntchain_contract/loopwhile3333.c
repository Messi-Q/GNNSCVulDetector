#include "vntlib.h"

KEY int32 count = 0;
KEY string ss = "qian";

constructor While3(){
}


MUTABLE
int32 test2(bool isDone){
     while(count < 3) {
        if(isDone) {
            continue;
        }
        count++;
     }
     return count;
}

 
MUTABLE
int32 test1(string s){
    int32 isDone = Equal(s, ss);
    int32 res = test2(isDone);
    return res;
}

