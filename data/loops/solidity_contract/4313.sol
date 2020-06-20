pragma solidity ^0.4.24;
 
 
 

library SafeMath {                              
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) { return 0; }
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

contract QurozToken {  
  function transfer(address _to, uint256 _value) public returns (bool) {}
}

contract QforaSale {
  using SafeMath for uint256;                          
  uint256 public goal;                                 
  uint256 public rate;                                 
  uint256 public openingTime;                          
  uint256 public closingTime;                          
  uint256 public weiRaised;                            
  uint256 public tokenSold;           
  uint256 public threshold;           
  uint256 public hardCap;             
  uint256 public bonusRate;           
  address public wallet;                               
  address public owner;                                
  bool public isFinalized;                      
  mapping(address => uint256) public balances;        
  mapping(address => uint256) public deposited;       
  mapping(address => bool) public whitelist;           
  enum State { Active, Refunding, Closed }             
  State public state;                                  
  QurozToken public token;

  event Closed();                                      
  event RefundsEnabled();                              
  event Refunded(address indexed beneficiary, uint256 weiAmount);    
  event Finalized();                                       
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);   
  event TokenPurchase(address indexed purchaser,address indexed beneficiary,uint256 value,uint256 amount);  

  constructor(address _wallet, QurozToken _token) public {
    require(_wallet != address(0) && _token != address(0));
    owner = msg.sender;
    wallet = _wallet;
    token = _token;
    goal = 5000e18;
    rate = 10000;
    threshold = 100e18;
    hardCap = 50000e18;
    bonusRate = 20;
    openingTime = now.add(3 hours + 5 minutes);
    closingTime = openingTime.add(28 days);
    require(block.timestamp <= openingTime && openingTime <= closingTime);
  }

  modifier onlyOwner() {require(msg.sender == owner); _;}             
  modifier isWhitelisted(address _beneficiary) {require(whitelist[_beneficiary]); _;}   

  function addToWhitelist(address _beneficiary) public onlyOwner {       
    whitelist[_beneficiary] = true;
  }

  function addManyToWhitelist(address[] _beneficiaries) public onlyOwner {  
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  function removeFromWhitelist(address _beneficiary) public onlyOwner {  
    whitelist[_beneficiary] = false;
  }

  function () external payable {                                             
    require(openingTime <= block.timestamp && block.timestamp <= closingTime);       
    require(whitelist[msg.sender]);         
    require(msg.value >= threshold );       
    require(weiRaised.add(msg.value) <= hardCap );       
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) public payable {                            
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);
    uint256 tokens = _getTokenAmount(weiAmount);
    uint256 totalTokens = tokens.mul(100 + bonusRate).div(100);
    weiRaised = weiRaised.add(weiAmount);
    tokenSold = tokenSold.add(totalTokens);           
    _processPurchase(_beneficiary, totalTokens);      
    deposit(_beneficiary, msg.value);            
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
 
 
 
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {    
       
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {         
    return _weiAmount.mul(rate);
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {       
 
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);   

  }

  function hasClosed() public view returns (bool) {                
    return block.timestamp > closingTime;
  }

  function deposit(address investor, uint256 value) internal {   
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(value);
  }

  function goalReached() public view returns (bool) {     
    return weiRaised >= goal;
  }

  function finalize() onlyOwner public {           
    require(!isFinalized);
    require(hasClosed());    
    finalization();
    emit Finalized();
    isFinalized = true;
  }

  function finalization() internal {                      
    if (goalReached()) { close(); } 
    else               { enableRefunds(); }
     
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

  function claimRefund() public {                          
    require(isFinalized);
    require(!goalReached());
    refund(msg.sender);
  }

  function refund(address investor) public {        
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    balances[investor] = 0;                                                                              
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }

  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {        
    token.transfer(_beneficiary, _tokenAmount);
  }

  function withdrawTokens() public {                               
    require(hasClosed());
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
    deposited[msg.sender] = 0;                         
  }

  function transferOwnership(address _newOwner) public onlyOwner {  
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {        
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
    
  function destroyAndSend(address _recipient) onlyOwner public {    
    selfdestruct(_recipient);
  }

 
  function transferToken(address to, uint256 value) onlyOwner public { 
    token.transfer(to, value);
  }
  
  function setBonusRate(uint256 _bonusRate) public onlyOwner{
    _setBonusRate(_bonusRate);
  }

  function _setBonusRate(uint256 _bonusRate) internal {
    bonusRate = _bonusRate;
  }
  
  function getWeiBalance() public view returns(uint256) {
    return address(this).balance;
  }

  function getBalanceOf(address investor) public view returns(uint256) {
    return balances[investor];
  }

  function getDepositedOf(address investor) public view returns(uint256) {
    return deposited[investor];
  }

  function getWeiRaised() public view returns(uint256) {
    return weiRaised;
  }

  function getTokenSold() public view returns(uint256) {
    return tokenSold;
  }

  function setSmallInvestor(address _beneficiary, uint256 weiAmount, uint256 totalTokens) public onlyOwner {
    require(whitelist[_beneficiary]); 
    require(weiAmount >= 1 ether ); 
    require(weiRaised.add(weiAmount) <= hardCap ); 
    weiRaised = weiRaised.add(weiAmount);
    tokenSold = tokenSold.add(totalTokens); 
    _processPurchase(_beneficiary, totalTokens);     
    deposit(_beneficiary, weiAmount);
  }

}