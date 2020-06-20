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

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
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

contract Cloudbric is StandardToken, BurnableToken, Ownable {
    using SafeMath for uint256;

    string public constant symbol = "CLB";
    string public constant name = "Cloudbric";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
    uint256 public constant TOKEN_SALE_ALLOWANCE = 540000000 * (10 ** uint256(decimals));
    uint256 public constant ADMIN_ALLOWANCE = INITIAL_SUPPLY - TOKEN_SALE_ALLOWANCE;

     
    address public adminAddr;

     
    address public tokenSaleAddr;

     
    bool public transferEnabled = false;

     
    mapping(address => uint256) private lockedAccounts;

     

     
    modifier onlyWhenTransferAllowed() {
        require(transferEnabled == true
            || msg.sender == adminAddr
            || msg.sender == tokenSaleAddr);
        _;
    }

     
    modifier onlyWhenTokenSaleAddrNotSet() {
        require(tokenSaleAddr == address(0x0));
        _;
    }

     
    modifier onlyValidDestination(address to) {
        require(to != address(0x0)
            && to != address(this)
            && to != owner
            && to != adminAddr
            && to != tokenSaleAddr);
        _;
    }

    modifier onlyAllowedAmount(address from, uint256 amount) {
        require(balances[from].sub(amount) >= lockedAccounts[from]);
        _;
    }
     
    function Cloudbric(address _adminAddr) public {
        totalSupply_ = INITIAL_SUPPLY;

        balances[msg.sender] = totalSupply_;
        Transfer(address(0x0), msg.sender, totalSupply_);

        adminAddr = _adminAddr;
        approve(adminAddr, ADMIN_ALLOWANCE);
    }

     
    function setTokenSaleAmount(address _tokenSaleAddr, uint256 amountForSale)
        external
        onlyOwner
        onlyWhenTokenSaleAddrNotSet
    {
        require(!transferEnabled);

        uint256 amount = (amountForSale == 0) ? TOKEN_SALE_ALLOWANCE : amountForSale;
        require(amount <= TOKEN_SALE_ALLOWANCE);

        approve(_tokenSaleAddr, amount);
        tokenSaleAddr = _tokenSaleAddr;
    }

     
    function enableTransfer() external onlyOwner {
        transferEnabled = true;
        approve(tokenSaleAddr, 0);
    }

     
    function disableTransfer() external onlyOwner {
        transferEnabled = false;
    }

     
    function transfer(address to, uint256 value)
        public
        onlyWhenTransferAllowed
        onlyValidDestination(to)
        onlyAllowedAmount(msg.sender, value)
        returns (bool)
    {
        return super.transfer(to, value);
    }

     
    function transferFrom(address from, address to, uint256 value)
        public
        onlyWhenTransferAllowed
        onlyValidDestination(to)
        onlyAllowedAmount(from, value)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

     
    function burn(uint256 value) public onlyOwner {
        require(transferEnabled);
        super.burn(value);
    }

     
    function lockAccount(address addr, uint256 amount)
        external
        onlyOwner
        onlyValidDestination(addr)
    {
        require(amount > 0);
        lockedAccounts[addr] = amount;
    }

     

    function unlockAccount(address addr)
        external
        onlyOwner
        onlyValidDestination(addr)
    {
        lockedAccounts[addr] = 0;
    }
}

contract CloudbricSale is Pausable {
    using SafeMath for uint256;

     
    uint256 public startTime;
     
    uint256 public endTime;
     
    address private fundAddr;
     
    Cloudbric public token;
     
    uint256 public totalWeiRaised;
     
    uint256 public constant BASE_HARD_CAP_PER_ROUND = 20000 * 1 ether;

    uint256 public constant UINT256_MAX = ~uint256(0);
     
    uint256 public constant BASE_CLB_TO_ETH_RATE = 10000;
     
    uint256 public constant BASE_MIN_CONTRIBUTION = 0.1 * 1 ether;
     
    mapping(address => bool) public whitelist;
     
    mapping(address => mapping(uint8 => uint256)) public contPerRound;

     
    enum Stages {
        SetUp,
        Started,
        Ended
    }
     
    Stages public stage;

     
    enum SaleRounds {
        EarlyInvestment,
        PreSale1,
        PreSale2,
        CrowdSale
    }
     
    SaleRounds public round;

     
    struct RoundInfo {
        uint256 minContribution;
        uint256 maxContribution;
        uint256 hardCap;
        uint256 rate;
        uint256 weiRaised;
    }

     
     
    mapping(uint8 => RoundInfo) public roundInfos;

    struct AllocationInfo {
        bool isAllowed;
        uint256 allowedAmount;
    }

     
    mapping(address => AllocationInfo) private allocationList;

     
    event SaleStarted(uint256 startTime, uint256 endTime, SaleRounds round);

     
    event SaleEnded(uint256 endTime, uint256 totalWeiRaised, SaleRounds round);

     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

     
    modifier atStage(Stages expectedStage) {
        require(stage == expectedStage);
        _;
    }

     
    modifier atRound(SaleRounds expectedRound) {
        require(round == expectedRound);
        _;
    }

     
    modifier onlyValidPurchase() {
        require(round <= SaleRounds.CrowdSale);
        require(now >= startTime && now <= endTime);

        uint256 contributionInWei = msg.value;
        address purchaser = msg.sender;

        require(whitelist[purchaser]);
        require(purchaser != address(0));
        require(contributionInWei >= roundInfos[uint8(round)].minContribution);
        require(
            contPerRound[purchaser][uint8(round)].add(contributionInWei)
            <= roundInfos[uint8(round)].maxContribution
        );
        require(
            roundInfos[uint8(round)].weiRaised.add(contributionInWei)
            <= roundInfos[uint8(round)].hardCap
        );
        _;
    }

     
    function CloudbricSale(
        address fundAddress,
        address tokenAddress
    )
        public
    {
        require(fundAddress != address(0));
        require(tokenAddress != address(0));

        token = Cloudbric(tokenAddress);
        fundAddr = fundAddress;
        stage = Stages.Ended;
        round = SaleRounds.EarlyInvestment;
        uint8 roundIndex = uint8(round);

        roundInfos[roundIndex].minContribution = BASE_MIN_CONTRIBUTION;
        roundInfos[roundIndex].maxContribution = UINT256_MAX;
        roundInfos[roundIndex].hardCap = BASE_HARD_CAP_PER_ROUND;
        roundInfos[roundIndex].weiRaised = 0;
        roundInfos[roundIndex].rate = BASE_CLB_TO_ETH_RATE;
    }

     
    function () public payable {
        buy();
    }

     
    function withdraw() external onlyOwner {
        fundAddr.transfer(this.balance);
    }

     
    function addManyToWhitelist(address[] users) external onlyOwner {
        for (uint32 i = 0; i < users.length; i++) {
            addToWhitelist(users[i]);
        }
    }

     
    function addToWhitelist(address user) public onlyOwner {
        whitelist[user] = true;
    }

     
    function removeManyFromWhitelist(address[] users) external onlyOwner {
        for (uint32 i = 0; i < users.length; i++) {
            removeFromWhitelist(users[i]);
        }
    }

     
    function removeFromWhitelist(address user) public onlyOwner {
        whitelist[user] = false;
    }

     
    function setMinContributionForRound(
        SaleRounds _round,
        uint256 _minContribution
    )
        public
        onlyOwner
        atStage(Stages.SetUp)
    {
        require(round <= _round);
        roundInfos[uint8(_round)].minContribution =
            (_minContribution == 0) ? BASE_MIN_CONTRIBUTION : _minContribution;
    }

     
    function setMaxContributionForRound(
        SaleRounds _round,
        uint256 _maxContribution
    )
        public
        onlyOwner
        atStage(Stages.SetUp)
    {
        require(round <= _round);
        roundInfos[uint8(_round)].maxContribution =
            (_maxContribution == 0) ? UINT256_MAX : _maxContribution;
    }

     
    function setHardCapForRound(
        SaleRounds _round,
        uint256 _hardCap
    )
        public
        onlyOwner
        atStage(Stages.SetUp)
    {
        require(round <= _round);
        roundInfos[uint8(_round)].hardCap =
            (_hardCap == 0) ? BASE_HARD_CAP_PER_ROUND : _hardCap;
    }

     
    function setRateForRound(
        SaleRounds _round,
        uint256 _rate
    )
        public
        onlyOwner
        atStage(Stages.SetUp)
    {
        require(round <= _round);
        roundInfos[uint8(_round)].rate =
            (_rate == 0) ? BASE_CLB_TO_ETH_RATE : _rate;
    }

     
    function setUpSale(
        SaleRounds _round,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _hardCap,
        uint256 _rate
    )
        external
        onlyOwner
        atStage(Stages.Ended)
    {
        require(round <= _round);
        stage = Stages.SetUp;
        round = _round;
        setMinContributionForRound(_round, _minContribution);
        setMaxContributionForRound(_round, _maxContribution);
        setHardCapForRound(_round, _hardCap);
        setRateForRound(_round, _rate);
    }

     
    function startSale(uint256 durationInSeconds)
        external
        onlyOwner
        atStage(Stages.SetUp)
    {
        require(roundInfos[uint8(round)].minContribution > 0
            && roundInfos[uint8(round)].hardCap > 0);
        stage = Stages.Started;
        startTime = now;
        endTime = startTime.add(durationInSeconds);
        SaleStarted(startTime, endTime, round);
    }

     
    function endSale() external onlyOwner atStage(Stages.Started) {
        endTime = now;
        stage = Stages.Ended;

        SaleEnded(endTime, totalWeiRaised, round);
    }

    function buy()
        public
        payable
        whenNotPaused
        atStage(Stages.Started)
        onlyValidPurchase()
        returns (bool)
    {
        address purchaser = msg.sender;
        uint256 contributionInWei = msg.value;
        uint256 tokenAmount = contributionInWei.mul(roundInfos[uint8(round)].rate);

        if (!token.transferFrom(token.owner(), purchaser, tokenAmount)) {
            revert();
        }

        totalWeiRaised = totalWeiRaised.add(contributionInWei);
        roundInfos[uint8(round)].weiRaised =
            roundInfos[uint8(round)].weiRaised.add(contributionInWei);

        contPerRound[purchaser][uint8(round)] =
            contPerRound[purchaser][uint8(round)].add(contributionInWei);

         
        fundAddr.transfer(contributionInWei);
        TokenPurchase(msg.sender, contributionInWei, tokenAmount);

        return true;
    }

     
    function addToAllocationList(address user, uint256 amount)
        public
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
    {
        allocationList[user].isAllowed = true;
        allocationList[user].allowedAmount = amount;
    }

     
    function addManyToAllocationList(address[] users, uint256[] amounts)
        external
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
    {
        require(users.length == amounts.length);

        for (uint32 i = 0; i < users.length; i++) {
            addToAllocationList(users[i], amounts[i]);
        }
    }

     
    function removeFromAllocationList(address user)
        public
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
    {
        allocationList[user].isAllowed = false;
    }

     
    function removeManyFromAllocationList(address[] users)
        external
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
    {
        for (uint32 i = 0; i < users.length; i++) {
            removeFromAllocationList(users[i]);
        }
    }


     
    function allocateTokens(address to, uint256 tokenAmount)
        public
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
        returns (bool)
    {
        require(allocationList[to].isAllowed
            && tokenAmount <= allocationList[to].allowedAmount);

        if (!token.transferFrom(token.owner(), to, tokenAmount)) {
            revert();
        }
        return true;
    }

     
    function allocateTokensToMany(address[] toList, uint256[] tokenAmountList)
        external
        onlyOwner
        atRound(SaleRounds.EarlyInvestment)
        returns (bool)
    {
        require(toList.length == tokenAmountList.length);

        for (uint32 i = 0; i < toList.length; i++) {
            allocateTokens(toList[i], tokenAmountList[i]);
        }
        return true;
    }
}