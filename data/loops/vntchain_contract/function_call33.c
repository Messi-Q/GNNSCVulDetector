#include "vntlib.h"

KEY uint256 v;

KEY mapping(address, uint32) account;

constructor Test1(){}

MUTABLE
uint256 test2(uint256 amount){
    if (amount > 50) {
        return amount;
    } else {
        return U256SafeAdd(amount, amount);
    }
}

MUTABLE
uint64 test1(uint256 amount){
    v = amount;
    uint256 vv = test2(amount);
    address to = GetSender();
    account.key = to;
    account.value = U256SafeAdd(vv, v);
    return account.value;
}

