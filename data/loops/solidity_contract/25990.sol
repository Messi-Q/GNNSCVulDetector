pragma solidity ^0.4.18;

 
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

contract DragonToken{
  function transferFrom(address _from, address _to, uint256 _value) returns(bool success);
}

 
contract Crowdsale is Ownable{
  using SafeMath for uint256;

   
  DragonToken public token;
  
   
  address public tokenReserve;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;
  
  uint256 public tokensSold;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 releaseTime);
  
   
  event EndTimeUpdated();
  
   
  event DragonPriceUpdated();
  
   
  event TokenReleased(address indexed holder, uint256 amount);


  function Crowdsale() public {
  
    owner = 0xF615Ac471E066b5ae4BD211CC5044c7a31E89C4e;  
    startTime = now;
    endTime = 1521187200;
    rate = 5000000000000000;  
    wallet = 0xF615Ac471E066b5ae4BD211CC5044c7a31E89C4e;
    token = DragonToken(0x814F67fA286f7572B041D041b1D99b432c9155Ee);
    tokenReserve = 0xF615Ac471E066b5ae4BD211CC5044c7a31E89C4e;
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
    tokensSold = tokensSold.add(tokens);

    uint256 lockedFor = assignTokens(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens, lockedFor);

    forwardFunds();
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    uint256 amount = weiAmount.div(rate);
    return amount.mul(100000000);  
  }

   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function updateEndTime(uint256 newTime) onlyOwner external {
    require(newTime > startTime);
    endTime = newTime;
    EndTimeUpdated();
  }
  
  function updateDragonPrice(uint256 weiAmount) onlyOwner external {
    require(weiAmount > 0);
    rate = weiAmount;
    DragonPriceUpdated();
  }
  
  mapping(address => uint256) balances;
  mapping(address => uint256) releaseTime;
  function assignTokens(address beneficiary, uint256 amount) private returns(uint256 lockedFor){
      lockedFor = now + 45 days;
      balances[beneficiary] = balances[beneficiary].add(amount);
      releaseTime[beneficiary] = lockedFor;
  }
  
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  

  function unlockTime(address _owner) public view returns (uint256 time) {
    return releaseTime[_owner];
  }

   
  function releaseDragonTokens() public {
    require(now >= releaseTime[msg.sender]);
    
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    
    balances[msg.sender] = 0;
    if(!token.transferFrom(tokenReserve,msg.sender,amount)){
        revert();
    }

    TokenReleased(msg.sender,amount);
  }
  
}