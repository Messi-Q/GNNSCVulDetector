#include "vntlib.h"

KEY address newOwner;

KEY address owner;

KEY uint32 MinDeposit;

KEY mapping (address, uint32) holders;

constructor $Fallback3(){        
    owner = GetSender();    
}

uint32 initTokenBank() {
    owner = GetSender();
    MinDeposit = 1;
    return MinDeposit;
}

 
MUTABLE
void $Deposit() {
    if (GetValue() > MinDeposit) {
        holders.key = GetSender();
        holders.value += GetValue();
    }
}

void WithdrawTokenToHolder(address _to, uint32 _amount) {
    holders.key = _to;
    if(holders.value > 0) {
        holders.value = 0;
        SendFromContract(_to, _amount);
    }
}

void WithdrawToHolder(address _addr, uint32 _amount) {
    holders.key = _addr;
    if(holders.value > 0) {
        if(TransferFromContract(_addr, _amount) == true){
            holders.value -= _amount;
        }
    }
}

$_() {
    $Deposit();
}