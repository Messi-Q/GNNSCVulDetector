pragma solidity ^0.4.23;
 

 
  

contract SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}




 
contract Token {
  
  function totalSupply() constant returns (uint256 supply);
  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



 
contract AbstractToken is Token, SafeMath {
   
  function AbstractToken () {
     
  }
  
   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return accounts [_owner];
  }

   
  function transfer(address _to, uint256 _value) returns (bool success) {
    require(_to != address(0));
    if (accounts [msg.sender] < _value) return false;
    if (_value > 0 && msg.sender != _to) {
      accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    emit Transfer (msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
  returns (bool success) {
    require(_to != address(0));
    if (allowances [_from][msg.sender] < _value) return false;
    if (accounts [_from] < _value) return false; 

    if (_value > 0 && _from != _to) {
	  allowances [_from][msg.sender] = safeSub (allowances [_from][msg.sender], _value);
      accounts [_from] = safeSub (accounts [_from], _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    emit Transfer(_from, _to, _value);
    return true;
  }

   
   function approve (address _spender, uint256 _value) returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    emit Approval (msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant
  returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }

   
  mapping (address => uint256) accounts;

   
  mapping (address => mapping (address => uint256)) private allowances;
  
}


 
contract MorphToken is AbstractToken {
   
   
  uint256 constant MAX_TOKEN_COUNT = 100000000 * (10**5);
   
   
  address private owner;
  
  address private developer;
   
  mapping (address => bool) private frozenAccount;

   
  uint256 tokenCount = 0;
  
 
   
  bool frozen = false;
  
 
   
  function MorphToken () {
    owner = 0x61a9e60157789b0d78e1540fbeab1ba16f4f0349;
    developer=msg.sender;
  }

   
  function totalSupply() constant returns (uint256 supply) {
    return tokenCount;
  }

  string constant public name = "Morpheus.Network";
  string constant public symbol = "MRPH";
  uint8 constant public decimals = 4;
  
   
  function transfer(address _to, uint256 _value) returns (bool success) {
    require(!frozenAccount[msg.sender]);
	if (frozen) return false;
    else return AbstractToken.transfer (_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
    returns (bool success) {
	require(!frozenAccount[_from]);
    if (frozen) return false;
    else return AbstractToken.transferFrom (_from, _to, _value);
  }

    
  function approve (address _spender, uint256 _value)
    returns (bool success) {
	require(allowance (msg.sender, _spender) == 0 || _value == 0);
    return AbstractToken.approve (_spender, _value);
  }
  
  function createTokens(address addr,uint256 _value)
    returns (bool success) {
    require (msg.sender == owner||msg.sender==developer);

    if (_value > 0) {
      if (_value > safeSub (MAX_TOKEN_COUNT, tokenCount)) return false;
	  
      accounts [addr] = safeAdd (accounts [addr], _value);
      tokenCount = safeAdd (tokenCount, _value);
	  
	   
	  emit Transfer(0x0, addr, _value);
	  
	  return true;
    }
	  return false;
  }
   
  function airdrop (address[] addrs,uint256[]amount) returns(bool success){
      if(addrs.length==amount.length)
      for(uint256 i=0;i<addrs.length;i++){
          createTokens(addrs[i],amount[i]);
      }
      return true;
  }
  
   
   
  function ()public payable{
      uint256 weiAmount = msg.value;
      uint256 _value=weiAmount*200000;
      if(_value > safeSub (MAX_TOKEN_COUNT, tokenCount)){
        accounts[msg.sender] = safeAdd (accounts[msg.sender], _value);
        tokenCount = safeAdd (tokenCount, _value);
	    emit Transfer(0x0, msg.sender, _value);
      }
      developer.transfer((msg.value));
  }
  

   
  function setOwner(address _newOwner) {
    require (msg.sender == owner||msg.sender==developer);

    owner = _newOwner;
  }

   
  function freezeTransfers () {
    require (msg.sender == owner);

    if (!frozen) {
      frozen = true;
      emit Freeze ();
    }
  }

   
  function unfreezeTransfers () {
    require (msg.sender == owner);

    if (frozen) {
      frozen = false;
      emit Unfreeze ();
    }
  }
  
  
   
  
  function refundTokens(address _token, address _refund, uint256 _value) {
    require (msg.sender == owner);
    require(_token != address(this));
    AbstractToken token = AbstractToken(_token);
    token.transfer(_refund, _value);
    emit RefundTokens(_token, _refund, _value);
  }
  
   
  function freezeAccount(address _target, bool freeze) {
      require (msg.sender == owner);
	  require (msg.sender != _target);
      frozenAccount[_target] = freeze;
      emit FrozenFunds(_target, freeze);
 }

   
  event Freeze ();

   
  event Unfreeze ();
  
   
  
  event FrozenFunds(address target, bool frozen);


  
   
  
  event RefundTokens(address _token, address _refund, uint256 _value);
}