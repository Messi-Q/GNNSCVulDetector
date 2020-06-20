#include "vntlib.h"

EVENT CHANGE(indexed address  _hodler, uint256  _amount);
EVENT TRANSFER(indexed address  _hodler, uint256  _amount);
KEY mapping(address,uint32) hodlers;

KEY uint256 time = U256(1635780000);

constructor a6030(){}

MUTABLE
void $D()
{
    hodlers.key=GetSender();
    hodlers.value=U256_Add(hodlers.value,GetValue());
    CHANGE(GetSender(), GetValue());
}


void P(){
    hodlers.key=GetSender();
    Require(GetTimestamp() >= (uint64)time && U256_Cmp(hodlers.value,0)==1,"ERROR");
    uint256 value = hodlers.value;
    hodlers.value=0;
    TransferFromContract(GetSender(),value);
    TRANSFER(GetSender(), value);
}
