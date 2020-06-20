#include "vntlib.h"

KEY address engineer;
KEY address manager;
KEY uint256 createdTime;
KEY uint256 updatedTime;

constructor a40666(){}

MUTABLE
void ConsultingHalf(address _engineer, address _manager)
{
    engineer = _engineer;
    manager = _manager;
    createdTime = (uint256)GetTimestamp();
    updatedTime = (uint256)GetTimestamp();
}

MUTABLE
bool payout()
{
    if(GetSender() == engineer || GetSender() == manager) {
        SendFromContract(engineer,U256_Div(GetBalanceFromAddress(GetContractAddress()),2));
        SendFromContract(manager,U256_Div(GetBalanceFromAddress(GetContractAddress()),2));
        updatedTime = (uint256)GetTimestamp();
        bool _success = true;
    }else{
        bool _success = false;
    }
}
