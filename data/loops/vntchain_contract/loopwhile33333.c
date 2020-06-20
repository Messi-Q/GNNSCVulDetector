#include "vntlib.h"

KEY int64 count = 0;
KEY string ss = "qian";

constructor While3(){
}

MUTABLE
int64 test2(bool isDone){
     while(count < 3) {
        if(isDone) {
            continue;
        }
        count++;
     }
     return count;
}
 
MUTABLE
int64 test1(string s){
    int64 isDone = Equal(s, ss);
    int64 res = test2(isDone);
    return res;
}


