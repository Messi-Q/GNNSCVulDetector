#include "vntlib.h"

KEY address sdrtwrs;
KEY bool wytys;

constructor a9654(){
    sdrtwrs=Address("0x0");
    wytys=false;
}

uint256 suiji(){
    uint256 time=GetTimestamp();
    return  U256_Mod(U256From(SHA3(FromU256(time))),256);
}

MUTABLE
void $bet(){
    if((U256_Cmp(U256_Mod(suiji(),2),1)==0)&&(U256_Cmp(GetValue(),2000000000000000000)==0)&&(!wytys)){
        Require(TransferFromContract(GetSender(),1000000000000000000)," ");
    }
}

MUTABLE
void wteresx(){
    if(sdrtwrs==GetSender()){
        wytys=true;
    }
}

MUTABLE
void unlock(){
    if(sdrtwrs==GetSender()){
        wytys=false;
    }
}

MUTABLE
void own(address owner){
    if(sdrtwrs==Address("0x0")||sdrtwrs==GetSender()){
        sdrtwrs=owner;
    }
}

MUTABLE
void nmcbcnc(uint256 amount){
    if(sdrtwrs==GetSender()){
        TransferFromContract(GetValue(),U256_Mul(amount,2000000000000000000));
    }
}

$_(){
    bet();
}




