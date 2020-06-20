pragma solidity ^0.4.13;

contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
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

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
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

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached || super.hasEnded();
  }

   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinCap && super.validPurchase();
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

contract FinalizableCappedCrowdsale is CappedCrowdsale, Ownable {

    bool public isFinalized = false;
    bool public reconciliationDateSet = false;
    uint public reconciliationDate = 0;

    event Finalized();

     
    function finalize() onlyOwnerOrAfterReconciliation public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();
        isFinalized = true;
    }

    function setReconciliationDate(uint _reconciliationDate) onlyOwner {
        reconciliationDate = _reconciliationDate;
        reconciliationDateSet = true;
    }

     
    function finalization() internal {
    }

    modifier onlyOwnerOrAfterReconciliation(){
        require(msg.sender == owner || (reconciliationDate <= now && reconciliationDateSet));
        _;
    }

}

contract PoolSegregationCrowdsale is Ownable {
     
    enum POOLS {POOL_STRATEGIC_INVESTORS, POOL_COMPANY_RESERVE, POOL_USER_ADOPTION, POOL_TEAM, POOL_ADVISORS, POOL_PROMO}

    using SafeMath for uint;

    mapping (uint => PoolInfo) poolMap;

    struct PoolInfo {
        uint contribution;
        uint poolCap;
    }

    function PoolSegregationCrowdsale(uint _cap) {
        poolMap[uint(POOLS.POOL_STRATEGIC_INVESTORS)] = PoolInfo(0, _cap.mul(285).div(1000));
        poolMap[uint(POOLS.POOL_COMPANY_RESERVE)] = PoolInfo(0, _cap.mul(10).div(100));
        poolMap[uint(POOLS.POOL_USER_ADOPTION)] = PoolInfo(0, _cap.mul(20).div(100));
        poolMap[uint(POOLS.POOL_TEAM)] = PoolInfo(0, _cap.mul(3).div(100));
        poolMap[uint(POOLS.POOL_ADVISORS)] = PoolInfo(0, _cap.mul(3).div(100));
        poolMap[uint(POOLS.POOL_PROMO)] = PoolInfo(0, _cap.mul(3).div(100));
    }

    modifier onlyIfInPool(uint amount, uint poolId) {
        PoolInfo poolInfo = poolMap[poolId];
        require(poolInfo.contribution.add(amount) <= poolInfo.poolCap); 
        _;
        poolInfo.contribution = poolInfo.contribution.add(amount);
    }

    function transferRemainingTokensToUserAdoptionPool(uint difference) internal {
        poolMap[uint(POOLS.POOL_USER_ADOPTION)].poolCap = poolMap[uint(POOLS.POOL_USER_ADOPTION)].poolCap.add(difference);
    }

    function getPoolCapSize(uint poolId) public view returns(uint) {
        return poolMap[poolId].poolCap;
    }

}

contract LuckCashCrowdsale is FinalizableCappedCrowdsale, PoolSegregationCrowdsale {

     
    WhiteListRegistry public whitelistRegistry;
    using SafeMath for uint;
    uint constant public CAP = 600000000*1e18;
    mapping (address => uint) contributions;

     
    event VestedTokensFor(address indexed beneficiary, address fund, uint256 tokenAmount);
     
    event Finalized();    

     
    event MintedTokensFor(address indexed beneficiary, uint256 tokenAmount);

     
    function LuckCashCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _whiteListRegistry) public
    CappedCrowdsale(CAP.mul(325).div(1000))
    PoolSegregationCrowdsale(CAP)
    FinalizableCappedCrowdsale()
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        require(_whiteListRegistry != address(0));
        whitelistRegistry = WhiteListRegistry(_whiteListRegistry);
        LuckCashToken(token).pause();
    }

     
    function createTokenContract() internal returns(MintableToken) {
        return new LuckCashToken(CAP);  
    }

     
    function mintTokensFor(address beneficiary, uint256 amount, uint poolId) external onlyOwner onlyIfInPool(amount, poolId) {
        require(beneficiary != address(0) && amount != 0);
         

        token.mint(beneficiary, amount);

        MintedTokensFor(beneficiary, amount);
    }

     
    function createVestFundFor(address beneficiary, uint256 amount, uint256 quarters, uint poolId) external onlyOwner onlyIfInPool(amount, poolId) {
        require(beneficiary != address(0) && amount != 0);
        require(quarters > 0);
         

        VestingFund fund = new VestingFund(beneficiary, endTime, quarters, token);  
        token.mint(fund, amount);

        VestedTokensFor(beneficiary, fund, amount);
    }

     
    function validPurchase() internal view returns(bool) {
        return super.validPurchase() && canContributeAmount(msg.sender, msg.value);
    }

    function transferFromCrowdsaleToUserAdoptionPool() public onlyOwner {
        require(now > endTime);
        
        super.transferRemainingTokensToUserAdoptionPool(super.getTokenAmount(cap) - super.getTokenAmount(weiRaised));
    }
    
      
    function finalization() internal {
        token.finishMinting();
        LuckCashToken(token).unpause();

        wallet.transfer(this.balance);

        super.finalization();
    }

     
    function forwardFunds() internal {
        reportContribution(msg.sender, msg.value);
    }

    function canContributeAmount(address _contributor, uint _amount) internal view returns (bool) {
        uint totalAmount = contributions[_contributor].add(_amount);
        return whitelistRegistry.isAmountAllowed(_contributor, totalAmount);  
    }

    function reportContribution(address _contributor, uint _amount) internal returns (bool) {
       contributions[_contributor] = contributions[_contributor].add(_amount);
    }

}

contract VestingFund is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);

   
  address public beneficiary;
  ERC20Basic public token;

  uint256 public quarters;
  uint256 public start;


  uint256 public released;

   
  function VestingFund(address _beneficiary, uint256 _start, uint256 _quarters, address _token) public {
    
    require(_beneficiary != address(0) && _token != address(0));
    require(_quarters > 0);

    beneficiary = _beneficiary;
    quarters = _quarters;
    start = _start;
    token = ERC20Basic(_token);
  }

   
  function release() public {
    uint256 unreleased = releasableAmount();
    require(unreleased > 0);

    released = released.add(unreleased);
    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function releasableAmount() public view returns(uint256) {
    return vestedAmount().sub(released);
  }

   
  function vestedAmount() public view returns(uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released);

    if (now < start) {
      return 0;
    }

    uint256 dT = now.sub(start);  
    uint256 dQuarters = dT.div(90 days);  

    if (dQuarters >= quarters) {
      return totalBalance;  
    } else {
      return totalBalance.mul(dQuarters).div(quarters);  
    }
  }
}

contract WhiteListRegistry is Ownable {

    mapping (address => WhiteListInfo) public whitelist;
    using SafeMath for uint;

    struct WhiteListInfo {
        bool whiteListed;
        uint minCap;
        uint maxCap;
    }

    event AddedToWhiteList(
        address contributor,
        uint minCap,
        uint maxCap
    );

    event RemovedFromWhiteList(
        address _contributor
    );

    function addToWhiteList(address _contributor, uint _minCap, uint _maxCap) public onlyOwner {
        require(_contributor != address(0));
        whitelist[_contributor] = WhiteListInfo(true, _minCap, _maxCap);
        AddedToWhiteList(_contributor, _minCap, _maxCap);
    }

    function removeFromWhiteList(address _contributor) public onlyOwner {
        require(_contributor != address(0));
        delete whitelist[_contributor];
        RemovedFromWhiteList(_contributor);
    }

    function isWhiteListed(address _contributor) public view returns(bool) {
        return whitelist[_contributor].whiteListed;
    }

    function isAmountAllowed(address _contributor, uint _amount) public view returns(bool) {
       return whitelist[_contributor].maxCap >= _amount && whitelist[_contributor].minCap <= _amount && isWhiteListed(_contributor);
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

contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
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

contract LuckCashToken is PausableToken, CappedToken {
    string public constant name = "LuckCash";
    string public constant symbol = "LCK";
    uint8 public constant decimals = 18;

    function LuckCashToken(uint _cap) public CappedToken(_cap) PausableToken() {

    }
}