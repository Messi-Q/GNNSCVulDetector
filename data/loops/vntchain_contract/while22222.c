#include "vntlib.h"

KEY int32 count = 0;

constructor While2(){

}

MUTABLE
int32 test1(){

    while (count <= 100) {
        count++;
        Printint32T("count:", count);
    }

    return count;
}
