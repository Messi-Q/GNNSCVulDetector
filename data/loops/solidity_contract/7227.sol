pragma solidity 0.4.18;

 

 
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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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

 

contract OAKToken is MintableToken {
  string public name = "Acorn Collective Token";
  string public symbol = "OAK";
  uint256 public decimals = 18;

  mapping(address => bool) public kycRequired;

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    kycRequired[_to] = true;
    return super.mint(_to, _amount);
  }

   
  function transfer(address _to, uint _value) public returns (bool) {
    require(!kycRequired[msg.sender]);

    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(!kycRequired[_from]);

    return super.transferFrom(_from, _to, _value);
  }

  function kycVerify(address participant) onlyOwner public {
    kycRequired[participant] = false;
    KycVerified(participant);
  }
  event KycVerified(address indexed participant);
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  OAKToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  event CrowdSaleTokenContractCreation();
   
  function createTokenContract() internal returns (OAKToken) {
    OAKToken newToken = new OAKToken();
    CrowdSaleTokenContractCreation();
    return newToken;
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

 

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

contract OAKTokenCrowdsale is FinalizableCrowdsale, Pausable {

  uint256 public restrictedPercent;
  address public restricted;
  uint256 public soldTokens;
  uint256 public hardCap;
  uint256 public vipRate;

  uint256 public totalTokenSupply;

  mapping(address => bool) public vip;

   
  uint256 public Y1_lockedTokenReleaseTime;
  uint256 public Y1_lockedTokenAmount;

  uint256 public Y2_lockedTokenReleaseTime;
  uint256 public Y2_lockedTokenAmount;


   
  function OAKTokenCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public
  Crowdsale(_startTime, _endTime, _rate, _wallet) {

     
    totalTokenSupply = 75000000 * 10 ** 18;

     
    hardCap = 7000000 * 10 ** 18;

    vipRate = _rate;
    soldTokens = 0;

    restrictedPercent = 20;
    restricted = msg.sender;
  }

   
  function setHardCap(uint256 _hardCap) public onlyOwner {
    require(!isFinalized);
    require(_hardCap >= 0 && _hardCap <= totalTokenSupply);

    hardCap = _hardCap;
  }

   
  function setWalletAddress(address _wallet) public onlyOwner {
    require(!isFinalized);

    wallet = _wallet;
  }

   
  function setRate(uint256 _rate) public onlyOwner {
    require(!isFinalized);
    require(_rate > 0);

    rate = _rate;
  }

   
  function setVipRate(uint256 _vipRate) public onlyOwner {
    require(!isFinalized);
    require(_vipRate > 0);

    vipRate = _vipRate;
  }

   
  function setVipAddress(address _address) public onlyOwner {
    vip[_address] = true;
  }

   
  function unsetVipAddress(address _address) public onlyOwner {
    vip[_address] = false;
  }

   
  function setSalePeriod(uint256 _startTime, uint256 _endTime) public onlyOwner {
    require(!isFinalized);
    require(_startTime > 0);
    require(_endTime > _startTime);

    startTime = _startTime;
    endTime = _endTime;
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public whenNotPaused payable {
    require(beneficiary != address(0));
    require(!isFinalized);

    uint256 weiAmount = msg.value;
    uint tokens;

    if(vip[msg.sender] == true){
      tokens = weiAmount.mul(vipRate);
    }else{
      tokens = weiAmount.mul(rate);
    }
    require(validPurchase(tokens));
    soldTokens = soldTokens.add(tokens);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function validPurchase(uint256 tokens) internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool withinCap = soldTokens.add(tokens) <= hardCap;
    bool withinTotalSupply = soldTokens.add(tokens) <= totalTokenSupply;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase && withinCap && withinTotalSupply;
  }

   
  function finalization() internal {
     
    uint256 restrictedTokens = soldTokens.div(100).mul(restrictedPercent);
    token.mint(this, restrictedTokens);
    token.kycVerify(this);

    Y1_lockedTokenReleaseTime = now + 1 years;
    Y1_lockedTokenAmount = restrictedTokens.div(2);

    Y2_lockedTokenReleaseTime = now + 2 years;
    Y2_lockedTokenAmount = restrictedTokens.div(2);

     
    token.finishMinting();

     
    token.transferOwnership(owner);

  }

   
  function Y1_release() onlyOwner public {
    require(Y1_lockedTokenAmount > 0);
    require(now > Y1_lockedTokenReleaseTime);

     
    token.transfer(restricted, Y1_lockedTokenAmount);

    Y1_lockedTokenAmount = 0;
  }

   
  function Y2_release() onlyOwner public {
    require(Y1_lockedTokenAmount == 0);
    require(Y2_lockedTokenAmount > 0);
    require(now > Y2_lockedTokenReleaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

     
    token.transfer(restricted, amount);

    Y2_lockedTokenAmount = 0;
  }

  function kycVerify(address participant) onlyOwner public {
    token.kycVerify(participant);
  }

  function addPrecommitment(address participant, uint balance) onlyOwner public {
    require(!isFinalized);
    require(balance > 0);
     
    require(soldTokens.add(balance) <= totalTokenSupply);

    soldTokens = soldTokens.add(balance);
    token.mint(participant, balance);
  }

}