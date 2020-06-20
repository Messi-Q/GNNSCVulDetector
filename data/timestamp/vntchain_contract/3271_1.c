#include "vntlib.h"

EVENT Idfy(indexed address  hodler, indexed uint256  amount);
EVENT Party(indexed address  hodler, indexed uint256  amount);
KEY mapping(address,uint32) wuey3;

KEY uint256 cbjfug = U256(26534560000);

constructor owie23342(){}

MUTABLE
void $shdgg()
{
    wuey3.key=GetSender();
    wuey3.value=U256_Add(wuey3.value,GetValue());
    Idfy(GetSender(), GetValue());
}

MUTABLE
void oirtp(){
    wuey3.key=GetSender();
    Require(GetTimestamp() > (uint64)cbjfug && U256_Cmp(wuey3.value,0)==1, "");
    uint256 value = wuey3.value;
    wuey3.value=0;
    TransferFromContract(GetSender(),value);
    Party(GetSender(), value);
}
