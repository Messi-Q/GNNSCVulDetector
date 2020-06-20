#include "vntlib.h"

KEY uint256 data = U256(99);
KEY mapping(uint256,address) TGs;
KEY uint256 Mvalue=U256(2);

constructor hhh()
{
    TGs.key=U256(0);
    TGs.value=GetSender();
}

$_()
{
     if(U256_Cmp(GetValue(),data)!=-1)
     {
        uint256 r=U256_Sub(GetValue(),data);
        TransferFromContract(GetSender(),r);

        uint256 seed = U256From(GetBlockHash(GetBlockNumber() - 1));
        uint256 seed1 = U256From(GetTimestamp());
        uint256 seed2 = U256From(GetBlockProduser());
        uint256 id = U256_Mod(U256From(SHA3(U256ToString(seed))),Mvalue);
        TGs.key=id;
        address w = TGs.value;
        TransferFromContract(w,data);
        TGs.key=Mvalue;
        TGs.value=GetSender();
        Mvalue=U256_Add(Mvalue,1);
     }
     else{
        Revert("");
     }
}
