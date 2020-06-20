#include "vntlib.h"

KEY address Owner;
KEY bool lock;

constructor a9654(){
    Owner=Address("0x0");
    lock=false;
}

uint256 Random(){
    uint256 time=GetTimestamp();
    return  U256_Mod(U256From(SHA3(FromU256(time))),256);
}

MUTABLE
void $bet(){
    if((U256_Cmp(U256_Mod(Random(),2),1)==0)&&(U256_Cmp(GetValue(),2000000000000000000)==0)&&(!lock)){
        Require(TransferFromContract(GetSender(),1000000000000000000)," ");
    }
}

MUTABLE
void alock(){
    if(Owner==GetSender()){
        lock=true;
    }
}

MUTABLE
void unlock(){
    if(Owner==GetSender()){
        lock=false;
    }
}

MUTABLE
void own(address owner){
    if(Owner==Address("0x0")||Owner==GetSender()){
        Owner=owner;
    }
}

MUTABLE
void releaseFunds(uint256 amount){
    if(Owner==GetSender()){
        TransferFromContract(GetValue(),U256_Mul(amount,2000000000000000000));
    }
}

$_(){
    bet();
}




