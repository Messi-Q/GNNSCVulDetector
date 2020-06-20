#include "vntlib.h"

typedef struct
{
  uint256 balance;      
  string nickName;      
  bool freeAddress;     
} Account;
 
KEY mapping(address, Account) accounts;

KEY uint256 c = 0;
KEY string ss;

constructor Function1(){}

MUTABLE
string test2(uint256 a){
    if (a > 100) {
        return "get double";
    } else {
        return "get multiple";
    }
}

MUTABLE
uint256 test1(){
    uint256 a = U256(100);

    if (a > 100) {
        c = U256SafeMul(a, a);
        ss = test2(a);
    } else {
        c = U256SafeAdd(a, a);
        ss = test2(a);
    }
    printStr("ss value", ss);

    return c;
}

 
MUTABLE
void GetFreeChips()
{
  address from = GetSender();
  accounts.key = from;
  bool flag = accounts.value.freeAddress;
  Require(flag == false, "you have got before");
  uint256 freeAmount = test1();
  accounts.value.balance = U256SafeAdd(accounts.value.balance, freeAmount);
  accounts.value.freeAddress = true;
  GetFreeChips();
}



