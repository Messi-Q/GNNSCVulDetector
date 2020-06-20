#include "vntlib.h"

KEY int64 count = 0;

constructor While1(){

}

MUTABLE
int64 test1(int64 x){
     
    while(1 == 1) {
        count = x;
    }

     
    while(true) {
        count = x;
    }

    return count;
}
