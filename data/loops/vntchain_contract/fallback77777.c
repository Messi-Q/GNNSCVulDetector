#include "vntlib.h"

KEY uint32 amount = 100;

typedef struct fallback7 {
    uint32 balance;
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback7() {}

uint64 getRes(address addr, uint64 amount) {
    accounts.key = addr;

    uint32 balance = accounts.value.balance;
    uint32 res = U256SafeAdd(balance, amount);

    return res;
}

MUTABLE
void test1(){
    getRes(GetSender(), amount);
}

 
_(){
    test1();
}