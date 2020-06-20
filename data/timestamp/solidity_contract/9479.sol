pragma solidity ^0.4.21;


 
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

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract GeneNuggetsToken is Pausable,StandardToken {
  using SafeMath for uint256;
  
  string public name = "Gene Nuggets";
  string public symbol = "GNUS";
   
   
  uint8 public decimals = 6;
  uint256 public decimalFactor = 10 ** uint256(decimals);
  uint public CAP = 30e8 * decimalFactor;  
  
   
  uint256 public circulatingSupply;
  uint256 public totalUsers;
  uint256 public exchangeLimit = 10000*decimalFactor;
  uint256 public exchangeThreshold = 2000*decimalFactor;
  uint256 public exchangeInterval = 60;
  uint256 public destroyThreshold = 100*decimalFactor;
 
   
  address public CFO;  
  mapping(address => uint256) public CustomerService;  
  
   
  uint[10] public MINING_LAYERS = [0,10e4,30e4,100e4,300e4,600e4,1000e4,2000e4,3000e4,2**256 - 1];
  uint[9] public MINING_REWARDS = [1000*decimalFactor,600*decimalFactor,300*decimalFactor,200*decimalFactor,180*decimalFactor,160*decimalFactor,60*decimalFactor,39*decimalFactor,0];
  
   
  event UpdateTotal(uint totalUser,uint totalSupply);
  event Exchange(address indexed user,uint256 amount);
  event Destory(address indexed user,uint256 amount);

  modifier onlyCFO() {
    require(msg.sender == CFO);
    _;
  }


  modifier onlyCustomerService() {
    require(CustomerService[msg.sender] != 0);
    _;
  }

     
  function GeneNuggetsToken() public {}

      
  function() public {
    revert();
  }
  
   
  function setName(string newName) external onlyOwner {
    name = newName;
  }
  
   
  function setSymbol(string newSymbol) external onlyOwner {
    symbol = newSymbol;
  }
  
   
  function setCFO(address newCFO) external onlyOwner {
    CFO = newCFO;
  }
  
   
  function setExchangeInterval(uint newInterval) external onlyCFO {
    exchangeInterval = newInterval;
  }

   
  function setExchangeLimit(uint newLimit) external onlyCFO {
    exchangeLimit = newLimit;
  }

   
  function setExchangeThreshold(uint newThreshold) external onlyCFO {
    exchangeThreshold = newThreshold;
  }
  
   
  function setDestroyThreshold(uint newThreshold) external onlyCFO {
    destroyThreshold = newThreshold;
  }
  
   
  function addCustomerService(address cs) onlyCFO external {
    CustomerService[cs] = block.timestamp;
  }
  
   
  function removeCustomerService(address cs) onlyCFO external {
    CustomerService[cs] = 0;
  }

   
  function updateTotal(uint256 _userAmount) onlyCFO external {
    require(_userAmount>totalUsers);
    uint newTotalSupply = calTotalSupply(_userAmount);
    require(newTotalSupply<=CAP && newTotalSupply>totalSupply_);
    
    uint _amount = newTotalSupply.sub(totalSupply_);
    totalSupply_ = newTotalSupply;
    totalUsers = _userAmount;
    emit UpdateTotal(_amount,totalSupply_); 
  }

     
  function calTotalSupply(uint _userAmount) private view returns (uint ret) {
    uint tokenAmount = 0;
	  for (uint8 i = 0; i < MINING_LAYERS.length ; i++ ) {
	    if(_userAmount < MINING_LAYERS[i+1]) {
	      tokenAmount = tokenAmount.add(MINING_REWARDS[i].mul(_userAmount.sub(MINING_LAYERS[i])));
	      break;
	    }else {
        tokenAmount = tokenAmount.add(MINING_REWARDS[i].mul(MINING_LAYERS[i+1].sub(MINING_LAYERS[i])));
	    }
	  }
	  return tokenAmount;
  }

   
  function exchange(address user,uint256 _amount) whenNotPaused onlyCustomerService external {
  	
  	require((block.timestamp-CustomerService[msg.sender])>exchangeInterval);

  	require(_amount <= exchangeLimit && _amount >= exchangeThreshold);

    circulatingSupply = circulatingSupply.add(_amount);
    
    balances[user] = balances[user].add(_amount);
    
    CustomerService[msg.sender] = block.timestamp;
    
    emit Exchange(user,_amount);
    
    emit Transfer(address(0),user,_amount);
    
  }
  

   
  function destory(uint256 _amount) external {  
    require(balances[msg.sender]>=_amount && _amount>destroyThreshold && circulatingSupply>=_amount);

    circulatingSupply = circulatingSupply.sub(_amount);
    
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    
    emit Destory(msg.sender,_amount);
    
    emit Transfer(msg.sender,0x0,_amount);
    
  }

  function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner external {
     
    token.transfer( owner, amount );
  }
  
}