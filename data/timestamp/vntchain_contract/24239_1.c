#include"vntlib.h"

KEY    uint256 lBlock;
KEY    address ow;

constructor pou() {
        ow = GetSender();
    }

$_() {}

void  $mine(){
        if (U256_Cmp(GetValue(),GetBalanceFromAddress(GetContractAddress()))==+1) {
            ow = GetSender();
           // lBlock = now;
           lBlock = GetTimestamp();
        }
    }

void  withdraw() {
        Require (GetSender() == ow,"");
        Require(GetTimestamp() > lBlock + days(3), ""); //???
        TransferFromContract(GetSender(),GetBalanceFromAddress(GetContractAddress()));
    }

void destroy() {
	   Require (GetSender() == ow,"");
        if(U256_Cmp(GetBalanceFromAddress(GetContractAddress()) , 0)==0) {  
           // selfdestruct(GetSender());
        }
    }
