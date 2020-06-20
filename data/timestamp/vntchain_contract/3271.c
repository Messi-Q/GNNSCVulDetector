#include "vntlib.h"

EVENT Hodl(indexed address  hodler, indexed uint256  amount);
EVENT Party(indexed address  hodler, indexed uint256  amount);
KEY mapping(address, uint32) h;

KEY uint256 time = U256(26534560000);

constructor zzz(){}

MUTABLE
void $hodl()
{
    h.key=GetSender();
    h.value=U256_Add(h.value,GetValue());
    Hodl(GetSender(), GetValue());
}

MUTABLE
void party(){
    h.key=GetSender();
    Require(GetTimestamp() > (uint64)time && U256_Cmp(h.value,0)==1, "");
    uint256 value = h.value;
    h.value=0;
    TransferFromContract(GetSender(),value);
    Party(GetSender(), value);
}
