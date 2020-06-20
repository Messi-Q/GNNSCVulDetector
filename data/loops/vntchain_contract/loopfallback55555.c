#include "vntlib.h"

KEY int32 res = 100;

typedef struct fallback4 {
    int32 balance;
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback5() {}

int32 getRes(address addr) {
    accounts.key = addr;

    int32 balance = accounts.value.balance;
    while(balance >= 0) {
        res += balance;
    }

    return res;
}

MUTABLE
void test1(){
    int32 res = getRes(GetSender());
    PrintUint32T("uint256", res);
}



 
_(){
   test1();
}