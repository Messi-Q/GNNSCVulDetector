pragma solidity 0.4.24;

 

 
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

 

 
contract GolixToken is PausableToken, MintableToken {
    string public constant name = "Golix Token";
    string public constant symbol = "GLX";
    uint8 public constant decimals = 18;

     
    function stakeGLX(address staker, address glxStakingContract) public onlyOwner {
        uint256 stakerGLXBalance = balanceOf(staker);
        balances[staker] = 0;
        balances[glxStakingContract] = balances[glxStakingContract].add(stakerGLXBalance);
        emit Transfer(staker, glxStakingContract, stakerGLXBalance);
    }
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

 

 
contract VestTokenAllocation is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    uint256 public allocatedTokens;
    uint256 public canSelfDestruct;

    mapping (address => uint256) public totalTokensLocked;
    mapping (address => uint256) public releasedTokens;

    ERC20 public golix;
    address public tokenDistribution;

    event Released(address beneficiary, uint256 amount);

     
    function VestTokenAllocation
        (
            ERC20 _token,
            address _tokenDistribution,
            uint256 _start,
            uint256 _cliff,
            uint256 _duration,
            uint256 _canSelfDestruct
        )
        public
    {
        require(_token != address(0) && _cliff != 0);
        require(_cliff <= _duration);
        require(_start > now);
        require(_canSelfDestruct > _duration.add(_start));

        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;

        golix = ERC20(_token);
        tokenDistribution = _tokenDistribution;
        canSelfDestruct = _canSelfDestruct;
    }

    modifier onlyOwnerOrTokenDistributionContract() {
        require(msg.sender == address(owner) || msg.sender == address(tokenDistribution));
        _;
    }
     
    function addVestTokenAllocation(address beneficiary, uint256 allocationValue)
        external
        onlyOwnerOrTokenDistributionContract
    {
        require(totalTokensLocked[beneficiary] == 0 && beneficiary != address(0));  

        allocatedTokens = allocatedTokens.add(allocationValue);
        require(allocatedTokens <= golix.balanceOf(this));

        totalTokensLocked[beneficiary] = allocationValue;
    }

     
    function release() public {
        uint256 unreleased = releasableAmount();

        require(unreleased > 0);

        releasedTokens[msg.sender] = releasedTokens[msg.sender].add(unreleased);

        golix.safeTransfer(msg.sender, unreleased);

        emit Released(msg.sender, unreleased);
    }

     
    function releasableAmount() public view returns (uint256) {
        return vestedAmount().sub(releasedTokens[msg.sender]);
    }

     
    function vestedAmount() public view returns (uint256) {
        uint256 totalBalance = totalTokensLocked[msg.sender];

        if (now < cliff) {
            return 0;
        } else if (now >= start.add(duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(start)).div(duration);
        }
    }

     
    function kill() public onlyOwner {
        require(now >= canSelfDestruct);
        uint256 balance = golix.balanceOf(this);

        if (balance > 0) {
            golix.transfer(msg.sender, balance);
        }

        selfdestruct(owner);
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

 

 
contract GolixTokenDistribution is FinalizableCrowdsale {
    uint256 constant public TOTAL_TOKENS_SUPPLY = 1274240097e18;  
     
    uint256 constant public MARKETING_SHARE = 127424009e18;
     
    uint256 constant public SHAREHOLDERS_SHARE = 191136015e18;
     
    uint256 constant public FOUNDERS_SHARE = 318560024e18;
    uint256 constant public TOTAL_TOKENS_FOR_CROWDSALE = 637120049e18;  

    VestTokenAllocation public teamVestTokenAllocation;
    VestTokenAllocation public contributorsVestTokenAllocation;
    address public marketingWallet;
    address public shareHoldersWallet;

    bool public canFinalizeEarly;
    bool public isStakingPeriod;

    mapping (address => uint256) public icoContributions;

    event MintedTokensFor(address indexed investor, uint256 tokensPurchased);
    event GLXStaked(address indexed staker, uint256 amount);

     
    function GolixTokenDistribution
        (
            uint256 _startTime,
            uint256 _endTime,
            uint256 _rate,
            address _wallet,
            address _marketingWallet,
            address _shareHoldersWallet
        )
        public
        FinalizableCrowdsale()
        Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        require(_marketingWallet != address(0) && _shareHoldersWallet != address(0));
        require(
            MARKETING_SHARE + SHAREHOLDERS_SHARE + FOUNDERS_SHARE + TOTAL_TOKENS_FOR_CROWDSALE
            == TOTAL_TOKENS_SUPPLY
        );

        marketingWallet = _marketingWallet;
        shareHoldersWallet = _shareHoldersWallet;

        GolixToken(token).pause();
    }

     
    function mintTokensForCrowdsaleParticipants(address[] investorsAddress, uint256[] amountOfTokens)
        external
        onlyOwner
    {
        require(investorsAddress.length == amountOfTokens.length);

        for (uint256 i = 0; i < investorsAddress.length; i++) {
            require(token.totalSupply().add(amountOfTokens[i]) <= TOTAL_TOKENS_FOR_CROWDSALE);

            token.mint(investorsAddress[i], amountOfTokens[i]);
            icoContributions[investorsAddress[i]] = icoContributions[investorsAddress[i]].add(amountOfTokens[i]);

            emit MintedTokensFor(investorsAddress[i], amountOfTokens[i]);
        }
    }
    
     
    function buyTokens(address beneficiary) public payable {
        revert();
    }
    
     
    function setVestTokenAllocationAddresses
        (
            address _teamVestTokenAllocation,
            address _contributorsVestTokenAllocation
        )
        public
        onlyOwner
    {
        require(_teamVestTokenAllocation != address(0) && _contributorsVestTokenAllocation != address(0));

        teamVestTokenAllocation = VestTokenAllocation(_teamVestTokenAllocation);
        contributorsVestTokenAllocation = VestTokenAllocation(_contributorsVestTokenAllocation);
    }

     
     
    function hasEnded() public view returns (bool) {
        if (canFinalizeEarly) {
            return true;
        }

        return super.hasEnded();
    }

     
    function stakeGLXForContributors() public {
        uint256 senderGlxBalance = token.balanceOf(msg.sender);
        require(senderGlxBalance == icoContributions[msg.sender] && isStakingPeriod);

        GolixToken(token).stakeGLX(msg.sender, contributorsVestTokenAllocation);
        contributorsVestTokenAllocation.addVestTokenAllocation(msg.sender, senderGlxBalance);
        emit GLXStaked(msg.sender, senderGlxBalance);
    }

     
    function prepareForEarlyFinalization() public onlyOwner {
        canFinalizeEarly = true;
    }

     
    function disableStakingPeriod() public onlyOwner {
        isStakingPeriod = false;
    }

     
    function createTokenContract() internal returns (MintableToken) {
        return new GolixToken();
    }

     
    function finalization() internal {
         
        require(teamVestTokenAllocation != address(0) && contributorsVestTokenAllocation != address(0));

        if (TOTAL_TOKENS_FOR_CROWDSALE > token.totalSupply()) {
            uint256 remainingTokens = TOTAL_TOKENS_FOR_CROWDSALE.sub(token.totalSupply());
            token.mint(contributorsVestTokenAllocation, remainingTokens);
            isStakingPeriod = true;
        }

         
        token.mint(marketingWallet, MARKETING_SHARE);
        token.mint(shareHoldersWallet, SHAREHOLDERS_SHARE);
        token.mint(teamVestTokenAllocation, FOUNDERS_SHARE);

        token.finishMinting();
        GolixToken(token).unpause();
        super.finalization();
    }
}