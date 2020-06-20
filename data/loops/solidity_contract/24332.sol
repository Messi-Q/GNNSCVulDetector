 
 
 pragma solidity ^0.4.18;

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
    Transfer(msg.sender, _to, _value);
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

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract SovToken is MintableToken {
  string public name = "Sovereign";
  string public symbol = "SVT";
  uint256 public decimals = 18;

  uint256 private _tradeableDate = now;
  
   
  address private constant CONVERT_ADDRESS = 0x9376B2Ff3E68Be533bAD507D99aaDAe7180A8175; 
  address private constant POOL = 0xE06be458ad8E80d8b8f198579E0Aa0Ce5f571294;
  
  event Burn(address indexed burner, uint256 value);

  function SovToken(uint256 tradeDate) public
  {
    _tradeableDate = tradeDate;
  }

  function transfer(address _to, uint256 _value) public returns (bool) 
  {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
     
     
    require(now > _tradeableDate || _to == POOL || msg.sender == POOL);
    
     
    if (_to == CONVERT_ADDRESS)
    {   
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    else
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
  }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, MintableToken _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
}

contract SovTokenCrowdsale is Crowdsale {
  uint private constant TIME_UNIT = 86400;     
  uint private constant TOTAL_TIME = 91;
  uint private constant RATE = 1000;
  uint256 private constant START_TIME = 1519128000;
  uint256 private constant HARD_CAP = 100000*1000000000000000000;     
  
   
  address private constant WALLET = 0x04Fb0BbC4f95F5681138502094f8FD570AA2CB9F;
  address private constant POOL = 0xE06be458ad8E80d8b8f198579E0Aa0Ce5f571294;

  function SovTokenCrowdsale() public
        Crowdsale(START_TIME, START_TIME + (TIME_UNIT * TOTAL_TIME), RATE, WALLET, new SovToken(START_TIME + (TIME_UNIT * TOTAL_TIME)))
  {    }
  
   
  function buyTokens(address beneficiary) public payable 
  {
    require(beneficiary != address(0));
    require(validPurchase());
    
    uint256 weiAmount = msg.value;

     
    require(weiRaised.add(weiAmount) < HARD_CAP);

     
    uint256 tokens = getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

     
    token.mint(POOL, tokens/2);

    forwardFunds();
  }

   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) 
  {
    uint256 tokens =  weiAmount.mul(rate);
    uint256 bonus = 100;

     
    if (now >= endTime)
      bonus = 0;
    else if (now <= startTime + (7 * TIME_UNIT))
      bonus += 75;
    else if (now <= startTime + (14 * TIME_UNIT))
      bonus += 65;
    else if (now <= startTime + (21 * TIME_UNIT))
      bonus += 55;
    else if (now <= startTime + (28 * TIME_UNIT))
      bonus += 45;
    else if (now <= startTime + (39 * TIME_UNIT))
      bonus += 35;
    else if (now <= startTime + (70 * TIME_UNIT))
      bonus = 0;
    else if (now <= startTime + (77 * TIME_UNIT))
      bonus += 10;
    else if (now <= startTime + (84 * TIME_UNIT))
      bonus += 5;
    else
      bonus = 100;

    tokens = tokens * bonus / 100;

    bonus = 100;
    
     
     
    if (weiAmount >= 1000000000000000000 && weiAmount < 10000000000000000000)
      bonus += 10;
    else if (weiAmount >= 10000000000000000000)
      bonus += 20;

    tokens = tokens * bonus / 100;
      
    return tokens;
  }  
  
  
   
  function validPurchase() internal view returns (bool) 
  {
      bool isPreSale = now >= startTime && now <= startTime + (39 * TIME_UNIT);
      bool isIco = now > startTime + (70 * TIME_UNIT) && now <= endTime;
      bool withinPeriod = isPreSale || isIco;
      bool nonZeroPurchase = msg.value != 0;
      return withinPeriod && nonZeroPurchase;
  }
}