pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
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

contract I2Presale is Ownable {
    using SafeMath for uint256;

    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    uint public usd = 1000;
    uint public bonus;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

     
    function I2Presale (
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
         
        uint tokensPerDollar,  
         
         
        uint bonusInPercent,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
         
        fundingGoal = fundingGoalInEthers.mul(1 ether); 
        deadline = now.add(durationInMinutes.mul(1 minutes));
        price = 10**18;
        price = price.div(tokensPerDollar).div(usd); 
         
         
        bonus = bonusInPercent;

        tokenReward = token(addressOfTokenUsedAsReward);
    }

     
    function changeBonus (uint _bonus) public onlyOwner {
        bonus = _bonus;
    }
    
     
    function setUSDPrice (uint _usd) public onlyOwner {
        usd = _usd;
    }
    
     
    function finshCrowdsale () public onlyOwner {
        deadline = now;
        crowdsaleClosed = true;
    }

     
    function () public payable {
        require(beneficiary != address(0));
        require(!crowdsaleClosed);
        require(msg.value != 0);
        
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
         
         
        uint tokensToSend = amount.div(price).mul(10**18);
        uint tokenToSendWithBonus = tokensToSend.add(tokensToSend.mul(bonus).div(100));
        tokenReward.transfer(msg.sender, tokenToSendWithBonus);
        FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

     
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


     
    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                 
                fundingGoalReached = false;
            }
        }
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