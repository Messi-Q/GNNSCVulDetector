#include "vntlib.h"

KEY uint64 amount = 100;

typedef struct fallback4 {
    uint32 balance;
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback6() {}

uint32 getRes(address addr, uint64 amount) {
    accounts.key = addr;

    uint256 balance = accounts.value.balance;
    uint32 res = U256SafeAdd(balance, amount);

    return res;
}

MUTABLE
void test1(){
    getRes(GetSender(), amount);
}

uint64 test2(){
    Require(accounts.value.balance > 0, "balance > 0");
    uint32 res = accounts.value.balance;
    if (res > 0) {
        test1();
    }

    return res;
}

 
_(){
   test2();
}