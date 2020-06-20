#include "vntlib.h"

KEY uint32 res = 100;

typedef struct fallback4 {
    uint32 balance;
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback5() {}

uint32 getRes(address addr) {
    accounts.key = addr;

    uint32 balance = accounts.value.balance;
    Require(balance > 0, "balance > 0");

    while(balance > 0) {
        res += balance;
    }

    return res;
}

MUTABLE
void test1(){
    uint32 res = getRes(GetSender());
    PrintUint32T("uint16", res);
}

 
_(){
   test1();
}