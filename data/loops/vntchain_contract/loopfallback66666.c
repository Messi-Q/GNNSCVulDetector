#include "vntlib.h"

KEY int64 amount = 100;

typedef struct fallback4 {
    int64 balance;
    string nickName;      
} Account;

 
KEY mapping(address, Account) accounts;

constructor Fallback6() {}

int64 getRes(address addr, int64 amount) {
    accounts.key = addr;

    int64 balance = accounts.value.balance;
    int64 res = U256SafeAdd(balance, amount);

    return res;
}

MUTABLE
void test1(){
    getRes(GetSender(), amount);
}



int64 test2(){
    Require(accounts.value.balance > 0, "balance > 0");
    int64 res = accounts.value.balance;
    while (res > 0) {
        test1();
    }

    return res;
}

 
_(){
   test2();
}