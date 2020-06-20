pragma solidity ^0.4.17;

 

 
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

 

contract ERC20Interface {

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);

}

 

contract BaseToken is ERC20Interface {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);

    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);

    return true;
  }

   
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);

    return true;
  }

   
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
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

 

 
contract MintableToken is BaseToken, Ownable {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(_to != address(0));

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

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 tokens);

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  uint256 public rate;

   
  address public wallet;

   
  uint256 public weiRaised;
   
  uint256 public tokensSold;


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    token = MintableToken(_token);
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
    tokensSold = tokensSold.add(tokens);

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

 

contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  event Finalized();

  bool public isFinalized = false;

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

 

contract TokenCappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public tokenCap;

  function TokenCappedCrowdsale(uint256 _tokenCap) public {
    require(_tokenCap > 0);
    tokenCap = _tokenCap;
  }

  function isCapReached() public view returns (bool) {
    return tokensSold >= tokenCap;
  }

  function hasEnded() public view returns (bool) {
    return isCapReached() || super.hasEnded();
  }

   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = tokensSold.add(getTokenAmount(msg.value)) <= tokenCap;
    return withinCap && super.validPurchase();
  }
}

 

contract ZitKOINCrowdsale is TokenCappedCrowdsale, FinalizableCrowdsale {
  event RateChanged(uint256 newRate);

  uint256 private constant E18 = 10**18;

   
  uint256 private TOKEN_SALE_CAP = 500000000 * E18;

   
  uint256 public constant TEAM_TOKENS = 200000000 * E18;
  address public constant TEAM_ADDRESS = 0x900f9dF4Dd7A5131adFd7da173E75e328968F5f3;

   
  uint256 public constant FUTURE_ME_TOKENS = 170000000 * E18;
  address public constant FUTURE_ME_ADDRESS = 0x900f9dF4Dd7A5131adFd7da173E75e328968F5f3;

   
  uint256 public constant ADVISORS_TOKENS = 80000000 * E18;
  address public constant ADVISORS_ADDRESS = 0x900f9dF4Dd7A5131adFd7da173E75e328968F5f3;

   
  uint256 public constant AIRDROP_TOKENS = 50000000 * E18;
  address public constant AIRDROP_ADDRESS = 0x900f9dF4Dd7A5131adFd7da173E75e328968F5f3;


  function ZitKOINCrowdsale(uint256 _startTime,
                            uint256 _endTime,
                            uint256 _rate,
                            address _wallet,
                            address _token)
        TokenCappedCrowdsale(TOKEN_SALE_CAP)
        Crowdsale(_startTime, _endTime, _rate, _wallet, _token) public {
  }

  function setCrowdsaleWallet(address _wallet) public onlyOwner {
    require(_wallet != address(0));
    wallet = _wallet;
  }

  function setRate(uint256 _rate) public onlyOwner  {
    rate = _rate;
    RateChanged(_rate);
  }

  function finalization() internal {
    token.mint(TEAM_ADDRESS, TEAM_TOKENS);
    token.mint(FUTURE_ME_ADDRESS, FUTURE_ME_TOKENS);
    token.mint(ADVISORS_ADDRESS, ADVISORS_TOKENS);
    token.mint(AIRDROP_ADDRESS, AIRDROP_TOKENS);

     
    token.finishMinting();
     
    token.transferOwnership(owner);
     
    super.finalization();
  }

   
  function recoverERC20Tokens(address _erc20, uint256 _amount) public onlyOwner {
    ERC20Interface(_erc20).transfer(msg.sender, _amount);
  }

  function releaseTokenOwnership() public onlyOwner {
    token.transferOwnership(owner);
  }
}