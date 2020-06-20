#include "vntlib.h"

 
KEY mapping(address, uint32) account;

KEY address owner;

EVENT Deposit(indexed address  from, int32 id, uint256 value, uint256 balance);

constructor Fallback3(){
    owner = GetSender();    
}

 
MUTABLE
void $deposit(int32 id) {
    uint256 amount = GetValue();
    address from = GetSender();
    account.key = from;
    account.value = U256SafeAdd(account.value, amount);
    Deposit(GetSender(), id, GetValue(), account.value);
}

void perform() {
    string UUID = "1234-5678-9101";
    $deposit(UUID);
}

 
 
$_() {
    perform();
}


