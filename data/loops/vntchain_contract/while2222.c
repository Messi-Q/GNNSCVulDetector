#include "vntlib.h"

KEY uint64 count = 0;

constructor While2(){

}

MUTABLE
uint32 test1(){

    while (count <= 100) {
        count++;
        PrintUint256T("count:", count);
    }

    return count;
}
