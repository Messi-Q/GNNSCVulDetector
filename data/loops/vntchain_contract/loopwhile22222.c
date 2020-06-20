#include "vntlib.h"

KEY int64 count = 0;

constructor While2(){
}

MUTABLE
int64 test1(int64 x){
    while (count <= 100)
        PrintUint64T("count:", count);
    count++;

    return count;
}
