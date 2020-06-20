#include "vntlib.h"

KEY uint64 amount = 100;

typedef struct fallback7 {
    uint64 balance;      
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback7() {}

uint64 getRes(address addr, uint32 amount) {
    accounts.key = addr;

    uint64 balance = accounts.value.balance;
    uint64 res = U256SafeAdd(balance, amount);

    return res;
}

MUTABLE
void test1(){
    PrintStr("getRes()", "getRes()");
    getRes(GetSender(), amount);
}
 
_(){
    PrintStr("fallback", "fallback");
    test1();
}