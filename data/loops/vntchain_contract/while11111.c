#include "vntlib.h"

KEY int32 count = 0;

constructor While1(){}

MUTABLE
int32 test1(int32 x){

    count = x;

    while (count < 100) {
        count++;
    }

    return count;
}
