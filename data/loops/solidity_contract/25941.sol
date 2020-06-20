pragma solidity ^0.4.18;



 
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


 

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract EthixToken is PausableToken {
  string public constant name = "EthixToken";
  string public constant symbol = "ETHIX";
  uint8 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 100000000 * (10 ** uint256(decimals));
  uint256 public totalSupply;

   
  function EthixToken() public {
    totalSupply = INITIAL_SUPPLY;
    balances[owner] = totalSupply;
    Transfer(0x0, owner, INITIAL_SUPPLY);
  }

}


 
contract TokenDistributionStrategy {
  using SafeMath for uint256;

  CompositeCrowdsale crowdsale;
  uint256 rate;

  modifier onlyCrowdsale() {
    require(msg.sender == address(crowdsale));
    _;
  }

  function TokenDistributionStrategy(uint256 _rate) {
    require(_rate > 0);
    rate = _rate;
  }

  function initializeDistribution(CompositeCrowdsale _crowdsale) {
    require(crowdsale == address(0));
    require(_crowdsale != address(0));
    crowdsale = _crowdsale;
  }

  function returnUnsoldTokens(address _wallet) onlyCrowdsale {
    
  }

  function whitelistRegisteredAmount(address beneficiary) view returns (uint256 amount) {
  }

  function distributeTokens(address beneficiary, uint amount);

  function calculateTokenAmount(uint256 _weiAmount, address beneficiary) view returns (uint256 amount);

  function getToken() view returns(ERC20);

  

}


 
contract FixedPoolWithBonusTokenDistributionStrategy is TokenDistributionStrategy {
  using SafeMath for uint256;
  uint256 constant MAX_DISCOUNT = 100;

   
  struct BonusInterval {
     
    uint256 endPeriod;
     
    uint256 bonus;
  }
  BonusInterval[] bonusIntervals;
  bool intervalsConfigured = false;

   
  ERC20 token;
  mapping(address => uint256) contributions;
  uint256 totalContributed;
   

  function FixedPoolWithBonusTokenDistributionStrategy(ERC20 _token, uint256 _rate)
           TokenDistributionStrategy(_rate) public
  {
    token = _token;
  }


   
   
   
   
  modifier validateIntervals {
    _;
    require(intervalsConfigured == false);
    intervalsConfigured = true;
    require(bonusIntervals.length > 0);
    for(uint i = 0; i < bonusIntervals.length; ++i) {
      require(bonusIntervals[i].bonus <= MAX_DISCOUNT);
      require(bonusIntervals[i].bonus >= 0);
      require(crowdsale.startTime() < bonusIntervals[i].endPeriod);
      require(bonusIntervals[i].endPeriod <= crowdsale.endTime());
      if (i != 0) {
        require(bonusIntervals[i-1].endPeriod < bonusIntervals[i].endPeriod);
      }
    }
  }

   
  function initIntervals() validateIntervals {
  }

  function calculateTokenAmount(uint256 _weiAmount, address beneficiary) view returns (uint256 tokens) {
     
    for (uint i = 0; i < bonusIntervals.length; i++) {
      if (now <= bonusIntervals[i].endPeriod) {
         
        tokens = _weiAmount.mul(rate);
         
         
        return tokens.add(tokens.mul(bonusIntervals[i].bonus).div(100));
      }
    }
    return _weiAmount.mul(rate);
  }

  function distributeTokens(address _beneficiary, uint256 _tokenAmount) onlyCrowdsale {
    contributions[_beneficiary] = contributions[_beneficiary].add(_tokenAmount);
    totalContributed = totalContributed.add(_tokenAmount);
    require(totalContributed <= token.balanceOf(this));
  }

  function compensate(address _beneficiary) {
    require(crowdsale.hasEnded());
    if (token.transfer(_beneficiary, contributions[_beneficiary])) {
      contributions[_beneficiary] = 0;
    }
  }

  function getTokenContribution(address _beneficiary) view returns(uint256){
    return contributions[_beneficiary];
  }

  function getToken() view returns(ERC20) {
    return token;
  }

  function getIntervals() view returns (uint256[] _endPeriods, uint256[] _bonuss) {
    uint256[] memory endPeriods = new uint256[](bonusIntervals.length);
    uint256[] memory bonuss = new uint256[](bonusIntervals.length);
    for (uint256 i=0; i<bonusIntervals.length; i++) {
      endPeriods[i] = bonusIntervals[i].endPeriod;
      bonuss[i] = bonusIntervals[i].bonus;
    }
    return (endPeriods, bonuss);
  }

}


 
contract VestedTokenDistributionStrategy is Ownable, FixedPoolWithBonusTokenDistributionStrategy {


  event Released(address indexed beneficiary, uint256 indexed amount);

   
  uint256 public vestingStart;
  bool public vestingConfigured = false;
  uint256 public vestingDuration;

  mapping (address => uint256) public released;

  modifier vestingPeriodStarted {
    require(crowdsale.hasEnded());
    require(vestingConfigured == true);
    require(now > vestingStart);
    _;
  }

  function VestedTokenDistributionStrategy(ERC20 _token, uint256 _rate)
            Ownable()
            FixedPoolWithBonusTokenDistributionStrategy(_token, _rate) {

  }

   
  function configureVesting(uint256 _vestingStart, uint256 _vestingDuration) onlyOwner {
    require(vestingConfigured == false);
    require(_vestingStart > crowdsale.endTime());
    require(_vestingDuration > 0);
    vestingStart = _vestingStart;
    vestingDuration = _vestingDuration;
    vestingConfigured = true;
  }

   
   function compensate(address _beneficiary) public onlyOwner vestingPeriodStarted {
     uint256 unreleased = releasableAmount(_beneficiary);

     require(unreleased > 0);

     released[_beneficiary] = released[_beneficiary].add(unreleased);

     require(token.transfer(_beneficiary, unreleased));
     Released(_beneficiary,unreleased);

   }

   
   function releasableAmount(address _beneficiary) public view returns (uint256) {
     return vestedAmount(_beneficiary).sub(released[_beneficiary]);
   }

   
  function vestedAmount(address _beneficiary) public view returns (uint256) {
    uint256 totalBalance = contributions[_beneficiary];
     
    if (now < vestingStart || vestingConfigured == false) {
      return 0;
    } else if (now >= vestingStart.add(vestingDuration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(vestingStart)).div(vestingDuration);
    }
  }

  function getReleased(address _beneficiary) public view returns (uint256) {
    return released[_beneficiary];
  }

}


 
contract WhitelistedDistributionStrategy is Ownable, VestedTokenDistributionStrategy {
    uint256 public constant maximumBidAllowed = 500 ether;

    uint256 rate_for_investor;
    mapping(address=>uint) public registeredAmount;

    event RegistrationStatusChanged(address target, bool isRegistered);

    function WhitelistedDistributionStrategy(ERC20 _token, uint256 _rate, uint256 _whitelisted_rate)
              VestedTokenDistributionStrategy(_token,_rate){
        rate_for_investor = _whitelisted_rate;
    }

     
    function changeRegistrationStatus(address target, uint256 amount)
        public
        onlyOwner
    {
        require(amount <= maximumBidAllowed);
        registeredAmount[target] = amount;
        if (amount > 0){
            RegistrationStatusChanged(target, true);
        }else{
            RegistrationStatusChanged(target, false);
        }
    }

     
    function changeRegistrationStatuses(address[] targets, uint256[] amounts)
        public
        onlyOwner
    {
        require(targets.length == amounts.length);
        for (uint i = 0; i < targets.length; i++) {
            changeRegistrationStatus(targets[i], amounts[i]);
        }
    }

     

    function calculateTokenAmount(uint256 _weiAmount, address beneficiary) view returns (uint256 tokens) {
        if (_weiAmount >= registeredAmount[beneficiary] && registeredAmount[beneficiary] > 0 ){
            tokens = _weiAmount.mul(rate_for_investor);
        } else{
            tokens = super.calculateTokenAmount(_weiAmount, beneficiary);
        }
    }

     

    function whitelistRegisteredAmount(address beneficiary) view returns (uint256 amount) {
        amount = registeredAmount[beneficiary];
    }
}


 
contract EthicHubTokenDistributionStrategy is Ownable, WhitelistedDistributionStrategy {
  
  event UnsoldTokensReturned(address indexed destination, uint256 amount);


  function EthicHubTokenDistributionStrategy(EthixToken _token, uint256 _rate, uint256 _rateForWhitelisted)
           WhitelistedDistributionStrategy(_token, _rate, _rateForWhitelisted)
           public
  {

  }


   
  function initIntervals() onlyOwner validateIntervals  {

     
    require(owner == crowdsale.owner());

    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 1 days,10));
    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 2 days,10));
    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 3 days,8));
    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 4 days,6));
    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 5 days,4));
    bonusIntervals.push(BonusInterval(crowdsale.startTime() + 6 days,2));
  }

  function returnUnsoldTokens(address _wallet) onlyCrowdsale {
     
    if (token.balanceOf(this) == 0) {
      UnsoldTokensReturned(_wallet,0);
      return;
    }
    
    uint256 balance = token.balanceOf(this).sub(totalContributed);
    require(balance > 0);

    if(token.transfer(_wallet, balance)) {
      UnsoldTokensReturned(_wallet, balance);
    }
    
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





 
contract CompositeCrowdsale is Ownable {
  using SafeMath for uint256;

   
  TokenDistributionStrategy public tokenDistribution;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function CompositeCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet, TokenDistributionStrategy _tokenDistribution) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_wallet != 0x0);
    require(address(_tokenDistribution) != address(0));

    startTime = _startTime;
    endTime = _endTime;

    tokenDistribution = _tokenDistribution;
    tokenDistribution.initializeDistribution(this);

    wallet = _wallet;
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = tokenDistribution.calculateTokenAmount(weiAmount, beneficiary);
     
    weiRaised = weiRaised.add(weiAmount);

    tokenDistribution.distributeTokens(beneficiary, tokens);
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



 
contract CappedCompositeCrowdsale is CompositeCrowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCompositeCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinCap && super.validPurchase();
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

 
contract FinalizableCompositeCrowdsale is CompositeCrowdsale {
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


 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}



 
contract RefundableCompositeCrowdsale is FinalizableCompositeCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

  function RefundableCompositeCrowdsale(uint256 _goal) {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

}

contract EthicHubPresale is Ownable, Pausable, CappedCompositeCrowdsale, RefundableCompositeCrowdsale {

  uint256 public constant minimumBidAllowed = 0.1 ether;
  uint256 public constant maximumBidAllowed = 100 ether;
  uint256 public constant WHITELISTED_PREMIUM_TIME = 1 days;


  mapping(address=>uint) public participated;

   
  function EthicHubPresale(uint256 _startTime, uint256 _endTime, uint256 _goal, uint256 _cap, address _wallet, EthicHubTokenDistributionStrategy _tokenDistribution)
    CompositeCrowdsale(_startTime, _endTime, _wallet, _tokenDistribution)
    CappedCompositeCrowdsale(_cap)
    RefundableCompositeCrowdsale(_goal)
  {

     
     
    require(_goal <= _cap);
  }

  function claimRefund() public {
    super.claimRefund();
  }

   
  function buyTokens(address beneficiary) whenNotPaused payable {
    require(msg.value >= minimumBidAllowed);
    require(participated[msg.sender].add(msg.value) <= maximumBidAllowed);
    participated[msg.sender] = participated[msg.sender].add(msg.value);

    super.buyTokens(beneficiary);
  }

   
  function getInvestedAmount(address investor) view public returns(uint investedAmount){
    investedAmount = participated[investor];
  }

   
   
   
  function validPurchase() internal view returns (bool) {
     
    if ((now >= startTime.sub(WHITELISTED_PREMIUM_TIME)) && (now <= startTime)){
        uint256 registeredAmount = tokenDistribution.whitelistRegisteredAmount(msg.sender);
        bool isWhitelisted = registeredAmount > 0;
        bool withinCap = weiRaised.add(msg.value) <= cap;
        bool nonZeroPurchase = msg.value != 0;
        return isWhitelisted && withinCap && nonZeroPurchase;
    } else {
        return super.validPurchase();
    }
  }

   
  function finalization() internal {
    super.finalization();
    tokenDistribution.returnUnsoldTokens(wallet);
  }
}