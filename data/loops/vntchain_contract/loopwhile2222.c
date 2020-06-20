#include "vntlib.h"

KEY int32 count = 0;

constructor While2(){
}

MUTABLE
int32 test1(int32 x){
    while (count <= 100)
        PrintUint32T("count:", count);
    count++;

    return count;
}
