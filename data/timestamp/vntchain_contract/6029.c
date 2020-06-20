#include "vntlib.h"

EVENT Hodl(indexed address  _hodler, uint256  _amount);
EVENT Party(indexed address  _hodler, uint256  _amount);
KEY mapping(address,uint32) hodlers;

KEY uint256 Time = U256(1535780000);

constructor a6029(){}

MUTABLE
void $DEP()
{
    hodlers.key=GetSender();
    hodlers.value=U256_Add(hodlers.value,GetValue());
    Hodl(GetSender(), GetValue());
}

MUTABLE
void party(){
    hodlers.key=GetSender();
    Require(GetTimestamp() > (uint64)Time && U256_Cmp(hodlers.value,0)==1,"error");
    uint256 value = hodlers.value;
    hodlers.value=0;
    TransferFromContract(GetSender(),value);
    Party(GetSender(), value);
}
