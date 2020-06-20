#include "vntlib.h"

 
KEY mapping(address, uint64) account;

KEY address owner;

EVENT Deposit(indexed address  from, int32 id, uint256 value, uint256 balance);

constructor Fallback3(){
    owner = GetSender();    
}

 
MUTABLE
uint256 $deposit(int32 id) {
    uint256 amount = GetValue();
    address from = GetSender();
    account.key = from;
    account.value = U256SafeAdd(account.value, amount);
    Deposit(GetSender(), id, GetValue(), account.value);
    return account.value;
}

string perform() {
    string UUID = "1234-5678-9101";
    PrintStr("UUID", "UUID");
    $deposit(UUID);
    return UUID;
}

 
 
$_() {
    string s = perform();
    PrintStr("s",  s);
}


