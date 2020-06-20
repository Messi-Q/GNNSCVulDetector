pragma solidity ^0.4.18;

 
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

contract MultiOwnable {

    mapping (address => bool) public isOwner;
    address[] public ownerHistory;
    uint8 public ownerCount;

    event OwnerAddedEvent(address indexed _newOwner);
    event OwnerRemovedEvent(address indexed _oldOwner);

    function MultiOwnable() public {
         
        address owner = msg.sender;
        ownerHistory.push(owner);
        isOwner[owner] = true;
        ownerCount++;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }
    
    function ownerHistoryCount() public view returns (uint) {
        return ownerHistory.length;
    }

     
    function addOwner(address owner) onlyOwner public {
        require(owner != address(0));
        require(!isOwner[owner]);
        ownerHistory.push(owner);
        isOwner[owner] = true;
        ownerCount++;
        OwnerAddedEvent(owner);
    }

     
    function removeOwner(address owner) onlyOwner public {
        
         
         
         
        require(ownerCount > 1);
        
        require(isOwner[owner]);
        isOwner[owner] = false;
        ownerCount--;
        OwnerRemovedEvent(owner);
    }
}

contract Pausable is Ownable {

    bool public paused;

    modifier ifNotPaused {
        require(!paused);
        _;
    }

    modifier ifPaused {
        require(paused);
        _;
    }

     
    function pause() external onlyOwner ifNotPaused {
        paused = true;
    }

     
    function resume() external onlyOwner ifPaused {
        paused = false;
    }
}

contract ERC20 {

    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is ERC20 {
    
    using SafeMath for uint;

    mapping(address => uint256) balances;
    
    mapping(address => mapping(address => uint256)) allowed;

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        
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

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract CommonToken is StandardToken, MultiOwnable {

    string public constant name   = 'White Rabbit Token';
    string public constant symbol = 'WRT';
    uint8 public constant decimals = 18;
    
     
    address public seller;
    
     
     
     
    uint256 public constant saleLimit = 110200000 ether;
    
     
    uint256 public tokensSold;  
    uint256 public totalSales;  

     
    bool public locked = true;

    event SellEvent(address indexed _seller, address indexed _buyer, uint256 _value);
    event ChangeSellerEvent(address indexed _oldSeller, address indexed _newSeller);
    event Burn(address indexed _burner, uint256 _value);
    event Unlock();

    function CommonToken(
        address _seller
    ) MultiOwnable() public {

        require(_seller != 0);
        seller = _seller;

        totalSupply = 190000000 ether;
        balances[seller] = totalSupply;
        Transfer(0x0, seller, totalSupply);
    }
    
    modifier ifUnlocked() {
        require(isOwner[msg.sender] || !locked);
        _;
    }

     
    function changeSeller(address newSeller) onlyOwner public returns (bool) {
        require(newSeller != address(0));
        require(seller != newSeller);
        
         
        require(balances[newSeller] == 0);

        address oldSeller = seller;
        uint256 unsoldTokens = balances[oldSeller];
        balances[oldSeller] = 0;
        balances[newSeller] = unsoldTokens;
        Transfer(oldSeller, newSeller, unsoldTokens);

        seller = newSeller;
        ChangeSellerEvent(oldSeller, newSeller);
        return true;
    }

     
    function sellNoDecimals(address _to, uint256 _value) public returns (bool) {
        return sell(_to, _value * 1e18);
    }

    function sell(address _to, uint256 _value) onlyOwner public returns (bool) {

         
        if (saleLimit > 0) require(tokensSold.add(_value) <= saleLimit);

        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[seller]);

        balances[seller] = balances[seller].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(seller, _to, _value);

        totalSales++;
        tokensSold = tokensSold.add(_value);
        SellEvent(seller, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) ifUnlocked public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) ifUnlocked public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function burn(uint256 _value) public returns (bool) {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Transfer(msg.sender, 0x0, _value);
        Burn(msg.sender, _value);
        return true;
    }
    
     
    function unlock() onlyOwner public {
        require(locked);
        locked = false;
        Unlock();
    }
}

 
contract CommonWhitelist is MultiOwnable {

    mapping(address => bool) public isAllowed;
    
     
     
     
    address[] public history;

    event AddedEvent(address indexed wallet);
    event RemovedEvent(address indexed wallet);

    function CommonWhitelist() MultiOwnable() public {}

    function historyCount() public view returns (uint) {
        return history.length;
    }
    
    function add(address _wallet) internal {
        require(_wallet != address(0));
        require(!isAllowed[_wallet]);

        history.push(_wallet);
        isAllowed[_wallet] = true;
        AddedEvent(_wallet);
    }

    function addMany(address[] _wallets) public onlyOwner {
        for (uint i = 0; i < _wallets.length; i++) {
            add(_wallets[i]);
        }
    }

    function remove(address _wallet) internal {
        require(isAllowed[_wallet]);
        
        isAllowed[_wallet] = false;
        RemovedEvent(_wallet);
    }

    function removeMany(address[] _wallets) public onlyOwner {
        for (uint i = 0; i < _wallets.length; i++) {
            remove(_wallets[i]);
        }
    }
}

 
 
 
 

contract HasManager {
  address public manager;

  modifier onlyManager {
    require(msg.sender == manager);
    _;
  }

  function transferManager(address _newManager) public onlyManager() {
    require(_newManager != address(0));
    manager = _newManager;
  }
}

 
contract ICrowdsaleProcessor is Ownable, HasManager {
  modifier whenCrowdsaleAlive() {
    require(isActive());
    _;
  }

  modifier whenCrowdsaleFailed() {
    require(isFailed());
    _;
  }

  modifier whenCrowdsaleSuccessful() {
    require(isSuccessful());
    _;
  }

  modifier hasntStopped() {
    require(!stopped);
    _;
  }

  modifier hasBeenStopped() {
    require(stopped);
    _;
  }

  modifier hasntStarted() {
    require(!started);
    _;
  }

  modifier hasBeenStarted() {
    require(started);
    _;
  }

   
  uint256 constant public MIN_HARD_CAP = 1 ether;

   
  uint256 constant public MIN_CROWDSALE_TIME = 3 days;

   
  uint256 constant public MAX_CROWDSALE_TIME = 50 days;

   
  bool public started;

   
  bool public stopped;

   
  uint256 public totalCollected;

   
  uint256 public totalSold;

   
  uint256 public minimalGoal;

   
  uint256 public hardCap;

   
   
  uint256 public duration;

   
  uint256 public startTimestamp;

   
  uint256 public endTimestamp;

   
  function deposit() public payable {}

   
  function getToken() public returns(address);

   
  function mintETHRewards(address _contract, uint256 _amount) public onlyManager();

   
  function mintTokenRewards(address _contract, uint256 _amount) public onlyManager();

   
  function releaseTokens() public onlyManager() hasntStopped() whenCrowdsaleSuccessful();

   
   
  function stop() public onlyManager() hasntStopped();

   
  function start(uint256 _startTimestamp, uint256 _endTimestamp, address _fundingAddress)
    public onlyManager() hasntStarted() hasntStopped();

   
  function isFailed() public constant returns (bool);

   
  function isActive() public constant returns (bool);

   
  function isSuccessful() public constant returns (bool);
}

 
contract BasicCrowdsale is ICrowdsaleProcessor {
  event CROWDSALE_START(uint256 startTimestamp, uint256 endTimestamp, address fundingAddress);

   
  address public fundingAddress;

   
  function BasicCrowdsale(
    address _owner,
    address _manager
  )
    public
  {
    owner = _owner;
    manager = _manager;
  }

   
   
   
   
  function mintETHRewards(
    address _contract,   
    uint256 _amount      
  )
    public
    onlyManager()  
  {
    require(_contract.call.value(_amount)());
  }

   
  function stop() public onlyManager() hasntStopped()  {
     
    if (started) {
      require(!isFailed());
      require(!isSuccessful());
    }
    stopped = true;
  }

   
   
  function start(
    uint256 _startTimestamp,
    uint256 _endTimestamp,
    address _fundingAddress
  )
    public
    onlyManager()    
    hasntStarted()   
    hasntStopped()   
  {
    require(_fundingAddress != address(0));

     
    require(_startTimestamp >= block.timestamp);

     
    require(_endTimestamp > _startTimestamp);
    duration = _endTimestamp - _startTimestamp;

     
    require(duration >= MIN_CROWDSALE_TIME && duration <= MAX_CROWDSALE_TIME);

    startTimestamp = _startTimestamp;
    endTimestamp = _endTimestamp;
    fundingAddress = _fundingAddress;

     
    started = true;

    CROWDSALE_START(_startTimestamp, _endTimestamp, _fundingAddress);
  }

   
  function isFailed()
    public
    constant
    returns(bool)
  {
    return (
       
      started &&

       
      block.timestamp >= endTimestamp &&

       
      totalCollected < minimalGoal
    );
  }

   
  function isActive()
    public
    constant
    returns(bool)
  {
    return (
       
      started &&

       
      totalCollected < hardCap &&

       
      block.timestamp >= startTimestamp &&
      block.timestamp < endTimestamp
    );
  }

   
  function isSuccessful()
    public
    constant
    returns(bool)
  {
    return (
       
      totalCollected >= hardCap ||

       
      (block.timestamp >= endTimestamp && totalCollected >= minimalGoal)
    );
  }
}

 
contract IWingsController {
  uint256 public ethRewardPart;
  uint256 public tokenRewardPart;
}

 
contract Bridge is BasicCrowdsale {
  using SafeMath for uint256;

  modifier onlyCrowdsale() {
    require(msg.sender == crowdsaleAddress);
    _;
  }

   
  StandardToken token;

   
  address public crowdsaleAddress;

   
  bool public completed;

   
   
  function Bridge(
    uint256 _minimalGoal,
    uint256 _hardCap,
    address _token,
    address _crowdsaleAddress
  )
    public
     
     
    BasicCrowdsale(msg.sender, msg.sender)
  {
     
    minimalGoal = _minimalGoal;
    hardCap = _hardCap;
    crowdsaleAddress = _crowdsaleAddress;
    token = StandardToken(_token);
  }

 

   
  function getToken()
    public
    returns(address)
  {
    return address(token);
  }

   
   
   
  function mintTokenRewards(
    address _contract,   
    uint256 _amount      
  )
    public
    onlyManager()  
  {
     
    token.transfer(_contract, _amount);
  }

   
  function releaseTokens()
    public
    onlyManager()              
    hasntStopped()             
    whenCrowdsaleSuccessful()  
  {
     
  }

 

   
  function () payable public {
  }

  function notifySale(uint256 _ethAmount, uint256 _tokensAmount) public
    hasBeenStarted()      
    hasntStopped()        
    whenCrowdsaleAlive()  
    onlyCrowdsale()  
  {
    totalCollected = totalCollected.add(_ethAmount);
    totalSold = totalSold.add(_tokensAmount);
  }

   
  function finish() public
    hasntStopped()
    hasBeenStarted()
    whenCrowdsaleAlive()
    onlyCrowdsale()
  {
    completed = true;
  }

   
  function withdraw(
    uint256 _amount  
  )
    public
    onlyOwner()  
    hasntStopped()   
    whenCrowdsaleSuccessful()  
  {
     
  }

   
  function refund()
    public
  {
     
  }

   
  function isFailed()
    public
    constant
    returns(bool)
  {
    return (
      false
    );
  }

   
  function isActive()
    public
    constant
    returns(bool)
  {
    return (
       
      started && !completed
    );
  }

   
  function isSuccessful()
    public
    constant
    returns(bool)
  {
    return (
      completed
    );
  }

  function calculateRewards() public view returns(uint256,uint256) {
    uint256 tokenRewardPart = IWingsController(manager).tokenRewardPart();
    uint256 ethRewardPart = IWingsController(manager).ethRewardPart();

    uint256 tokenReward = totalSold.mul(tokenRewardPart) / 1000000;
    bool hasEthReward = (ethRewardPart != 0);

    uint256 ethReward = 0;
    if (hasEthReward) {
        ethReward = totalCollected.mul(ethRewardPart) / 1000000;
    }

    return (ethReward, tokenReward);
  }
}

contract Connector is Ownable {
  modifier bridgeInitialized() {
    require(address(bridge) != address(0x0));
    _;
  }

  Bridge public bridge;

  function changeBridge(address _bridge) public onlyOwner {
    require(_bridge != address(0x0));
    bridge = Bridge(_bridge);
  }

  function notifySale(uint256 _ethAmount, uint256 _tokenAmount) internal bridgeInitialized {
    bridge.notifySale(_ethAmount, _tokenAmount);
  }

  function closeBridge() internal bridgeInitialized {
    bridge.finish();
  }
}

 
 

contract CommonTokensale is Connector, Pausable {
    
    using SafeMath for uint;
    
    CommonToken public token;          
    CommonWhitelist public whitelist;  
    
    address public beneficiary;        
    address public bsWallet = 0x8D5bd2aBa04A07Bfa0cc976C73eD45B23cC6D6a2;
    
    bool public whitelistEnabled = true;

    uint public minPaymentWei;
    uint public defaultTokensPerWei;

    uint public minCapWei;
    uint public maxCapWei;

    uint public startTime;
    uint public endTime;

     
    
    uint public totalTokensSold;   
    uint public totalWeiReceived;  
    
     
    mapping (address => uint256) public buyerToSentWei;
    
    mapping (bytes32 => bool) public calledOnce;

    event ChangeBeneficiaryEvent(address indexed _oldAddress, address indexed _newAddress);
    event ChangeWhitelistEvent(address indexed _oldAddress, address indexed _newAddress);
    event ReceiveEthEvent(address indexed _buyer, uint256 _amountWei);

    function CommonTokensale(
        address _token,
        address _whitelist,
        address _beneficiary
    ) public Connector() {
        require(_token != 0);
        require(_whitelist != 0);
        require(_beneficiary != 0);

        token = CommonToken(_token);
        whitelist = CommonWhitelist(_whitelist);
        beneficiary = _beneficiary;
    }
    
    modifier canBeCalledOnce(bytes32 _flag) {
        require(!calledOnce[_flag]);
        calledOnce[_flag] = true;
        _;
    }
    
     
    function updateMinCapEthOnce(uint _newValue) public onlyOwner canBeCalledOnce("updateMinCapEth") {
        minCapWei = _newValue * 1e18;
    }
    
     
    function updateMaxCapEthOnce(uint _newValue) public onlyOwner canBeCalledOnce("updateMaxCapEth") {
        maxCapWei = _newValue * 1e18;
    }

    function updateTokensPerEthOnce(uint _newValue) public onlyOwner canBeCalledOnce("updateTokensPerEth") {
        defaultTokensPerWei = _newValue;
        recalcBonuses();
    }
    
    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != 0);
        ChangeBeneficiaryEvent(beneficiary, _beneficiary);
        beneficiary = _beneficiary;
    }
    
    function setWhitelist(address _whitelist) public onlyOwner {
        require(_whitelist != 0);
        ChangeWhitelistEvent(whitelist, _whitelist);
        whitelist = CommonWhitelist(_whitelist);
    }
    
    function setWhitelistEnabled(bool _enabled) public onlyOwner {
        whitelistEnabled = _enabled;
    }

     
    function() public payable {
        sellTokensForEth(msg.sender, msg.value);
    }

    function sellTokensForEth(
        address _buyer, 
        uint256 _amountWei
    ) ifNotPaused internal {
        
         
        if (whitelistEnabled) require(whitelist.isAllowed(_buyer));
        
        require(startTime <= now && now <= endTime);
        require(_amountWei >= minPaymentWei);
        require(totalWeiReceived < maxCapWei);
        
        uint256 newTotalReceived = totalWeiReceived.add(_amountWei);
        
         
        if (newTotalReceived > maxCapWei) {
            uint refundWei = newTotalReceived.sub(maxCapWei);
             
            _buyer.transfer(refundWei);
            _amountWei = _amountWei.sub(refundWei);
        }

        uint tokensE18 = weiToTokens(_amountWei);
         
        token.sell(_buyer, tokensE18);
        
         
        totalTokensSold = totalTokensSold.add(tokensE18);
        totalWeiReceived = totalWeiReceived.add(_amountWei);
        buyerToSentWei[_buyer] = buyerToSentWei[_buyer].add(_amountWei);
        ReceiveEthEvent(_buyer, _amountWei);
        
         
        uint bsTokens = totalTokensSold.mul(75).div(10000);
        token.sell(bsWallet, bsTokens);
        
         
        notifySale(_amountWei, tokensE18);
    }
    
    function amountPercentage(uint _amount, uint _per) public pure returns (uint) {
        return _amount.mul(_per).div(100);
    }
    
    function tokensPerWeiPlusBonus(uint _per) public view returns (uint) {
        return defaultTokensPerWei.add(
            amountPercentage(defaultTokensPerWei, _per)
        );
    }
    
     
    function weiToTokens(uint _amountWei) public view returns (uint) {
        return _amountWei.mul(tokensPerWei(_amountWei));
    }
    
    function recalcBonuses() internal;
    
    function tokensPerWei(uint _amountWei) public view returns (uint256);
    
    function isFinishedSuccessfully() public view returns (bool) {
        return now >= endTime && totalWeiReceived >= minCapWei;
    }
    
    function canWithdraw() public view returns (bool);
    
     
    function withdraw(address _to, uint256 _amount) public {
        require(canWithdraw());
        require(msg.sender == beneficiary);
        require(_amount <= this.balance);
        
        _to.transfer(_amount);
    }

    function withdraw(address _to) public {
        withdraw(_to, this.balance);
    }
    
     
    function deposit() public payable {
        require(isFinishedSuccessfully());
    }
  
     
    function sendWingsRewardsOnce() public onlyOwner canBeCalledOnce("sendWingsRewards") {
        require(isFinishedSuccessfully());
        
        uint256 ethReward = 0;
        uint256 tokenReward = 0;
        
        (ethReward, tokenReward) = bridge.calculateRewards();
        
        if (ethReward > 0) {
            bridge.transfer(ethReward);
        }
        
        if (tokenReward > 0) {
            token.sell(bridge, tokenReward);
        }
        
         
        closeBridge();
    }
}

contract Presale is CommonTokensale {
    
    uint public tokensPerWei10;
    uint public tokensPerWei15;
    uint public tokensPerWei20;
    
    function Presale(
        address _token,
        address _whitelist,
        address _beneficiary
    ) CommonTokensale(
        _token,
        _whitelist,
        _beneficiary
    ) public {
        minCapWei = 0 ether;        
        maxCapWei = 8000 ether;    

        startTime = 1524765600;     
        endTime   = 1526306400;     
        
        minPaymentWei = 5 ether;    
        defaultTokensPerWei = 4808;  
        recalcBonuses();
    }
    
    function recalcBonuses() internal {
        tokensPerWei10 = tokensPerWeiPlusBonus(10);
        tokensPerWei15 = tokensPerWeiPlusBonus(15);
        tokensPerWei20 = tokensPerWeiPlusBonus(20);
    }
    
    function tokensPerWei(uint _amountWei) public view returns (uint256) {
        if (5 ether <= _amountWei && _amountWei < 10 ether) return tokensPerWei10;
        if (_amountWei < 20 ether) return tokensPerWei15;
        if (20 ether <= _amountWei) return tokensPerWei20;
        return defaultTokensPerWei;
    }

     
    function canWithdraw() public view returns (bool) {
        return true;
    }
}

 
contract PublicSale is CommonTokensale {
    
    uint public tokensPerWei5;
    uint public tokensPerWei7;
    uint public tokensPerWei10;
    
     
     
    uint public refundDeadlineTime;

     
    uint public totalWeiRefunded;
    
    event RefundEthEvent(address indexed _buyer, uint256 _amountWei);
    
    function PublicSale(
        address _token,
        address _whitelist,
        address _beneficiary
    ) CommonTokensale(
        _token,
        _whitelist,
        _beneficiary
    ) public {
        minCapWei =  3200 ether;     
        maxCapWei = 16000 ether;     
        
        startTime = 1526392800;      
        endTime   = 1528639200;      
        refundDeadlineTime = endTime + 30 days;
        
        minPaymentWei = 0.05 ether;  
        defaultTokensPerWei = 4808;   
        recalcBonuses();
    }
    
    function recalcBonuses() internal {
        tokensPerWei5  = tokensPerWeiPlusBonus(5);
        tokensPerWei7  = tokensPerWeiPlusBonus(7);
        tokensPerWei10 = tokensPerWeiPlusBonus(10);
    }
    
    function tokensPerWei(uint _amountWei) public view returns (uint256) {
        if (0.05 ether <= _amountWei && _amountWei < 10 ether) return tokensPerWei5;
        if (_amountWei < 20 ether) return tokensPerWei7;
        if (20 ether <= _amountWei) return tokensPerWei10;
        return defaultTokensPerWei;
    }

     
    function canWithdraw() public view returns (bool) {
        return totalWeiReceived >= minCapWei || now > refundDeadlineTime;
    }
    
     
    function canRefund() public view returns (bool) {
        return totalWeiReceived < minCapWei && endTime < now && now <= refundDeadlineTime;
    }

     
    function refund() public {
        require(canRefund());
        
        address buyer = msg.sender;
        uint amount = buyerToSentWei[buyer];
        require(amount > 0);
        
        RefundEthEvent(buyer, amount);
        buyerToSentWei[buyer] = 0;
        totalWeiRefunded = totalWeiRefunded.add(amount);
        buyer.transfer(amount);
    }
}


 
 

     
     
     
     
     
     
     
     
     
     

 
 


 
 
contract ProdPublicSale is PublicSale {
    function ProdPublicSale() PublicSale(
        0x123,  
        0x123,  
        0x123   
    ) public {}
}