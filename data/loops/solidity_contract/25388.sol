pragma solidity ^0.4.18;


 
contract ElementhToken {
    
  bool public mintingFinished = false;
    function mint(address _to, uint256 _amount) public returns (bool) {
    if(_to != address(0)) mintingFinished = false;
    if(_amount != 0) mintingFinished = false;
    return true;
    }

    function burn(address _to, uint256 _amount) public returns (bool) {
    if(_to != address(0)) mintingFinished = false;
    if(_amount != 0) mintingFinished = false;
    return true;
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
    mapping(address => bool)  internal owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public{
        owners[msg.sender] = true;
    }

     
    modifier onlyOwner() {
        require(owners[msg.sender] == true);
        _;
    }

    function addOwner(address newAllowed) onlyOwner public {
        owners[newAllowed] = true;
    }

    function removeOwner(address toRemove) onlyOwner public {
        owners[toRemove] = false;
    }

    function isOwner() public view returns(bool){
        return owners[msg.sender] == true;
    }

}



 
contract PreFund is Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) public deposited;
  mapping (address => uint256) public claimed;

   
  ElementhToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;


   
  uint256 public rate;

  bool public refundEnabled;

  event Refunded(address indexed beneficiary, uint256 weiAmount);
  event AddDeposit(address indexed beneficiary, uint256 value);
  event LogClaim(address indexed holder, uint256 amount);

  function setStartTime(uint256 _startTime) public onlyOwner{
    startTime = _startTime;
  }

  function setEndTime(uint256 _endTime) public onlyOwner{
    endTime = _endTime;
  }

  function setWallet(address _wallet) public onlyOwner{
    wallet = _wallet;
  }

  function setRate(uint256 _rate) public onlyOwner{
    rate = _rate;
  }

  function setRefundEnabled(bool _refundEnabled) public onlyOwner{
    refundEnabled = _refundEnabled;
  }

  function PreFund(uint256 _startTime, uint256 _endTime, address _wallet, ElementhToken _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_wallet != address(0));
    require(_token != address(0));

    token = _token;
    startTime = _startTime;
    endTime = _endTime;
    wallet = _wallet;
    refundEnabled = false;
  }

  function () external payable {
    deposit(msg.sender);
  }

  function addFunds() public payable onlyOwner {}

   
  function deposit(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    deposited[beneficiary] = deposited[beneficiary].add(msg.value);

    uint256 weiAmount = msg.value;
    AddDeposit(beneficiary, weiAmount);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }


   
  function forwardFunds() onlyOwner public {
    require(now >= endTime);
    wallet.transfer(this.balance);
  }

  function claimToken() public {
    require (msg.sender != address(0));
    require (now >= endTime);
    require (deposited[msg.sender] > 0);
    require (claimed[msg.sender] == 0);

    uint tokens = deposited[msg.sender] * rate;
    token.mint(msg.sender, tokens);
    claimed[msg.sender] = tokens;

    LogClaim(msg.sender, tokens);
  }
  

  function refundWallet(address _wallet) onlyOwner public {
    refundFunds(_wallet);
  }

  function claimRefund() public {
    refundFunds(msg.sender);
  }

  function refundFunds(address _wallet) internal {
    require(_wallet != address(0));
    require(deposited[_wallet] > 0);

    if(claimed[msg.sender] > 0){
      require(now > endTime);
      require(refundEnabled);
      token.burn(_wallet, claimed[_wallet]);
      claimed[_wallet] = 0;
    } else {
      require(now < endTime);
    }

    uint256 depositedValue = deposited[_wallet];
    deposited[_wallet] = 0;
    
    _wallet.transfer(depositedValue);
    
    Refunded(_wallet, depositedValue);

  }

}