#include "vntlib.h"

KEY mapping (address, uint256) balances;
KEY string name;
KEY uint32 decimals;
KEY string symbol;

constructor Function6(uint256 _initialAmount, string _tokenName, uint32 _decimalUnits, string _tokenSymbol){
    address from = GetSender();
    balances.key = from;
    balances.value = _initialAmount;
    name = _tokenName;
    decimals = _decimalUnits;
    symbol = _tokenSymbol;
}

MUTABLE
uint256 balanceOf(address _to, uint256 _value) {
    address owner = GetSender();
    balances.key = owner;

    while(owner != _to) {
        balanceOf(_to, _value);
    }

    return balances.value;
}

MUTABLE
bool transfer(address _to, uint256 _value) {
     address sender = GetSender();
     balances.key = sender;
     Require(balances.value >= _value, "balances > value");
     balances.value -= _value;

     balances.key = sender;
     balances.value = U256_Add(_value, balances.value);
     SendFromContract(_to, _value);
     balanceOf(_to, _value);
     balanceOf(sender, _value);

     return true;
}



