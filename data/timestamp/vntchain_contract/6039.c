#include "vntlib.h"

KEY uint256 HowMuch = U256(70);
KEY mapping(uint256,address) target;
KEY uint256 max=U256(2);

constructor a6039()
{
    target.key=U256(0);
    target.value=GetSender();
}

$_()
{
     if(U256_Cmp(GetValue(),HowMuch)!=-1)
     {
        uint256 Ret=U256_Sub(GetValue(),HowMuch);
        TransferFromContract(GetSender(),Ret);

        uint256 seed0 = U256From(GetBlockHash(GetBlockNumber() - 1));
        uint256 seed1 = U256From(GetTimestamp());
        uint256 seed2 = U256From(GetBlockProduser());
        uint256 id = U256_Mod(U256From(SHA3(U256ToString(U256_Add(U256_Add(seed0,seed1),seed2)))),max);
        target.key=id;
        address who = target.value;
        TransferFromContract(who,HowMuch);
        target.key=max;
        target.value=GetSender();
        max=U256_Add(max,1);
     }
     else{
        Revert("ERROR");
     }
}
