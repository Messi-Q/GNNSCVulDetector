pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract HolderBase is Ownable {
  using SafeMath for uint256;

  uint8 public constant MAX_HOLDERS = 64;  
  uint256 public coeff;
  bool public distributed;
  bool public initialized;

  struct Holder {
    address addr;
    uint96 ratio;
  }

  Holder[] public holders;

  event Distributed();

  function HolderBase(uint256 _coeff) public {
    require(_coeff != 0);
    coeff = _coeff;
  }

  function getHolderCount() public view returns (uint256) {
    return holders.length;
  }

  function initHolders(address[] _addrs, uint96[] _ratios) public onlyOwner {
    require(!initialized);
    require(holders.length == 0);
    require(_addrs.length != 0);
    require(_addrs.length <= MAX_HOLDERS);
    require(_addrs.length == _ratios.length);

    uint256 accRatio;

    for(uint8 i = 0; i < _addrs.length; i++) {
      if (_addrs[i] != address(0)) {
         
        holders.push(Holder(_addrs[i], _ratios[i]));
      }

      accRatio = accRatio.add(uint256(_ratios[i]));
    }

    require(accRatio <= coeff);

    initialized = true;
  }

   
  function distribute() internal {
    require(!distributed, "Already distributed");
    uint256 balance = this.balance;

    require(balance > 0, "No ether to distribute");
    distributed = true;

    for (uint8 i = 0; i < holders.length; i++) {
      uint256 holderAmount = balance.mul(uint256(holders[i].ratio)).div(coeff);

      holders[i].addr.transfer(holderAmount);
    }

    emit Distributed();  
  }

   
  function distributeToken(ERC20Basic _token, uint256 _targetTotalSupply) internal {
    require(!distributed, "Already distributed");
    distributed = true;

    for (uint8 i = 0; i < holders.length; i++) {
      uint256 holderAmount = _targetTotalSupply.mul(uint256(holders[i].ratio)).div(coeff);
      deliverTokens(_token, holders[i].addr, holderAmount);
    }

    emit Distributed();  
  }

   
  function deliverTokens(ERC20Basic _token, address _beneficiary, uint256 _tokens) internal {}
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


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}


 
contract Locker is Ownable {
  using SafeMath for uint;
  using SafeERC20 for ERC20Basic;

   
  enum State { Init, Ready, Active, Drawn }

  struct Beneficiary {
    uint ratio;              
    uint withdrawAmount;     
    bool releaseAllTokens;
  }

   
  struct Release {
    bool isStraight;         
    uint[] releaseTimes;     
    uint[] releaseRatios;    
  }

  uint public activeTime;

   
  ERC20Basic public token;

  uint public coeff;
  uint public initialBalance;
  uint public withdrawAmount;  

  mapping (address => Beneficiary) public beneficiaries;
  mapping (address => Release) public releases;   
  mapping (address => bool) public locked;  

  uint public numBeneficiaries;
  uint public numLocks;

  State public state;

  modifier onlyState(State v) {
    require(state == v);
    _;
  }

  modifier onlyBeneficiary(address _addr) {
    require(beneficiaries[_addr].ratio > 0);
    _;
  }

  event StateChanged(State _state);
  event Locked(address indexed _beneficiary, bool _isStraight);
  event Released(address indexed _beneficiary, uint256 _amount);

  function Locker(address _token, uint _coeff, address[] _beneficiaries, uint[] _ratios) public {
    require(_token != address(0));
    require(_beneficiaries.length == _ratios.length);

    token = ERC20Basic(_token);
    coeff = _coeff;
    numBeneficiaries = _beneficiaries.length;

    uint accRatio;

    for(uint i = 0; i < numBeneficiaries; i++) {
      require(_ratios[i] > 0);
      beneficiaries[_beneficiaries[i]].ratio = _ratios[i];

      accRatio = accRatio.add(_ratios[i]);
    }

    require(coeff == accRatio);
  }

   
  function activate() external onlyOwner onlyState(State.Ready) {
    require(numLocks == numBeneficiaries);  

    initialBalance = token.balanceOf(this);
    require(initialBalance > 0);

    activeTime = now;  

     
    state = State.Active;
    emit StateChanged(state);
  }

  function getReleaseType(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (bool)
  {
    return releases[_beneficiary].isStraight;
  }

  function getTotalLockedAmounts(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (uint)
  {
    return getPartialAmount(beneficiaries[_beneficiary].ratio, coeff, initialBalance);
  }

  function getReleaseTimes(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (uint[])
  {
    return releases[_beneficiary].releaseTimes;
  }

  function getReleaseRatios(address _beneficiary)
    public
    view
    onlyBeneficiary(_beneficiary)
    returns (uint[])
  {
    return releases[_beneficiary].releaseRatios;
  }

   
  function lock(address _beneficiary, bool _isStraight, uint[] _releaseTimes, uint[] _releaseRatios)
    external
    onlyOwner
    onlyState(State.Init)
    onlyBeneficiary(_beneficiary)
  {
    require(!locked[_beneficiary]);
    require(_releaseRatios.length != 0);
    require(_releaseRatios.length == _releaseTimes.length);

    uint i;
    uint len = _releaseRatios.length;

     
    require(_releaseRatios[len - 1] == coeff);

     
    for(i = 0; i < len - 1; i++) {
      require(_releaseTimes[i] < _releaseTimes[i + 1]);
      require(_releaseRatios[i] < _releaseRatios[i + 1]);
    }

     
    if (_isStraight) {
      require(len == 2);
    }

    numLocks = numLocks.add(1);

     
    releases[_beneficiary].isStraight = _isStraight;

     
    releases[_beneficiary].releaseTimes = _releaseTimes;
    releases[_beneficiary].releaseRatios = _releaseRatios;

     
    locked[_beneficiary] = true;
    emit Locked(_beneficiary, _isStraight);

     
    if (numLocks == numBeneficiaries) {
      state = State.Ready;
      emit StateChanged(state);
    }
  }

   
  function release() external onlyState(State.Active) onlyBeneficiary(msg.sender) {
    require(!beneficiaries[msg.sender].releaseAllTokens);

    uint releasableAmount = getReleasableAmount(msg.sender);
    beneficiaries[msg.sender].withdrawAmount = beneficiaries[msg.sender].withdrawAmount.add(releasableAmount);

    beneficiaries[msg.sender].releaseAllTokens = beneficiaries[msg.sender].withdrawAmount == getPartialAmount(
      beneficiaries[msg.sender].ratio,
      coeff,
      initialBalance);

    withdrawAmount = withdrawAmount.add(releasableAmount);

    if (withdrawAmount == initialBalance) {
      state = State.Drawn;
      emit StateChanged(state);
    }

    token.transfer(msg.sender, releasableAmount);
    emit Released(msg.sender, releasableAmount);
  }

  function getReleasableAmount(address _beneficiary) internal view returns (uint) {
    if (releases[_beneficiary].isStraight) {
      return getStraightReleasableAmount(_beneficiary);
    } else {
      return getVariableReleasableAmount(_beneficiary);
    }
  }

   
  function getStraightReleasableAmount(address _beneficiary) internal view returns (uint releasableAmount) {
    Beneficiary memory _b = beneficiaries[_beneficiary];
    Release memory _r = releases[_beneficiary];

     
    uint totalReleasableAmount = getTotalLockedAmounts(_beneficiary);

    uint firstTime = _r.releaseTimes[0];
    uint lastTime = _r.releaseTimes[1];

     
    require(now >= firstTime);  
     

    if(now >= lastTime) {  
      releasableAmount = totalReleasableAmount;
    } else {
       
      uint firstAmount = getPartialAmount(
        _r.releaseRatios[0],
        coeff,
        totalReleasableAmount);

       
      releasableAmount = getPartialAmount(
        now.sub(firstTime),
        lastTime.sub(firstTime),
        totalReleasableAmount.sub(firstAmount));
      releasableAmount = releasableAmount.add(firstAmount);
    }

     
    releasableAmount = releasableAmount.sub(_b.withdrawAmount);
  }

   
  function getVariableReleasableAmount(address _beneficiary) internal view returns (uint releasableAmount) {
    Beneficiary memory _b = beneficiaries[_beneficiary];
    Release memory _r = releases[_beneficiary];

     
    uint totalReleasableAmount = getTotalLockedAmounts(_beneficiary);

    uint releaseRatio;

     
    for(uint i = _r.releaseTimes.length - 1; i >= 0; i--) {
      if (now >= _r.releaseTimes[i]) {
        releaseRatio = _r.releaseRatios[i];
        break;
      }
    }

    require(releaseRatio > 0);

    releasableAmount = getPartialAmount(
      releaseRatio,
      coeff,
      totalReleasableAmount);
    releasableAmount = releasableAmount.sub(_b.withdrawAmount);
  }

   
   
   
   
   
   
  function getPartialAmount(uint numerator, uint denominator, uint target) public pure returns (uint) {
    return numerator.mul(target).div(denominator);
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

   
  constructor(address _wallet) public {
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
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

   
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}


 
contract MultiHolderVault is HolderBase, RefundVault {
  using SafeMath for uint256;

  function MultiHolderVault(address _wallet, uint256 _ratioCoeff)
    public
    HolderBase(_ratioCoeff)
    RefundVault(_wallet)
  {}

  function close() public onlyOwner {
    require(state == State.Active);
    require(initialized);

    super.distribute();  
    super.close();  
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


contract BaseCrowdsale is HolderBase, Pausable {
  using SafeMath for uint256;

  Locker public locker;      

   
  uint256 public startTime;
  uint256 public endTime;

   
   
  uint256 public rate;


   
  uint256 public weiRaised;

   
  uint256 public crowdsaleRatio;

  bool public isFinalized = false;

  uint256 public cap;

   
  uint256 public goal;

   
  MultiHolderVault public vault;

  address public nextTokenOwner;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event Finalized();
  event ClaimTokens(address indexed _token, uint256 _amount);

  function BaseCrowdsale(uint256 _coeff) HolderBase(_coeff) public {}

   
  function () external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) public payable whenNotPaused {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    uint256 toFund = calculateToFund(beneficiary, weiAmount);
    require(toFund > 0);

    uint256 toReturn = weiAmount.sub(toFund);

    buyTokensPreHook(beneficiary, toFund);

     
    uint256 tokens = getTokenAmount(toFund);

     
    weiRaised = weiRaised.add(toFund);

    if (toReturn > 0) {
      msg.sender.transfer(toReturn);
    }

    buyTokensPostHook(beneficiary, tokens, toFund);

    generateTokens(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, toFund, tokens);
    forwardFunds(toFund);
  }

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    emit Finalized();

    isFinalized = true;
  }


   
  function finalization() internal {
    if (goalReached()) {
      finalizationSuccessHook();
    } else {
      finalizationFailHook();
    }
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached || now > endTime;  
  }

   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

   
  function forwardFunds(uint256 toFund) internal {
    vault.deposit.value(toFund)(msg.sender);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;  
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function calculateToFund(address _beneficiary, uint256 _weiAmount) internal view returns (uint256) {
    uint256 toFund;
    uint256 postWeiRaised = weiRaised.add(_weiAmount);

    if (postWeiRaised > cap) {
      toFund = cap.sub(weiRaised);
    } else {
      toFund = _weiAmount;
    }
    return toFund;
  }

   
  function init(bytes32[] args) public;

   
  function buyTokensPreHook(address _beneficiary, uint256 _toFund) internal {}

   
  function buyTokensPostHook(address _beneficiary, uint256 _tokens, uint256 _toFund) internal {}

  function finalizationFailHook() internal {
    vault.enableRefunds();
  }

  function finalizationSuccessHook() internal {
     
    uint256 targetTotalSupply = getTotalSupply().mul(coeff).div(crowdsaleRatio);
    ERC20Basic token = ERC20Basic(getTokenAddress());

    super.distributeToken(token, targetTotalSupply);
    afterGeneratorHook();

    locker.activate();
    vault.close();

    transferTokenOwnership(nextTokenOwner);
  }

  function afterGeneratorHook() internal {}

   
  function generateTokens(address _beneficiary, uint256 _tokens) internal;
  function transferTokenOwnership(address _to) internal;
  function getTotalSupply() internal returns (uint256);
  function finishMinting() internal returns (bool);
  function getTokenAddress() internal returns (address);

   
  function generateTargetTokens(address _beneficiary, uint256 _targetTotalSupply, uint256 _ratio) internal {
    uint256 tokens = _targetTotalSupply.mul(_ratio).div(coeff);
    generateTokens(_beneficiary, tokens);
  }

   
  function claimTokens(ERC20Basic _token) external onlyOwner {
    require(isFinalized);
    uint256 balance = _token.balanceOf(this);
    _token.transfer(owner, balance);
    emit ClaimTokens(_token, balance);
  }

   
  function deliverTokens(ERC20Basic _token, address _beneficiary, uint256 _tokens) internal {
    generateTokens(_beneficiary, _tokens);
  }

}


 
contract BlockIntervalCrowdsale is BaseCrowdsale {
  uint256 public blockInterval;
  mapping (address => uint256) public recentBlock;

  function BlockIntervalCrowdsale(uint256 _blockInterval) public {
    require(_blockInterval != 0);
    blockInterval = _blockInterval;
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinBlock = recentBlock[msg.sender].add(blockInterval) < block.number;
    return withinBlock && super.validPurchase();
  }

   
  function buyTokensPreHook(address _beneficiary, uint256 _toFund) internal {
    recentBlock[msg.sender] = block.number;
    super.buyTokensPreHook(_beneficiary, _toFund);
  }
}


 

pragma solidity ^0.4.24;





 
contract BonusCrowdsale is BaseCrowdsale {

   
   
  uint32[] public BONUS_TIMES;
  uint32[] public BONUS_TIMES_VALUES;
  uint128[] public BONUS_AMOUNTS;
  uint32[] public BONUS_AMOUNTS_VALUES;

   
  function bonusesForTimesCount() public view returns(uint) {
    return BONUS_TIMES.length;
  }

   
  function setBonusesForTimes(uint32[] times, uint32[] values) public onlyOwner {
    require(times.length == values.length);
    for (uint i = 0; i + 1 < times.length; i++) {
      require(times[i] < times[i+1]);
    }

    BONUS_TIMES = times;
    BONUS_TIMES_VALUES = values;
  }

   
  function bonusesForAmountsCount() public view returns(uint) {
    return BONUS_AMOUNTS.length;
  }

   
  function setBonusesForAmounts(uint128[] amounts, uint32[] values) public onlyOwner {
    require(amounts.length == values.length);
    for (uint i = 0; i + 1 < amounts.length; i++) {
      require(amounts[i] > amounts[i+1]);
    }

    BONUS_AMOUNTS = amounts;
    BONUS_AMOUNTS_VALUES = values;
  }

   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
     
    uint256 bonus = computeBonus(weiAmount);
    uint256 rateWithBonus = rate.mul(coeff.add(bonus)).div(coeff);
    return weiAmount.mul(rateWithBonus);
  }

   
  function computeBonus(uint256 weiAmount) public view returns(uint256) {
    return computeAmountBonus(weiAmount).add(computeTimeBonus());
  }

   
  function computeTimeBonus() public view returns(uint256) {
    require(now >= startTime);  

    for (uint i = 0; i < BONUS_TIMES.length; i++) {
      if (now <= BONUS_TIMES[i]) {  
        return BONUS_TIMES_VALUES[i];
      }
    }

    return 0;
  }

   
  function computeAmountBonus(uint256 weiAmount) public view returns(uint256) {
    for (uint i = 0; i < BONUS_AMOUNTS.length; i++) {
      if (weiAmount >= BONUS_AMOUNTS[i]) {
        return BONUS_AMOUNTS_VALUES[i];
      }
    }

    return 0;
  }

}


 
contract FinishMintingCrowdsale is BaseCrowdsale {
  function afterGeneratorHook() internal {
    require(finishMinting());
    super.afterGeneratorHook();
  }
}


 
contract KYC is Ownable {
   
  mapping (address => bool) public registeredAddress;

   
  mapping (address => bool) public admin;

  event Registered(address indexed _addr);
  event Unregistered(address indexed _addr);
  event SetAdmin(address indexed _addr, bool indexed _isAdmin);

   
  modifier onlyAdmin() {
    require(admin[msg.sender]);
    _;
  }

  function KYC() public {
    admin[msg.sender] = true;
  }

   
  function setAdmin(address _addr, bool _isAdmin)
    public
    onlyOwner
  {
    require(_addr != address(0));
    admin[_addr] = _isAdmin;

    emit SetAdmin(_addr, _isAdmin);
  }

   
  function register(address _addr)
    public
    onlyAdmin
  {
    require(_addr != address(0));

    registeredAddress[_addr] = true;

    emit Registered(_addr);
  }

   
  function registerByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      require(_addrs[i] != address(0));

      registeredAddress[_addrs[i]] = true;

      emit Registered(_addrs[i]);
    }
  }

   
  function unregister(address _addr)
    public
    onlyAdmin
  {
    registeredAddress[_addr] = false;

    emit Unregistered(_addr);
  }

   
  function unregisterByList(address[] _addrs)
    public
    onlyAdmin
  {
    for(uint256 i = 0; i < _addrs.length; i++) {
      registeredAddress[_addrs[i]] = false;

      emit Unregistered(_addrs[i]);
    }
  }
}


 
contract KYCCrowdsale is BaseCrowdsale {

  KYC kyc;

  function KYCCrowdsale (address _kyc) public {
    require(_kyc != 0x0);
    kyc = KYC(_kyc);
  }

  function registered(address _addr) public view returns (bool) {
    return kyc.registeredAddress(_addr);
  }
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


 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
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


contract MintableBaseCrowdsale is BaseCrowdsale {

  MintableToken token;

  function MintableBaseCrowdsale (address _token) public {
    require(_token != address(0));
    token = MintableToken(_token);
  }


  function generateTokens(address _beneficiary, uint256 _tokens) internal {
    token.mint(_beneficiary, _tokens);
  }

  function transferTokenOwnership(address _to) internal {
    token.transferOwnership(_to);
  }

  function getTotalSupply() internal returns (uint256) {
    return token.totalSupply();
  }

  function finishMinting() internal returns (bool) {
    require(token.finishMinting());
    return true;
  }

  function getTokenAddress() internal returns (address) {
    return address(token);
  }
}


 
contract StagedCrowdsale is KYCCrowdsale {

  uint8 public numPeriods;

  Stage[] public stages;

  struct Stage {
    uint128 cap;
    uint128 maxPurchaseLimit;
    uint128 minPurchaseLimit;
    uint128 weiRaised;  
    uint32 startTime;
    uint32 endTime;
    bool kyc;
  }

  function StagedCrowdsale(uint _numPeriods) public {
    numPeriods = uint8(_numPeriods);
    require(numPeriods > 0);
  }

  function initStages(
    uint32[] _startTimes,
    uint32[] _endTimes,
    uint128[] _capRatios,
    uint128[] _maxPurchaseLimits,
    uint128[] _minPurchaseLimits,
    bool[] _kycs)
    public
  {
    uint len = numPeriods;

    require(stages.length == 0);
     
    require(len == _startTimes.length &&
      len == _endTimes.length &&
      len == _capRatios.length &&
      len == _maxPurchaseLimits.length &&
      len == _minPurchaseLimits.length &&
      len == _kycs.length);
     

    for (uint i = 0; i < len; i++) {
      require(_endTimes[i] >= _startTimes[i]);

      uint stageCap;

      if (_capRatios[i] != 0) {
        stageCap = cap.mul(uint(_capRatios[i])).div(coeff);
      } else {
        stageCap = 0;
      }

      stages.push(Stage({
        startTime: _startTimes[i],
        endTime: _endTimes[i],
        cap: uint128(stageCap),
        maxPurchaseLimit: _maxPurchaseLimits[i],
        minPurchaseLimit: _minPurchaseLimits[i],
        kyc: _kycs[i],
        weiRaised: 0
      }));
    }

    require(validPeriods());
  }

   
  function getStageIndex() public view returns (uint8 currentStage, bool onSale) {
    onSale = true;
    Stage memory p;

    for (currentStage = 0; currentStage < stages.length; currentStage++) {
      p = stages[currentStage];
      if (p.startTime <= now && now <= p.endTime) {
        return;
      }
    }

    onSale = false;
  }

   
  function saleFinished() public view returns (bool) {
    require(stages.length == numPeriods);
    return stages[stages.length - 1].endTime < now;
  }


  function validPeriods() internal view returns (bool) {
    if (stages.length != numPeriods) {
      return false;
    }

     
    for (uint8 i = 0; i < stages.length - 1; i++) {
      if (stages[i].endTime >= stages[i + 1].startTime) {
        return false;
      }
    }

    return true;
  }

   
  function calculateToFund(address _beneficiary, uint256 _weiAmount) internal view returns (uint256) {
    uint256 weiAmount = _weiAmount;
    uint8 currentStage;
    bool onSale;

    (currentStage, onSale) = getStageIndex();

    require(onSale);

    Stage memory p = stages[currentStage];

     
    if (p.kyc) {
      require(super.registered(_beneficiary));
    }

     
    require(weiAmount >= uint(p.minPurchaseLimit));

     
    if (p.maxPurchaseLimit != 0 && weiAmount > uint(p.maxPurchaseLimit)) {
      weiAmount = uint(p.maxPurchaseLimit);
    }

     
    if (p.cap > 0) {
      uint256 postWeiRaised = uint256(p.weiRaised).add(weiAmount);

      if (postWeiRaised > p.cap) {
        weiAmount = uint256(p.cap).sub(p.weiRaised);
      }
    }

     
    return super.calculateToFund(_beneficiary, weiAmount);
  }

  function buyTokensPreHook(address _beneficiary, uint256 _toFund) internal {
    uint8 currentStage;
    bool onSale;

    (currentStage, onSale) = getStageIndex();

    require(onSale);

    Stage storage p = stages[currentStage];

    p.weiRaised = uint128(_toFund.add(uint256(p.weiRaised)));
    super.buyTokensPreHook(_beneficiary, _toFund);
  }
}


pragma solidity^0.4.18;








contract AlphaconCrowdsale is BaseCrowdsale, MintableBaseCrowdsale, BonusCrowdsale, BlockIntervalCrowdsale, KYCCrowdsale, StagedCrowdsale, FinishMintingCrowdsale {

  bool public initialized;

   

  function AlphaconCrowdsale(bytes32[5] args) 
    BaseCrowdsale(
      parseUint(args[0]))
    MintableBaseCrowdsale(
      parseAddress(args[1]))
    BonusCrowdsale()
    BlockIntervalCrowdsale(
      parseUint(args[2]))
    KYCCrowdsale(
      parseAddress(args[3]))
    StagedCrowdsale(
      parseUint(args[4]))
    FinishMintingCrowdsale() public {}
  

  function parseBool(bytes32 b) internal pure returns (bool) {
    return b == 0x1;
  }

  function parseUint(bytes32 b) internal pure returns (uint) {
    return uint(b);
  }

  function parseAddress(bytes32 b) internal pure returns (address) {
    return address(b & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff);
  }

  function init(bytes32[] args) public {
    uint _startTime = uint(args[0]);
    uint _endTime = uint(args[1]);
    uint _rate = uint(args[2]);
    uint _cap = uint(args[3]);
    uint _goal = uint(args[4]);
    uint _crowdsaleRatio = uint(args[5]);
    address _vault = address(args[6]);
    address _locker = address(args[7]);
    address _nextTokenOwner = address(args[8]);

    require(_endTime > _startTime);
    require(_rate > 0);
    require(_cap > 0);
    require(_goal > 0);
    require(_cap > _goal);
    require(_crowdsaleRatio > 0);
    require(_vault != address(0));
    require(_locker != address(0));
    require(_nextTokenOwner != address(0));
    
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    cap = _cap;
    goal = _goal;
    crowdsaleRatio = _crowdsaleRatio;
    vault = MultiHolderVault(_vault);
    locker = Locker(_locker);
    nextTokenOwner = _nextTokenOwner;
  }
}