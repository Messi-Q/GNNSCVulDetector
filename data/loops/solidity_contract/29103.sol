pragma solidity ^0.4.19;

interface token {
    function transfer(address receiver, uint256 amount);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

contract GasCrowdsale {
    using SafeMath for uint256;
    
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public startdate;
    uint256 public deadline;
    uint256 public price;
    uint256 public fundTransferred;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

     
     

     
    function GasCrowdsale() {
        beneficiary = 0x007FB3e94dCd7C441CAA5b87621F275d199Dff81;
        fundingGoal = 8000 ether;
        startdate = 1518134400;
        deadline = startdate + 29 days;
        price = 0.0008 ether;
        tokenReward = token(0x75c79b88facE8892E7043797570c390bc2Db52A7);
    }

     
    function () payable {
        require(!crowdsaleClosed);
        uint256 bonus;
        uint256 amount = msg.value;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        amountRaised = amountRaised.add(amount);
        
         
        if(now >= startdate && now <= startdate + 24 hours ){
            amount =  amount.div(price);
            bonus = amount.mul(30).div(100);
            amount = amount.add(bonus);
        }
        else if(now > startdate + 24 hours && now <= startdate + 24 hours + 1 weeks ){
            amount =  amount.div(price);
            bonus = amount.mul(20).div(100);
            amount = amount.add(bonus);
        }
        else if(now > startdate + 24 hours + 1 weeks && now <= startdate + 24 hours + 3 weeks ){
            amount =  amount.div(price);
            bonus = amount.mul(10).div(100);
            amount = amount.add(bonus);
        } else {
            amount =  amount.div(price);
        }
        
        amount = amount.mul(100000000);
        tokenReward.transfer(msg.sender, amount);
         
    }

    modifier afterDeadline() { if (now >= deadline) _; }

     
     
    function endCrowdsale() afterDeadline {
        crowdsaleClosed = true;
    }


     
    function safeWithdrawal() {
        if (beneficiary == msg.sender) {
            if(fundTransferred != amountRaised){
               uint256 transferfund;
               transferfund = amountRaised.sub(fundTransferred);
               fundTransferred = fundTransferred.add(transferfund);
               beneficiary.send(transferfund);
            } 
        }
    }
}