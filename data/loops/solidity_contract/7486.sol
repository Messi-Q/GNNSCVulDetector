pragma solidity ^0.4.13;

contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

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

contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    isWhitelisted(_beneficiary)
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
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

contract OMICrowdsale is WhitelistedCrowdsale, Pausable {
  using SafeMath for uint256;

   
  uint256 constant crowdsaleStartTime = 1530273600;  
  uint256 constant crowdsaleFinishTime = 1538222400;  
  uint256 constant crowdsaleUSDGoal = 22125000;
  uint256 constant crowdsaleTokenGoal = 362500000*1e18;
  uint256 constant minimumTokenPurchase = 2500*1e18;
  uint256 constant maximumTokenPurchase = 5000000*1e18;

   
  OMIToken public token;
  OMITokenLock public tokenLock;

  uint256 public totalUSDRaised;
  uint256 public totalTokensSold;
  bool public isFinalized = false;

  mapping(address => uint256) public purchaseRecords;

   
  event RateChanged(uint256 newRate);
  event USDRaisedUpdated(uint256 newTotal);
  event WhitelistAddressAdded(address newWhitelistAddress);
  event WhitelistAddressRemoved(address removedWhitelistAddress);
  event CrowdsaleStarted();
  event CrowdsaleFinished();


   
  modifier whenNotFinalized () {
    require(!isFinalized);
    _;
  }

   
   
  function OMICrowdsale (
    uint256 _startingRate,
    address _ETHWallet,
    address _OMIToken,
    address _OMITokenLock
  )
    Crowdsale(_startingRate, _ETHWallet, ERC20(_OMIToken))
    public
  {
    token = OMIToken(_OMIToken);
    require(token.isOMITokenContract());

    tokenLock = OMITokenLock(_OMITokenLock);
    require(tokenLock.isOMITokenLockContract());

    rate = _startingRate;
  }

   
  function isOMICrowdsaleContract()
    public 
    pure 
    returns(bool)
  { 
    return true; 
  }

   
  function isOpen()
    public
    view
    whenNotPaused
    whenNotFinalized
    returns(bool)
  {
    return now >= crowdsaleStartTime;
  }

   
   
  function setRate(uint256 _newRate)
    public
    onlyOwner
    whenNotFinalized
    returns(bool)
  {
    require(_newRate > 0);
    rate = _newRate;
    RateChanged(rate);
    return true;
  }

   
  function setUSDRaised(uint256 _total)
    public
    onlyOwner
    whenNotFinalized
  {
    require(_total > 0);
    totalUSDRaised = _total;
    USDRaisedUpdated(_total);
  }

   
   
  function getPurchaseRecord(address _beneficiary) 
    public 
    view 
    isWhitelisted(_beneficiary)
    returns(uint256)
  {
    return purchaseRecords[_beneficiary];
  }

   
   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
    WhitelistAddressAdded(_beneficiary);
  }

   
   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
      WhitelistAddressAdded(_beneficiaries[i]);
    }
  }

   
   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
    WhitelistAddressRemoved(_beneficiary);
  }

   
  function finalize() external onlyOwner {
    _finalization();
  }

   
   
   
   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
    internal
    whenNotPaused
    whenNotFinalized
   {
    super._preValidatePurchase(_beneficiary, _weiAmount);

     
    uint256 _totalPurchased = purchaseRecords[_beneficiary].add(_getTokenAmount(_weiAmount));
    require(_totalPurchased >= minimumTokenPurchase);
    require(_totalPurchased <= maximumTokenPurchase);

     
    require(msg.sender == _beneficiary);

     
    require(now >= crowdsaleStartTime);
  }

   
   
   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount)
    internal
  {
     
    tokenLock.lockTokens(_beneficiary, 1 weeks, _tokenAmount);
  }

   
   
   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount)
    internal
  {
    uint256 _tokenAmount = _getTokenAmount(_weiAmount);

     
    purchaseRecords[_beneficiary] = purchaseRecords[_beneficiary].add(_tokenAmount);
    
     
    totalTokensSold = totalTokensSold.add(_tokenAmount);

     
     
    if (crowdsaleTokenGoal.sub(totalTokensSold) < minimumTokenPurchase) {
      _finalization();
    }
     
    if (totalUSDRaised >= crowdsaleUSDGoal) {
      _finalization();
    }
     
    if (now > crowdsaleFinishTime) {
      _finalization();
    }
  }

   
  function _finalization()
    internal
    whenNotFinalized
  {
    isFinalized = true;
    tokenLock.finishCrowdsale();
    CrowdsaleFinished();
  }
}

contract OMITokenLock is Ownable, Pausable {
  using SafeMath for uint256;

   
  OMIToken public token;
  OMICrowdsale public crowdsale;
  address public allowanceProvider;
  bool public crowdsaleFinished = false;
  uint256 public crowdsaleEndTime;

  struct Lock {
    uint256 amount;
    uint256 lockDuration;
    bool released;
    bool revoked;
  }
  struct TokenLockVault {
    address beneficiary;
    uint256 tokenBalance;
    uint256 lockIndex;
    Lock[] locks;
  }
  mapping(address => TokenLockVault) public tokenLocks;
  address[] public lockIndexes;
  uint256 public totalTokensLocked;

   
  modifier ownerOrCrowdsale () {
    require(msg.sender == owner || OMICrowdsale(msg.sender) == crowdsale);
    _;
  }

   
  event LockedTokens(address indexed beneficiary, uint256 amount, uint256 releaseTime);
  event UnlockedTokens(address indexed beneficiary, uint256 amount);
  event FinishedCrowdsale();

   
   
  function OMITokenLock (address _token, address _allowanceProvider) public {
    token = OMIToken(_token);
    require(token.isOMITokenContract());

    allowanceProvider = _allowanceProvider;
  }

   
  function isOMITokenLockContract()
    public 
    pure 
    returns(bool)
  { 
    return true; 
  }

   
   
  function setCrowdsaleAddress (address _crowdsale)
    public
    onlyOwner
    returns (bool)
  {
    crowdsale = OMICrowdsale(_crowdsale);
    require(crowdsale.isOMICrowdsaleContract());

    return true;
  }

   
   
  function setAllowanceAddress (address _allowanceProvider)
    public
    onlyOwner
    returns (bool)
  {
    allowanceProvider = _allowanceProvider;
    return true;
  }

   
  function finishCrowdsale()
    public
    ownerOrCrowdsale
    whenNotPaused
  {
    require(!crowdsaleFinished);
    crowdsaleFinished = true;
    crowdsaleEndTime = now;
    FinishedCrowdsale();
  }

   
   
  function getTokenBalance(address _beneficiary)
    public
    view
    returns (uint)
  {
    return tokenLocks[_beneficiary].tokenBalance;
  }

   
   
  function getNumberOfLocks(address _beneficiary)
    public
    view
    returns (uint)
  {
    return tokenLocks[_beneficiary].locks.length;
  }

   
   
   
  function getLockByIndex(address _beneficiary, uint256 _lockIndex)
    public
    view
    returns (uint256 amount, uint256 lockDuration, bool released, bool revoked)
  {
    require(_lockIndex >= 0);
    require(_lockIndex <= tokenLocks[_beneficiary].locks.length.sub(1));

    return (
      tokenLocks[_beneficiary].locks[_lockIndex].amount,
      tokenLocks[_beneficiary].locks[_lockIndex].lockDuration,
      tokenLocks[_beneficiary].locks[_lockIndex].released,
      tokenLocks[_beneficiary].locks[_lockIndex].revoked
    );
  }

   
   
   
  function revokeLockByIndex(address _beneficiary, uint256 _lockIndex)
    public
    onlyOwner
    returns (bool)
  {
    require(_lockIndex >= 0);
    require(_lockIndex <= tokenLocks[_beneficiary].locks.length.sub(1));
    require(!tokenLocks[_beneficiary].locks[_lockIndex].revoked);

    tokenLocks[_beneficiary].locks[_lockIndex].revoked = true;

    return true;
  }

   
   
   
   
  function lockTokens(address _beneficiary, uint256 _lockDuration, uint256 _tokens)
    external
    ownerOrCrowdsale
    whenNotPaused
  {
     
    require(_lockDuration >= 0);
     
    require(_tokens > 0);

     
    require(_tokens.add(totalTokensLocked) <= token.allowance(allowanceProvider, address(this)));

    TokenLockVault storage lock = tokenLocks[_beneficiary];

     
    if (lock.beneficiary == 0) {
      lock.beneficiary = _beneficiary;
      lock.lockIndex = lockIndexes.length;
      lockIndexes.push(_beneficiary);
    }

     
    lock.locks.push(Lock(_tokens, _lockDuration, false, false));

     
    lock.tokenBalance = lock.tokenBalance.add(_tokens);

     
    totalTokensLocked = _tokens.add(totalTokensLocked);

    LockedTokens(_beneficiary, _tokens, _lockDuration);
  }

   
  function releaseTokens()
    public
    whenNotPaused
    returns(bool)
  {
    require(crowdsaleFinished);
    require(_release(msg.sender));
    return true;
  }

   
   
  function releaseTokensByAddress(address _beneficiary)
    external
    whenNotPaused
    onlyOwner
    returns (bool)
  {
    require(crowdsaleFinished);
    require(_release(_beneficiary));
    return true;
  }

   
   
   
  function _release(address _beneficiary)
    internal
    whenNotPaused
    returns (bool)
  {
    TokenLockVault memory lock = tokenLocks[_beneficiary];
    require(lock.beneficiary == _beneficiary);
    require(_beneficiary != 0x0);

    bool hasUnDueLocks = false;

    for (uint256 i = 0; i < lock.locks.length; i++) {
      Lock memory currentLock = lock.locks[i];
       
      if (currentLock.released || currentLock.revoked) {
        continue;
      }

       
      if (crowdsaleEndTime.add(currentLock.lockDuration) >= now) {
        hasUnDueLocks = true;
        continue;
      }

       
      require(currentLock.amount <= token.allowance(allowanceProvider, address(this)));

       
      UnlockedTokens(_beneficiary, currentLock.amount);
      tokenLocks[_beneficiary].locks[i].released = true;
      tokenLocks[_beneficiary].tokenBalance = tokenLocks[_beneficiary].tokenBalance.sub(currentLock.amount);
      totalTokensLocked = totalTokensLocked.sub(currentLock.amount);
      assert(token.transferFrom(allowanceProvider, _beneficiary, currentLock.amount));
    }

     
    if (!hasUnDueLocks) {
      delete tokenLocks[_beneficiary];
      lockIndexes[lock.lockIndex] = 0x0;
    }

    return true;
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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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

contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    onlyOwner
    canMint
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract OMIToken is CappedToken, PausableToken {
  string public constant name = "Ecomi Token";
  string public constant symbol = "OMI";
  uint256 public decimals = 18;

  function OMIToken() public CappedToken(1000000000*1e18) {}

   
  function isOMITokenContract()
    public 
    pure 
    returns(bool)
  { 
    return true; 
  }
}