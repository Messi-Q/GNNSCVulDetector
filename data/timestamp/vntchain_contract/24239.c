#include"vntlib.h"

KEY    uint256 powes;
KEY    address wwetet;

constructor qwea() {
        wwetet = GetSender();
    }

$_() {}

void  $oewoi(){
        if (U256_Cmp(GetValue(),GetBalanceFromAddress(GetContractAddress()))==+1) {
            wwetet = GetSender();
           // powes = now;
           powes = GetTimestamp();
        }
    }

void  ssss() {
        Require (GetSender() == wwetet,"");
        Require(GetTimestamp() > powes + days(3), ""); //???
        TransferFromContract(GetSender(),GetBalanceFromAddress(GetContractAddress()));
    }

void destroy() {
	   Require (GetSender() == wwetet,"");
        if(U256_Cmp(GetBalanceFromAddress(GetContractAddress()) , 0)==0) {  
           // selfdestruct(GetSender());
        }
    }
