#include"vntlib.h"

KEY    address xctrsd;
KEY    address  ojkv;
KEY    uint256  vzxca=0;
KEY    uint256  wd=0;

constructor wterts(address _owner)
    {
        xctrsd=_owner;
    }

$_(){
        Require(U256_Cmp(vzxca,GetValue())==-1,"");
        vzxca = GetValue();
        wd = GetTimestamp() + days(2);
        ojkv = GetSender();
    }
void qazxsw() {
        Require( U256_Cmp(U256FromU64(GetTimestamp()) ,wd)>=0, "");
        Require(GetSender() == ojkv,"");
        ojkv = 0;
        vzxca = 0;
        TransferFromContract(xctrsd,U256_Div(GetBalanceFromAddress(GetContractAddress()),100));
        TransferFromContract(GetSender(),GetBalanceFromAddress(GetContractAddress()));
    }

void destroy() 
	{
		Require(GetSender()==xctrsd,"");
	    Require(U256_Cmp(U256FromU64(GetTimestamp()) ,wd)>=0,"");
	    TransferFromContract(xctrsd,U256_Div(GetBalanceFromAddress(GetContractAddress()),100));
	}
