pragma solidity ^0.4.18;

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

contract Ownable {

  address public owner;
  function Ownable() public { owner = msg.sender; }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {owner = newOwner;}
}contract IERC20 {

  function totalSupply() public constant returns (uint256);

  function balanceOf(address _owner) public constant returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);

  function allowance(address _owner, address _spender) public constant returns (uint256);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

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






library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract SmartOToken is Ownable, IERC20 {

  using SafeMath for uint256;

   
  string public constant name = "STO";
  string public constant symbol = "STO";
  uint public constant decimals = 18;
  uint256 public constant initialSupply = 12000000000 * 1 ether;
  uint256 public totalSupply;

   
  mapping (address => uint256) public balances;
  mapping (address => mapping (address => uint256)) public allowed;

   
  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);

   
  function SmartOToken() public {
      balances[msg.sender] = initialSupply;               
      totalSupply = initialSupply;                         
  }


   

  function totalSupply() public constant returns (uint256) { return totalSupply; }

  function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }

   
  function _transfer(address _from, address _to, uint _amount) internal {
      require (_to != 0x0);                                
      require (balances[_from] >= _amount);                 
      balances[_from] = balances[_from].sub(_amount);
      balances[_to] = balances[_to].add(_amount);
      Transfer(_from, _to, _amount);

  }

  function transfer(address _to, uint256 _amount) public returns (bool) {
    _transfer(msg.sender, _to, _amount);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require (_value <= allowed[_from][msg.sender]);      
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _amount) public returns (bool) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256) {
    return allowed[_owner][_spender];
  }

}

 
contract SmatrOCrowdsale is BasicCrowdsale {
   
  mapping(address => uint256) participants;

   
  uint256 tokensPerEthPrice;

   
  SmartOToken crowdsaleToken;

   
   
  function SmatrOCrowdsale(
    uint256 _minimalGoal,
    uint256 _hardCap,
    uint256 _tokensPerEthPrice,
    address _token
  )
    public
     
     
    BasicCrowdsale(msg.sender, msg.sender)
  {
     
    minimalGoal = _minimalGoal;
    hardCap = _hardCap;
    tokensPerEthPrice = _tokensPerEthPrice;
    crowdsaleToken = SmartOToken(_token);
  }

 

   
  function getToken()
    public
    returns(address)
  {
    return address(crowdsaleToken);
  }

   
   
   
  function mintTokenRewards(
    address _contract,   
    uint256 _amount      
  )
    public
    onlyManager()  
  {
     
    crowdsaleToken.transfer(_contract, _amount);
  }

   
  function releaseTokens()
    public
    onlyManager()              
    hasntStopped()             
    whenCrowdsaleSuccessful()  
  {
     
  }

 

  function setRate(uint256 _tokensPerEthPrice)
    public
    onlyOwner
  {
    tokensPerEthPrice = _tokensPerEthPrice;
  }

   
  function () payable public {
    require(msg.value >= 0.1 * 1 ether);

     
    sellTokens(msg.sender, msg.value);
  }

   
  function sellTokens(address _recepient, uint256 _value)
    internal
    hasBeenStarted()      
    hasntStopped()        
    whenCrowdsaleAlive()  
  {
    uint256 newTotalCollected = totalCollected + _value;

    if (hardCap < newTotalCollected) {
       

      uint256 refund = newTotalCollected - hardCap;
      uint256 diff = _value - refund;

       
      _recepient.transfer(refund);
      _value = diff;
    }

     
    uint256 tokensSold = _value * tokensPerEthPrice;

     
    crowdsaleToken.transfer(_recepient, tokensSold);

     
    participants[_recepient] += _value;

     
    totalCollected += _value;

     
    totalSold += tokensSold;
  }

   
  function withdraw(
    uint256 _amount  
  )
    public
    onlyOwner()  
    hasntStopped()   
    whenCrowdsaleSuccessful()  
  {
    require(_amount <= this.balance);
    fundingAddress.transfer(_amount);
  }

   
  function refund()
    public
  {
     
    require(stopped || isFailed());

    uint256 amount = participants[msg.sender];

     
    require(amount > 0);
    participants[msg.sender] = 0;

    msg.sender.transfer(amount);
  }
}