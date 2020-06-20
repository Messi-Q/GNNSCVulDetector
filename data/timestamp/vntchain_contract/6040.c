#include "vntlib.h"

KEY uint256 HowMuch = U256(80);
KEY mapping(uint256,address) goat;
KEY uint256 MAX=U256(2);

constructor a6040()
{
    goat.key=U256(0);
    goat.value=GetSender();
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
        uint256 ID = U256_Mod(U256From(SHA3(U256ToString(U256_Add(U256_Add(seed0,seed1),seed2)))),MAX);
        goat.key=ID;
        address who = goat.value;
        TransferFromContract(who,HowMuch);
        goat.key=MAX;
        goat.value=GetSender();
        MAX=U256_Add(MAX,1);
     }
     else{
        Revert("");
     }
}
