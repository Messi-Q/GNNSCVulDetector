pragma solidity ^0.4.21;

 
 

 
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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

 
 
 


 
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
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
    token.safeTransfer(_beneficiary, _tokenAmount);
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

 
 
 


 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

 
 
 


 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 
 
 


 
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

 
 
 

contract TimedPresaleCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    uint256 public presaleOpeningTime;
    uint256 public presaleClosingTime;

    uint256 public bonusUnlockTime;

    event CrowdsaleTimesChanged(uint256 presaleOpeningTime, uint256 presaleClosingTime, uint256 openingTime, uint256 closingTime);

     
    modifier onlyWhileOpen {
        require(isPresale() || isSale());
        _;
    }


    constructor(uint256 _presaleOpeningTime, uint256 _presaleClosingTime, uint256 _openingTime, uint256 _closingTime) public
    TimedCrowdsale(_openingTime, _closingTime) {

        changeTimes(_presaleOpeningTime, _presaleClosingTime, _openingTime, _closingTime);
    }

    function changeTimes(uint256 _presaleOpeningTime, uint256 _presaleClosingTime, uint256 _openingTime, uint256 _closingTime) public onlyOwner {
        require(!isFinalized);
        require(_presaleClosingTime >= _presaleOpeningTime);
        require(_openingTime >= _presaleClosingTime);
        require(_closingTime >= _openingTime);

        presaleOpeningTime = _presaleOpeningTime;
        presaleClosingTime = _presaleClosingTime;
        openingTime = _openingTime;
        closingTime = _closingTime;

        emit CrowdsaleTimesChanged(_presaleOpeningTime, _presaleClosingTime, _openingTime, _closingTime);
    }

    function isPresale() public view returns (bool) {
        return now >= presaleOpeningTime && now <= presaleClosingTime;
    }

    function isSale() public view returns (bool) {
        return now >= openingTime && now <= closingTime;
    }
}

 
 
 



contract TokenCappedCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    uint256 public cap;
    uint256 public totalTokens;
    uint256 public soldTokens = 0;
    bool public capIncreased = false;

    event CapIncreased();

    constructor() public {

        cap = 400 * 1000 * 1000 * 1 ether;
        totalTokens = 750 * 1000 * 1000 * 1 ether;
    }

    function notExceedingSaleCap(uint256 amount) internal view returns (bool) {
        return cap >= amount.add(soldTokens);
    }

     
    function finalization() internal {
        super.finalization();
    }
}

 
 
 

contract OpiriaCrowdsale is TimedPresaleCrowdsale, MintedCrowdsale, TokenCappedCrowdsale {
    using SafeMath for uint256;

    uint256 public presaleWeiLimit;

    address public tokensWallet;

    uint256 public totalBonus = 0;

    bool public hiddenCapTriggered;

    uint16 public additionalBonusPercent = 0;

    mapping(address => uint256) public bonusOf;

     
    constructor(ERC20 _token, uint16 _initialEtherUsdRate, address _wallet, address _tokensWallet,
        uint256 _presaleOpeningTime, uint256 _presaleClosingTime, uint256 _openingTime, uint256 _closingTime
    ) public
    TimedPresaleCrowdsale(_presaleOpeningTime, _presaleClosingTime, _openingTime, _closingTime)
    Crowdsale(_initialEtherUsdRate, _wallet, _token) {
        setEtherUsdRate(_initialEtherUsdRate);
        tokensWallet = _tokensWallet;

        require(PausableToken(token).paused());
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
         

        return _weiAmount.mul(rate).mul(10);
    }

    function _getBonusAmount(uint256 tokens) internal view returns (uint256) {
        uint16 bonusPercent = _getBonusPercent();
        uint256 bonusAmount = tokens.mul(bonusPercent).div(100);
        return bonusAmount;
    }

    function _getBonusPercent() internal view returns (uint16) {
        if (isPresale()) {
            return 20;
        }
        uint256 daysPassed = (now - openingTime) / 1 days;
        uint16 calcPercent = 0;
        if (daysPassed < 15) {
             
            calcPercent = (15 - uint8(daysPassed));
        }

        calcPercent = additionalBonusPercent + calcPercent;

        return calcPercent;
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _saveBonus(_beneficiary, _tokenAmount);
        _deliverTokens(_beneficiary, _tokenAmount);

        soldTokens = soldTokens.add(_tokenAmount);
    }

    function _saveBonus(address _beneficiary, uint256 tokens) internal {
        uint256 bonusAmount = _getBonusAmount(tokens);
        if (bonusAmount > 0) {
            totalBonus = totalBonus.add(bonusAmount);
            soldTokens = soldTokens.add(bonusAmount);
            bonusOf[_beneficiary] = bonusOf[_beneficiary].add(bonusAmount);
        }
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        if (isPresale()) {
            require(_weiAmount >= presaleWeiLimit);
        }

        uint256 tokens = _getTokenAmount(_weiAmount);
        uint256 bonusTokens = _getBonusAmount(tokens);
        require(notExceedingSaleCap(tokens.add(bonusTokens)));
    }

    function setEtherUsdRate(uint16 _etherUsdRate) public onlyOwner {
        rate = _etherUsdRate;

         
         
        presaleWeiLimit = uint256(1 ether).mul(2500).div(rate);
    }

    function setAdditionalBonusPercent(uint8 _additionalBonusPercent) public onlyOwner {
        additionalBonusPercent = _additionalBonusPercent;
    }
     
    function sendTokensTo(uint256 amount, address to) public onlyOwner {
        require(!isFinalized);
        require(notExceedingSaleCap(amount));

        require(MintableToken(token).mint(to, amount));
        soldTokens = soldTokens.add(amount);

        emit TokenPurchase(msg.sender, to, 0, amount);
    }

    function sendTokensToBatch(uint256[] amounts, address[] recipients) public onlyOwner {
        require(amounts.length == recipients.length);
        for (uint i = 0; i < recipients.length; i++) {
            sendTokensTo(amounts[i], recipients[i]);
        }
    }

    function addBonusBatch(uint256[] amounts, address[] recipients) public onlyOwner {

        for (uint i = 0; i < recipients.length; i++) {
            require(PausableToken(token).balanceOf(recipients[i]) > 0);
            require(notExceedingSaleCap(amounts[i]));

            totalBonus = totalBonus.add(amounts[i]);
            soldTokens = soldTokens.add(amounts[i]);
            bonusOf[recipients[i]] = bonusOf[recipients[i]].add(amounts[i]);
        }
    }

    function unlockTokenTransfers() public onlyOwner {
        require(isFinalized);
        require(now > closingTime + 30 days);
        require(PausableToken(token).paused());
        bonusUnlockTime = now + 30 days;
        PausableToken(token).unpause();
    }


    function distributeBonus(address[] addresses) public onlyOwner {
        require(now > bonusUnlockTime);
        for (uint i = 0; i < addresses.length; i++) {
            if (bonusOf[addresses[i]] > 0) {
                uint256 bonusAmount = bonusOf[addresses[i]];
                _deliverTokens(addresses[i], bonusAmount);
                totalBonus = totalBonus.sub(bonusAmount);
                bonusOf[addresses[i]] = 0;
            }
        }
        if (totalBonus == 0 && reservedTokensClaimStage == 3) {
            MintableToken(token).finishMinting();
        }
    }

    function withdrawBonus() public {
        require(now > bonusUnlockTime);
        require(bonusOf[msg.sender] > 0);

        _deliverTokens(msg.sender, bonusOf[msg.sender]);
        totalBonus = totalBonus.sub(bonusOf[msg.sender]);
        bonusOf[msg.sender] = 0;

        if (totalBonus == 0 && reservedTokensClaimStage == 3) {
            MintableToken(token).finishMinting();
        }
    }


    function finalization() internal {
        super.finalization();

         
        uint256 toMintNow = totalTokens.mul(25).div(100);

        if (!capIncreased) {
             
            toMintNow = toMintNow.add(50 * 1000 * 1000);
        }
        _deliverTokens(tokensWallet, toMintNow);
    }

    uint8 public reservedTokensClaimStage = 0;

    function claimReservedTokens() public onlyOwner {

        uint256 toMintNow = totalTokens.mul(5).div(100);
        if (reservedTokensClaimStage == 0) {
            require(now > closingTime + 6 * 30 days);
            reservedTokensClaimStage = 1;
            _deliverTokens(tokensWallet, toMintNow);
        }
        else if (reservedTokensClaimStage == 1) {
            require(now > closingTime + 12 * 30 days);
            reservedTokensClaimStage = 2;
            _deliverTokens(tokensWallet, toMintNow);
        }
        else if (reservedTokensClaimStage == 2) {
            require(now > closingTime + 24 * 30 days);
            reservedTokensClaimStage = 3;
            _deliverTokens(tokensWallet, toMintNow);
            if (totalBonus == 0) {
                MintableToken(token).finishMinting();
                MintableToken(token).transferOwnership(owner);
            }
        }
        else {
            revert();
        }
    }

    function increaseCap() public onlyOwner {
        require(!capIncreased);
        require(!isFinalized);
        require(now < openingTime + 5 days);

        capIncreased = true;
        cap = cap.add(50 * 1000 * 1000);
        emit CapIncreased();
    }

    function triggerHiddenCap() public onlyOwner {
        require(!hiddenCapTriggered);
        require(now > presaleOpeningTime);
        require(now < presaleClosingTime);

        presaleClosingTime = now;
        openingTime = now + 24 hours;

        hiddenCapTriggered = true;
    }
}

 