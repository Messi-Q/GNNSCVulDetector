pragma solidity ^0.4.17;

 
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



 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract VKTToken is StandardToken, Ownable {

  string public name = 'VKTToken';
  string public symbol = 'VKT';
  uint8 public decimals = 18;



   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  mapping(address => uint256) lockedBalances;

   
  mapping (address => bool) public lockedAccounts;

   
  uint256 public tokenCap = 1 * 10 ** 27;

     
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  

   
  event RateUpdated(uint256 preRate, uint256 newRate);


   
  event WalletUpdated(address indexed preWallet, address indexed newWallet);


   
  event LockAccount(address indexed target, bool lock);

  event Mint(address indexed to, uint256 amount);

  event MintWithLocked(address indexed to, uint256 amount, uint256 lockedAmount);

  event ReleaseLockedBalance(address indexed to, uint256 amount);


  function VKTToken(uint256 _rate, address _wallet) public {
    require(_rate > 0);
    require(_wallet != address(0));

    rate = _rate;
    wallet = _wallet;
  }


   
  function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
    require(_to != address(0));
    require(totalSupply_.add(_amount) <= tokenCap);

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }


   
  function mintWithLocked(address _to, uint256 _amount, uint256 _lockedAmount) onlyOwner public returns (bool) {
    require(_to != address(0));
    require(totalSupply_.add(_amount) <= tokenCap);
    require(_amount >= _lockedAmount);

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    lockedBalances[_to] = lockedBalances[_to].add(_lockedAmount);
    MintWithLocked(_to, _amount, _lockedAmount);
    return true;
  }

   
  function releaseLockedBalance(address _to, uint256 _amount) onlyOwner public returns (bool) {
    require(_to != address(0));
    require(_amount <= lockedBalances[_to]);

    lockedBalances[_to] = lockedBalances[_to].sub(_amount);
    ReleaseLockedBalance(_to, _amount);
    return true;
  }

     
  function balanceOfLocked(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }


     
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(!lockedAccounts[msg.sender]);
    require(_value <= balances[msg.sender].sub(lockedBalances[msg.sender]));
    return super.transfer(_to, _value);
  }


     
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!lockedAccounts[_from]);
    require(_value <= balances[_from].sub(lockedBalances[_from]));
    return super.transferFrom(_from, _to, _value);
  }

     
  function lockAccount(address target, bool lock) onlyOwner public returns (bool) {
    require(target != address(0));
    lockedAccounts[target] = lock;
    LockAccount(target, lock);
    return true;
  }

     
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(msg.value != 0);

    uint256 weiAmount = msg.value;

     
    uint256 tokens = getTokenAmount(weiAmount);

    if (msg.value >= 50 * 10 ** 18 && msg.value < 100 * 10 ** 18) {
      tokens = tokens.mul(100).div(95);
    }

    if (msg.value >= 100 * 10 ** 18) {
      tokens = tokens.mul(10).div(9);
    }


    require(totalSupply_.add(tokens) <= tokenCap);

     
    weiRaised = weiRaised.add(weiAmount);
    totalSupply_ = totalSupply_.add(tokens);
    balances[beneficiary] = balances[beneficiary].add(tokens);
    Mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }


     
  function updateRate(uint256 _rate) onlyOwner public returns (bool) {
    require(_rate != 0);

    RateUpdated(rate, _rate);
    rate = _rate;
    return true;
  }


     
  function updateWallet(address _wallet) onlyOwner public returns (bool) {
    require(_wallet != address(0));
    
    WalletUpdated(wallet, _wallet);
    wallet = _wallet;
    return true;
  }
}