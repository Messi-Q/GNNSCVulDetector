pragma solidity ^0.4.18;

 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract JoyTokenAbstract {
  function unlock();
}

 
contract JoysoCrowdsale {
  using SafeMath for uint256;

   
  address constant public JOY = 0x18D0a71E1135dCb693d3F305BA9dcA720d911E86;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public joysoWallet = 0x1CaC2d7ee5Fd2E6C349d1783B0BFC80ee4d55daD;

   
  uint256 public rate = 100000000;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

     
    uint256 joyAmounts = calculateObtainedJOY(msg.value);

     
    weiRaised = weiRaised.add(msg.value);

    require(ERC20Basic(JOY).transfer(beneficiary, joyAmounts));
    TokenPurchase(msg.sender, beneficiary, msg.value, joyAmounts);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    joysoWallet.transfer(msg.value);
  }

  function calculateObtainedJOY(uint256 amountEtherInWei) public view returns (uint256) {
    return amountEtherInWei.mul(rate).div(10 ** 12);
  } 

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    return withinPeriod;
  }

   
  function hasEnded() public view returns (bool) {
    bool isEnd = now > endTime || weiRaised == 2 * 10 ** (8+6);
    return isEnd;
  }

   
  function releaseJoyToken() public returns (bool) {
    require (hasEnded() && startTime != 0);
    require (msg.sender == joysoWallet || now > endTime + 10 days);
    uint256 remainedJoy = ERC20Basic(JOY).balanceOf(this);
    require(ERC20Basic(JOY).transfer(joysoWallet, remainedJoy));    
    JoyTokenAbstract(JOY).unlock();
  }

   
  function start() public returns (bool) {
    require (msg.sender == joysoWallet);
    startTime = now;
    endTime = now + 24 hours;
  }

  function changeJoysoWallet(address _joysoWallet) public returns (bool) {
    require (msg.sender == joysoWallet);
    joysoWallet = _joysoWallet;
  }
}