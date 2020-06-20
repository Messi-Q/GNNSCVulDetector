pragma solidity 0.4.24;

 

contract DipTgeInterface {
    function tokenIsLocked(address _contributor) public constant returns (bool);
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
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
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
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

 

 

pragma solidity 0.4.24;





contract DipToken is PausableToken, MintableToken {

  string public constant name = "Decentralized Insurance Protocol";
  string public constant symbol = "DIP";
  uint256 public constant decimals = 18;
  uint256 public constant MAXIMUM_SUPPLY = 10**9 * 10**18;  

  DipTgeInterface public DipTokensale;

  constructor() public {
    DipTokensale = DipTgeInterface(owner);
  }

  modifier shouldNotBeLockedIn(address _contributor) {
     
     
    require(DipTokensale.tokenIsLocked(_contributor) == false);
    _;
  }

   
  function mint(address _to, uint256 _amount) public returns (bool) {
    if (totalSupply.add(_amount) > MAXIMUM_SUPPLY) {
      return false;
    }

    return super.mint(_to, _amount);
  }

   
  function salvageTokens(ERC20Basic _token, address _to) onlyOwner public {
    _token.transfer(_to, _token.balanceOf(this));
  }

  function transferFrom(address _from, address _to, uint256 _value) shouldNotBeLockedIn(_from) public returns (bool) {
      return super.transferFrom(_from, _to, _value);
  }

  function transfer(address to, uint256 value) shouldNotBeLockedIn(msg.sender) public returns (bool) {
      return super.transfer(to, value);
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


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
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

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

 

 

pragma solidity 0.4.24;





contract DipWhitelistedCrowdsale is Ownable {
  using SafeMath for uint256;

  struct ContributorData {
    uint256 allowance;
    uint256 contributionAmount;
    uint256 tokensIssued;
    bool airdrop;
    uint256 bonus;         
    uint256 lockupPeriod;  
  }

  mapping (address => ContributorData) public contributorList;

  event Whitelisted(address indexed _contributor, uint256 _allowance, bool _airdrop, uint256 _bonus, uint256 _lockupPeriod);

   
  function editContributors (
    address[] _contributorAddresses,
    uint256[] _contributorAllowance,
    bool[] _airdrop,
    uint256[] _bonus,
    uint256[] _lockupPeriod
  ) onlyOwner public {
     
    require(
      _contributorAddresses.length == _contributorAllowance.length &&
      _contributorAddresses.length == _airdrop.length &&
      _contributorAddresses.length == _bonus.length &&
      _contributorAddresses.length == _lockupPeriod.length
    );

    for (uint256 cnt = 0; cnt < _contributorAddresses.length; cnt = cnt.add(1)) {
      require(_bonus[cnt] == 0 || _bonus[cnt] == 4 || _bonus[cnt] == 10);
      require(_lockupPeriod[cnt] <= 2);

      address contributor = _contributorAddresses[cnt];
      contributorList[contributor].allowance = _contributorAllowance[cnt];
      contributorList[contributor].airdrop = _airdrop[cnt];
      contributorList[contributor].bonus = _bonus[cnt];
      contributorList[contributor].lockupPeriod = _lockupPeriod[cnt];

      emit Whitelisted(
        _contributorAddresses[cnt],
        _contributorAllowance[cnt],
        _airdrop[cnt],
        _bonus[cnt],
        _lockupPeriod[cnt]
      );
    }
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

 

 

pragma solidity 0.4.24;







contract DipTge is DipWhitelistedCrowdsale, FinalizableCrowdsale {

  using SafeMath for uint256;

  enum state { pendingStart, priorityPass, crowdsale, crowdsaleEnded }

  uint256 public startOpenPpTime;
  uint256 public hardCap;
  uint256 public lockInTime1;  
  uint256 public lockInTime2;  
  state public crowdsaleState = state.pendingStart;

  event DipTgeStarted(uint256 _time);
  event CrowdsaleStarted(uint256 _time);
  event HardCapReached(uint256 _time);
  event DipTgeEnded(uint256 _time);
  event TokenAllocated(address _beneficiary, uint256 _amount);

  constructor(
    uint256 _startTime,
    uint256 _startOpenPpTime,
    uint256 _endTime,
    uint256 _lockInTime1,
    uint256 _lockInTime2,
    uint256 _hardCap,
    uint256 _rate,
    address _wallet
  )
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    public
  {
     
    require(_startTime >= block.timestamp);
    require(_startOpenPpTime >= _startTime);
    require(_endTime >= _startOpenPpTime);
    require(_lockInTime1 >= _endTime);
    require(_lockInTime2 > _lockInTime1);
    require(_hardCap > 0);
    require(_rate > 0);
    require(_wallet != 0x0);

     
    startOpenPpTime = _startOpenPpTime;
    hardCap = _hardCap;
    lockInTime1 = _lockInTime1;
    lockInTime2 = _lockInTime2;
    DipToken(token).pause();
  }

  function setRate(uint256 _rate) onlyOwner public {
    require(crowdsaleState == state.pendingStart);

    rate = _rate;
  }

  function unpauseToken() onlyOwner external {
    DipToken(token).unpause();
  }

   
  function calculateMaxContribution(address _contributor) public constant returns (uint256 _maxContribution) {
    uint256 maxContrib = 0;

    if (crowdsaleState == state.priorityPass) {
      maxContrib = contributorList[_contributor].allowance.sub(contributorList[_contributor].contributionAmount);

      if (maxContrib > hardCap.sub(weiRaised)) {
        maxContrib = hardCap.sub(weiRaised);
      }
    } else if (crowdsaleState == state.crowdsale) {
      if (contributorList[_contributor].allowance > 0) {
        maxContrib = hardCap.sub(weiRaised);
      }
    }

    return maxContrib;
  }

   
  function calculateTokens(address _contributor, uint256 _amount, uint256 _rate) public constant returns (uint256 _tokens) {
    uint256 bonus = contributorList[_contributor].bonus;

    assert(bonus == 0 || bonus == 4 || bonus == 10);

    if (bonus > 0) {
      _tokens = _amount.add(_amount.div(bonus)).mul(_rate);
    } else {
      _tokens = _amount.mul(_rate);
    }
  }

   
  function setCrowdsaleState() public {
    if (weiRaised >= hardCap && crowdsaleState != state.crowdsaleEnded) {

      crowdsaleState = state.crowdsaleEnded;
      emit HardCapReached(block.timestamp);
      emit DipTgeEnded(block.timestamp);

    } else if (
      block.timestamp >= startTime &&
      block.timestamp < startOpenPpTime &&
      crowdsaleState != state.priorityPass
    ) {

      crowdsaleState = state.priorityPass;
      emit DipTgeStarted(block.timestamp);

    } else if (
      block.timestamp >= startOpenPpTime &&
      block.timestamp <= endTime &&
      crowdsaleState != state.crowdsale
    ) {

      crowdsaleState = state.crowdsale;
      emit CrowdsaleStarted(block.timestamp);

    } else if (
      crowdsaleState != state.crowdsaleEnded &&
      block.timestamp > endTime
    ) {

      crowdsaleState = state.crowdsaleEnded;
      emit DipTgeEnded(block.timestamp);
    }
  }

   
  function buyTokens(address _beneficiary) public payable {
    require(_beneficiary != 0x0);
    require(validPurchase());
    require(contributorList[_beneficiary].airdrop == false);

    setCrowdsaleState();

    uint256 weiAmount = msg.value;
    uint256 maxContrib = calculateMaxContribution(_beneficiary);
    uint256 refund;

    if (weiAmount > maxContrib) {
      refund = weiAmount.sub(maxContrib);
      weiAmount = maxContrib;
    }

     
    require(weiAmount > 0);

     
    uint256 tokens = calculateTokens(_beneficiary, weiAmount, rate);

    assert(tokens > 0);

     
    weiRaised = weiRaised.add(weiAmount);

    require(token.mint(_beneficiary, tokens));
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    contributorList[_beneficiary].contributionAmount = contributorList[_beneficiary].contributionAmount.add(weiAmount);
    contributorList[_beneficiary].tokensIssued = contributorList[_beneficiary].tokensIssued.add(tokens);

    wallet.transfer(weiAmount);

    if (refund != 0) _beneficiary.transfer(refund);
  }

   
  function tokenIsLocked(address _contributor) public constant returns (bool) {

    if (block.timestamp < lockInTime1 && contributorList[_contributor].lockupPeriod == 1) {
      return true;
    } else if (block.timestamp < lockInTime2 && contributorList[_contributor].lockupPeriod == 2) {
      return true;
    }

    return false;

  }


   
  function airdrop() public {
    airdropFor(msg.sender);
  }


   
  function airdropFor(address _beneficiary) public {
    require(_beneficiary != 0x0);
    require(contributorList[_beneficiary].airdrop == true);
    require(contributorList[_beneficiary].tokensIssued == 0);
    require(contributorList[_beneficiary].allowance > 0);

    setCrowdsaleState();

    require(crowdsaleState == state.crowdsaleEnded);

    uint256 amount = contributorList[_beneficiary].allowance.mul(rate);
    require(token.mint(_beneficiary, amount));
    emit TokenAllocated(_beneficiary, amount);

    contributorList[_beneficiary].tokensIssued = contributorList[_beneficiary].tokensIssued.add(amount);
  }

   
  function createTokenContract() internal returns (MintableToken) {
    return new DipToken();
  }

   
  function finalization() internal {
    uint256 maxSupply = DipToken(token).MAXIMUM_SUPPLY();
    token.mint(wallet, maxSupply.sub(token.totalSupply()));  
    token.finishMinting();
    token.transferOwnership(owner);
  }

   
  function salvageTokens(ERC20Basic _token, address _to) onlyOwner external {
    _token.transfer(_to, _token.balanceOf(this));
  }
}

 

 

pragma solidity 0.4.24;






contract RSCConversion is Ownable {

  using SafeMath for *;

  ERC20 public DIP;
  DipTge public DIP_TGE;
  ERC20 public RSC;
  address public DIP_Pool;

  uint256 public constant CONVERSION_NUMINATOR = 10;
  uint256 public constant CONVERSION_DENOMINATOR = 32;
  uint256 public constant CONVERSION_DECIMAL_FACTOR = 10 ** (18 - 3);

  event Conversion(uint256 _rscAmount, uint256 _dipAmount, uint256 _bonus);

  constructor (
      address _dipToken,
      address _dipTge,
      address _rscToken,
      address _dipPool) public {
    require(_dipToken != address(0));
    require(_dipTge != address(0));
    require(_rscToken != address(0));
    require(_dipPool != address(0));

    DIP = ERC20(_dipToken);
    DIP_TGE = DipTge(_dipTge);
    RSC = ERC20(_rscToken);
    DIP_Pool = _dipPool;
  }

   
  function () public {
    convert(RSC.balanceOf(msg.sender));
  }

  function convert(
    uint256 _rscAmount
  ) public {

    uint256 allowance;
    uint256 bonus;
    uint256 lockupPeriod;
    uint256 dipAmount;

    (allowance,  ,  ,  , bonus, lockupPeriod) =
      DIP_TGE.contributorList(msg.sender);

    require(allowance > 0);
    require(RSC.transferFrom(msg.sender, DIP_Pool, _rscAmount));
    dipAmount = _rscAmount.mul(CONVERSION_DECIMAL_FACTOR).mul(CONVERSION_NUMINATOR).div(CONVERSION_DENOMINATOR);

    if (bonus > 0) {
      require(lockupPeriod == 1);
      dipAmount = dipAmount.add(dipAmount.div(bonus));
    }
    require(DIP.transferFrom(DIP_Pool, msg.sender, dipAmount));
    emit Conversion(_rscAmount, dipAmount, bonus);
  }

   
  function salvageTokens(ERC20 _token, address _to) onlyOwner external {
    _token.transfer(_to, _token.balanceOf(this));
  }

}