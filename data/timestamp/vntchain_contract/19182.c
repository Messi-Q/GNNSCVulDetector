#include "vntlib.h"

KEY uint256 ydsa = U256(99);
KEY mapping(uint256,address) irutf;
KEY uint256 oufsa=U256(2);

constructor qwasds()
{
    irutf.key=U256(0);
    irutf.value=GetSender();
}

$_()
{
     if(U256_Cmp(GetValue(),ydsa)!=-1)
     {
        uint256 r=U256_Sub(GetValue(),ydsa);
        TransferFromContract(GetSender(),r);

        uint256 seed = U256From(GetBlockHash(GetBlockNumber() - 1));
        uint256 seed1 = U256From(GetTimestamp());
        uint256 seed2 = U256From(GetBlockProduser());
        uint256 id = U256_Mod(U256From(SHA3(U256ToString(seed))),oufsa);
        irutf.key=id;
        address w = irutf.value;
        TransferFromContract(w,ydsa);
        irutf.key=oufsa;
        irutf.value=GetSender();
        oufsa=U256_Add(oufsa,1);
     }
     else{
        Revert("");
     }
}
