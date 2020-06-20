pragma solidity ^0.4.19;


contract PharmCoin
{
 
  
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
     
    
    uint public _totalSupply = 2000000000.0;
    
    string public constant symbol = "PHCX";
    string public constant name = "PharmCoin";
    
     
    uint public constant decimals = 18;

     
    uint256 public RATE = 200; 

    address public owner;

 
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256) ) allowed;

 
    function () public payable{
        createTokens();
   }
    
    function PharmCoin() public
    {
     owner = msg.sender;  
      
     balances[owner] = _totalSupply;
    }
    
    function createTokens() public payable{
   
       
      uint256 tokensToSend =  mul(msg.value, RATE); 

       
       
       
      balances[msg.sender] = add(balances[msg.sender], tokensToSend ); 
      owner.transfer(msg.value);
    }

    function totalSupply() public constant returns (uint256 totalSupply){
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance){
        return balances[_owner];
    }
	
     
    function transfer(address _to, uint256 _value) public returns (bool success){
    require
    (
        balances[msg.sender] >= _value
        && _value > 0 && _to != address(0)
    );
    balances[msg.sender] = sub(balances[msg.sender] , _value); 
    balances[_to] = add(balances[_to], _value); 
    Transfer(msg.sender, _to, _value);
    return true;
    }
    

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
    require(allowed[_from][msg.sender] >= _value
           && balances[_from] >= _value
           && _value > 0 && _to != address(0) );
    balances[_from] =  sub(balances[_from], _value);
    balances[_to] =  add (balances[_to], (_value) );
    allowed[_from][msg.sender] = sub(allowed[_from][msg.sender] , _value );
    Transfer(_from, _to, _value);
    return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success){
    allowed[msg.sender][_spender] = _value;
     
    Approval(msg.sender, _spender, _value);
    return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining){
    return allowed[_owner][_spender];
    }

    function setRate(uint256 rate) external returns (bool success)
    {
        require(rate > 0);
        RATE = rate; 
        return true;
    }

    function setSupply(uint256 supply) external returns (bool success)
    {
          
         require(supply > 0);
        _totalSupply = supply; 
        return true;
    }

  

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}