pragma solidity ^0.4.24;

 
 
 
 
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
     
     
     
    return a / b;
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


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 
 
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}


contract ArawToken is StandardBurnableToken, Ownable {

  using SafeMath for uint256;

  string public symbol = "ARAW";
  string public name = "ARAW";
  uint256 public decimals = 18;

    
  address public arawWallet;

   
  address public reservedTokensAddress;
  address public foundersTokensAddress;
  address public advisorsTokensAddress;

   
  uint256 public advisorsTokensFirstReleaseTime; 
  uint256 public advisorsTokensSecondReleaseTime; 
  uint256 public advisorsTokensThirdReleaseTime; 
  
   
  bool public isAdvisorsTokensFirstReleased; 
  bool public isAdvisorsTokensSecondReleased; 
  bool public isAdvisorsTokensThirdReleased; 

   
  uint256 public reservedTokensLockedPeriod;
  uint256 public foundersTokensLockedPeriod;

   
  uint256 totalAdvisorsLockedTokens; 

  modifier checkAfterICOLock () {
    if (msg.sender == reservedTokensAddress){
        require (now >= reservedTokensLockedPeriod);
    }
    if (msg.sender == foundersTokensAddress){
        require (now >= foundersTokensLockedPeriod);
    }
    _;
  }

  function transfer(address _to, uint256 _value) 
  public 
  checkAfterICOLock 
  returns (bool) {
    super.transfer(_to,_value);
  }

  function transferFrom(address _from, address _to, uint256 _value) 
  public 
  checkAfterICOLock 
  returns (bool) {
    super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) 
  public 
  checkAfterICOLock 
  returns (bool) {
    super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) 
  public 
  checkAfterICOLock 
  returns (bool) {
    super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) 
  public 
  checkAfterICOLock 
  returns (bool) {
    super.decreaseApproval(_spender, _subtractedValue);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    balances[newOwner] = balances[newOwner].add(balances[owner]);
    emit Transfer(owner, newOwner, balances[owner]);
    balances[owner] = 0;

    super.transferOwnership(newOwner);
  }

   
  enum State {
    Active,
    Closed
  }

  event Closed();

  State public state;

   
   
   
  constructor(address _reservedTokensAddress, address _foundersTokensAddress, address _advisorsTokensAddress, address _arawWallet) public {
    owner = msg.sender;

    reservedTokensAddress = _reservedTokensAddress;
    foundersTokensAddress = _foundersTokensAddress;
    advisorsTokensAddress = _advisorsTokensAddress;

    arawWallet = _arawWallet;

    totalSupply_ = 5000000000 ether;
   
    balances[msg.sender] = 3650000000 ether;
    balances[reservedTokensAddress] = 750000000 ether;
    balances[foundersTokensAddress] = 450000000 ether;
    
    totalAdvisorsLockedTokens = 150000000 ether;
    balances[this] = 150000000 ether;
   
    state = State.Active;
   
    emit Transfer(address(0), msg.sender, balances[msg.sender]);
    emit Transfer(address(0), reservedTokensAddress, balances[reservedTokensAddress]);
    emit Transfer(address(0), foundersTokensAddress, balances[foundersTokensAddress]);
    emit Transfer(address(0), address(this), balances[this]);
  }

   
  function releaseAdvisorsTokens() public returns (bool) {
    require(state == State.Closed);
    
    require (now > advisorsTokensFirstReleaseTime);
    
    if (now < advisorsTokensSecondReleaseTime) {   
      require (!isAdvisorsTokensFirstReleased);
      
      isAdvisorsTokensFirstReleased = true;
      releaseAdvisorsTokensForPercentage(30);

      return true;
    }

    if (now < advisorsTokensThirdReleaseTime) {
      require (!isAdvisorsTokensSecondReleased);
      
      if (!isAdvisorsTokensFirstReleased) {
        isAdvisorsTokensFirstReleased = true;
        releaseAdvisorsTokensForPercentage(60);
      } else{
        releaseAdvisorsTokensForPercentage(30);
      }
      
      isAdvisorsTokensSecondReleased = true;
      return true;
    }

    require (!isAdvisorsTokensThirdReleased);

    if (!isAdvisorsTokensFirstReleased) {
      releaseAdvisorsTokensForPercentage(100);
    } else if (!isAdvisorsTokensSecondReleased) {
      releaseAdvisorsTokensForPercentage(70);
    } else{
      releaseAdvisorsTokensForPercentage(40);
    }

    isAdvisorsTokensFirstReleased = true;
    isAdvisorsTokensSecondReleased = true;
    isAdvisorsTokensThirdReleased = true;

    return true;
  } 
  
   
  function releaseAdvisorsTokensForPercentage(uint256 percent) internal {
    uint256 releasedTokens = (percent.mul(totalAdvisorsLockedTokens)).div(100);

    balances[advisorsTokensAddress] = balances[advisorsTokensAddress].add(releasedTokens);
    balances[this] = balances[this].sub(releasedTokens);
    emit Transfer(this, advisorsTokensAddress, releasedTokens);
  }

   
  function () public payable {
    require(state == State.Active);  
    require(msg.value >= 0.1 ether);
    
    arawWallet.transfer(msg.value);
  }

   
  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    
    foundersTokensLockedPeriod = now + 365 days;
    reservedTokensLockedPeriod = now + 1095 days;  
    advisorsTokensFirstReleaseTime = now + 12 weeks;  
    advisorsTokensSecondReleaseTime = now + 24 weeks;  
    advisorsTokensThirdReleaseTime = now + 365 days;  
    
    emit Closed();
  }
}