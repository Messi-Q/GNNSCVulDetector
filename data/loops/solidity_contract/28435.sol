library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

contract XIEXIEToken is StandardToken {
  string public name = "PleaseChinaResumeICOWeLoveYouXieXie";
  uint8 public decimals = 18;
  string public symbol = "XIEXIE";
  string public version = "0.1";
  address public wallet = 0xCDAe88d491030257265CD42226cF56b085aC58cf;
  address public tokensBank = 0x075768D0fB81282e1a62B1f05BAf5279Dc7B5dbe;
  uint256 public circulatingTokens = 0;
  uint256 constant public STARTBLOCKTM = 1506538800;  

  function XIEXIEToken() {
    totalSupply = 4200000000000000000000000;
    balances[tokensBank] = totalSupply;
  }

  function dynasty() returns (uint256) {
    if (circulatingTokens <= 37799999999999997902848) return 1644;
    if (circulatingTokens <= 462000000000000054525952) return 1368;
    return 1271;
  }

  function () payable {                                      
    require(msg.sender != 0x0);                              
    require(msg.value != 0);                                 
    require(msg.sender != tokensBank);                       
    require(msg.sender != wallet);                           
    require(msg.value >= 10000000000000000);  
    require(block.timestamp >= STARTBLOCKTM);                
    uint256 tokens = msg.value.mul(dynasty());               
    wallet.transfer(msg.value);                              
    require(circulatingTokens.add(tokens) <= totalSupply);   
    circulatingTokens = circulatingTokens.add(tokens);       
    require(allowed[tokensBank][msg.sender] == 0);           
    allowed[tokensBank][msg.sender] = tokens;                
    transferFrom(tokensBank, msg.sender, tokens);            
  }                                                          
}