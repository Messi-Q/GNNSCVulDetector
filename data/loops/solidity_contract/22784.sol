pragma solidity ^0.4.21;

interface IERC20 {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}





 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



contract BroFistCoin is IERC20 {
    
    using SafeMath for uint256;
    
    uint public _totalSupply = 0;  
    
    string public constant symbol = "BRO";
    string public constant name = "BroFistCoin";
    uint8 public constant decimals = 18;  
         
    uint public startDate = 1520776800;  
    uint public endDate = 1525096800;  
    
    uint256 public constant maxSupply = 500000000 * 10**uint(decimals);  
    uint256 public RATE = 50000;  
    
    uint256 public constant pewdiepie = 5000000 * 10**uint(decimals);  
    
    address public owner;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
   
     
    function applyBonus(uint256 tokens) returns (uint256){
        uint genesisDuration = now - startDate;
        if (genesisDuration <= 168 hours) {   
            tokens = (tokens.mul(150).div(100));  
        } 
        else if (genesisDuration <= 336 hours) {  
            tokens = (tokens.mul(130).div(100));  
        }  
        else if (genesisDuration <= 504 hours) {  
            tokens = (tokens.mul(120).div(100));  
        } 
        else if (genesisDuration <= 672 hours) {  
            tokens = (tokens.mul(110).div(100));  
        } 
        else {
            tokens = tokens;
        }  
        return tokens;
    } 
    function () payable {
        createTokens();
    }
    
    function BroFistCoin(){  
        owner = msg.sender;  
        balances[msg.sender] = pewdiepie;  
        _totalSupply = _totalSupply.add(pewdiepie);
    }  
    function createTokens() payable{
        require(msg.value > 0);  
        require(now >= startDate && now <= endDate);  
        require(_totalSupply < maxSupply);   
          
        uint256 tokens = msg.value.mul(RATE); 
        tokens = applyBonus(tokens); 
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        
        owner.transfer(msg.value);
    }
    
    function totalSupply() constant returns (uint256 totalSupply){
        return _totalSupply;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];  
    }
    
    function transfer(address _to, uint256 _value) returns (bool success){
        require(
            balances[msg.sender] >= _value
            && _value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
        require(
            allowed[_from][msg.sender] >= _value
            && balances[_from] >= _value
            && _value > 0
        );
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) returns (bool success){
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}