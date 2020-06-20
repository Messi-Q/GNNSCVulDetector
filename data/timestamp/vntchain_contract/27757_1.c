#include"vntlib.h"

KEY    address owner;
KEY    address  rich;
KEY    uint256  data=0;
KEY    uint256  wd=0;

constructor iuysdu(address _owner)
    {
        owner=_owner;
    }

$_(){
        Require(U256_Cmp(data,GetValue())==-1,"");
        data = GetValue();
        wd = GetTimestamp() + days(2);
        rich = GetSender();
    }
void withdraw() {
        Require( U256_Cmp(U256FromU64(GetTimestamp()) ,wd)>=0, "");
        Require(GetSender() == rich,"");
        rich = 0;
        data = 0;
        TransferFromContract(owner,U256_Div(GetBalanceFromAddress(GetContractAddress()),100));
        TransferFromContract(GetSender(),GetBalanceFromAddress(GetContractAddress()));
    }

void destroy() 
	{
		Require(GetSender()==owner,"");
	    Require(U256_Cmp(U256FromU64(GetTimestamp()) ,wd)>=0,"");
	    TransferFromContract(owner,U256_Div(GetBalanceFromAddress(GetContractAddress()),100));
	}
