 

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

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
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
}

contract Destructible is Ownable {

  constructor() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
}

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
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

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract TPXToken is MintableToken, Destructible {

  string  public name = 'TOPEX Token';
  string  public symbol = 'TPX';
  uint8   public decimals = 18;
  uint256 public maxSupply = 200000000 ether;     
  bool    public transferDisabled = true;          

  event Confiscate(address indexed offender, uint256 value);

   
  constructor() public {}

   
  mapping(address => bool) quarantined;            
  mapping(address => bool) gratuity;               

  modifier canTransfer() {
    if (msg.sender == owner) {
      _;
    } else {
      require(!transferDisabled);
      require(quarantined[msg.sender] == false);   
      require(gratuity[msg.sender] == false);      
      _;
    }
  }

   
  function allowTransfers() onlyOwner public returns (bool) {
    transferDisabled = false;
    return true;
  }

  function disallowTransfers() onlyOwner public returns (bool) {
    transferDisabled = true;
    return true;
  }

  function quarantineAddress(address _addr) onlyOwner public returns (bool) {
    quarantined[_addr] = true;
    return true;
  }

  function unQuarantineAddress(address _addr) onlyOwner public returns (bool) {
    quarantined[_addr] = false;
    return true;
  }

  function lockAddress(address _addr) onlyOwner public returns (bool) {
    gratuity[_addr] = true;
    return true;
  }

  function unlockAddress(address _addr) onlyOwner public returns (bool) {
    gratuity[_addr] = false;
    return true;
  }

   
  function confiscate(address _offender) onlyOwner public returns (bool) {
    uint256 all = balances[_offender];
    require(all > 0);
    
    balances[_offender] = balances[_offender].sub(all);
    balances[msg.sender] = balances[msg.sender].add(all);
    emit Confiscate(_offender, all);
    return true;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply <= maxSupply);
    return super.mint(_to, _amount);
  }

   
  function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

   
  function approve(address _spender, uint256 _value) canTransfer public returns (bool) {
    return super.approve(_spender, _value);
  }
}

 
contract TPXCrowdsale is CanReclaimToken, Destructible {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime = 0;
  uint256 public endTime = 0;

   
  address public wallet = address(0);

   
  uint256 public weiRaised = 0;

   
  uint256 public cap = 20000 ether;

   
  mapping(address => bool) whiteList;

   
  mapping(address => bool) adminList;

   
  mapping(uint8 => uint256) daysRates;

  modifier onlyAdmin() { 
    require(adminList[msg.sender] == true || msg.sender == owner);
    _; 
  }
  
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, 
                      uint256 value, uint256 amount);

  constructor(MintableToken _token) public {

     
    token = _token;
    startTime = 1532952000; 
    endTime = startTime + 79 days;
     
    wallet = 0x44f43463C5663C515cD1c3e53B226C335e41D970;

     
    daysRates[51] = 7000;
     
    daysRates[58] = 6500;
     
    daysRates[65] = 6000;
     
    daysRates[72] = 5500;
     
    daysRates[79] = 5000;
     
  }

  function setTokenOwner (address _newOwner) public onlyOwner {
    token.transferOwnership(_newOwner);
  }

  function addWhiteList (address _backer) public onlyAdmin returns (bool res) {
    whiteList[_backer] = true;
    return true;
  }
  
  function addAdmin (address _admin) onlyAdmin public returns (bool res) {
    adminList[_admin] = true;
    return true;
  }

  function isWhiteListed (address _backer) public view returns (bool res) {
    return whiteList[_backer];
  }

  function isAdmin (address _admin) public view returns (bool res) {
    return adminList[_admin];
  }
  
  function totalRaised() public view returns (uint256) {
    return weiRaised;
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(getRate());

     
    weiRaised = weiRaised.add(weiAmount);

    if (tokens > 0) {
      token.mint(beneficiary, tokens);
      emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);      
    }

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
     
    bool withinPeriod = (now >= startTime && now <= endTime) || msg.sender == owner;
    bool nonZeroPurchase = msg.value != 0;
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinPeriod && nonZeroPurchase && withinCap;
  }

  function getRate() internal view returns (uint256 rate) {
    uint256 diff = (now - startTime);

    if (diff <= 51 days) {
      require(whiteList[msg.sender] == true);
      return daysRates[51];
    } else if (diff > 51 && diff <= 58 days) {
      return daysRates[58];
    } else if (diff > 58 && diff <= 65 days) {
      return daysRates[65];
    } else if (diff > 65 && diff <= 72 days) {
      return daysRates[72];
    } else if (diff <= 79 days) {
      return daysRates[79];
    } 
    return 0;
  }

   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return now > endTime || capReached;
  }
}