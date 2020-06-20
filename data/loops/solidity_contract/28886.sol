pragma solidity ^0.4.18;

 

interface token {
    function transfer(address receiver, uint amount) public;
}

 
contract withdrawToken {
    function transfer(address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external constant returns (uint balance);
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

 
contract Crowdsale {
    using SafeMath for uint256;

    address public owner;  
    address public operations;  
    address public index;  
    uint256 public amountRaised;  
    uint256 public amountRaisedPhase;  
    uint256 public tokensSold;  
    uint256 public phase1Price;  
    uint256 public phase2Price;  
    uint256 public phase3Price;  
    uint256 public phase4Price;  
    uint256 public phase5Price;  
    uint256 public phase6Price;  
    uint256 public startTime;  
    token public tokenReward;  
    mapping(address => uint256) public contributionByAddress;

    event FundTransfer(address backer, uint amount, bool isContribution);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Crowdsale(
        uint saleStartTime,
        address ownerAddress,
        address operationsAddress,
        address indexAddress,
        address rewardTokenAddress

    ) public {
        startTime = saleStartTime;  
        owner = ownerAddress;  
        operations = operationsAddress;  
        index = indexAddress;  
        phase1Price = 0.00600 ether;  
        phase2Price = 0.00613 ether;  
        phase3Price = 0.00627 ether;  
        phase4Price = 0.00640 ether;  
        phase5Price = 0.00653 ether;  
        phase6Price = 0.00667 ether;  
        tokenReward = token(rewardTokenAddress);  
    }

     
    function () public payable {
        uint256 amount = msg.value;
        require(now > startTime);
        require(amount <= 1000 ether);

        if(now < startTime.add(7 days)) {  
            contributionByAddress[msg.sender] = contributionByAddress[msg.sender].add(amount);
            amountRaised = amountRaised.add(amount);
            amountRaisedPhase = amountRaisedPhase.add(amount);
            tokensSold = tokensSold.add(amount.mul(10**18).div(phase1Price));
            tokenReward.transfer(msg.sender, amount.mul(10**18).div(phase1Price));
            FundTransfer(msg.sender, amount, true);
        }

        else if(now > startTime.add(7 days) && now < startTime.add(14 days)) {  
            contributionByAddress[msg.sender] = contributionByAddress[msg.sender].add(amount);
            amountRaised = amountRaised.add(amount);
            amountRaisedPhase = amountRaisedPhase.add(amount);
            tokensSold = tokensSold.add(amount.mul(10**18).div(phase2Price));
            tokenReward.transfer(msg.sender, amount.mul(10**18).div(phase2Price));
            FundTransfer(msg.sender, amount, true);
        }

        else if(now > startTime.add(14 days) && now < startTime.add(21 days)) {  
            contributionByAddress[msg.sender] = contributionByAddress[msg.sender].add(amount);
            amountRaised = amountRaised.add(amount);
            amountRaisedPhase = amountRaisedPhase.add(amount);
            tokensSold = tokensSold.add(amount.mul(10**18).div(phase3Price));
            tokenReward.transfer(msg.sender, amount.mul(10**18).div(phase3Price));
            FundTransfer(msg.sender, amount, true);
        }

        else if(now > startTime.add(21 days) && now < startTime.add(28 days)) {  
            contributionByAddress[msg.sender] = contributionByAddress[msg.sender].add(amount);
            amountRaised = amountRaised.add(amount);
            amountRaisedPhase = amountRaisedPhase.add(amount);
            tokensSold = tokensSold.add(amount.mul(10**18).div(phase4Price));
            tokenReward.transfer(msg.sender, amount.mul(10**18).div(phase4Price));
            FundTransfer(msg.sender, amount, true);
        }

        else if(now > startTime.add(28 days) && now < startTime.add(35 days)) {  
            contributionByAddress[msg.sender] = contributionByAddress[msg.sender].add(amount);
            amountRaised = amountRaised.add(amount);
            amountRaisedPhase = amountRaisedPhase.add(amount);
            tokensSold = tokensSold.add(amount.mul(10**18).div(phase5Price));
            tokenReward.transfer(msg.sender, amount.mul(10**18).div(phase5Price));
            FundTransfer(msg.sender, amount, true);
        }

        else if(now > startTime.add(35 days)) {  
            contributionByAddress[msg.sender] = contributionByAddress[msg.sender].add(amount);
            amountRaised = amountRaised.add(amount);
            amountRaisedPhase = amountRaisedPhase.add(amount);
            tokensSold = tokensSold.add(amount.mul(10**18).div(phase6Price));
            tokenReward.transfer(msg.sender, amount.mul(10**18).div(phase6Price));
            FundTransfer(msg.sender, amount, true);
        }
    }

     
    function withdrawTokens(address tokenContract) external onlyOwner {
        withdrawToken tc = withdrawToken(tokenContract);

        tc.transfer(owner, tc.balanceOf(this));
    }
    
     
    function withdrawEther() external onlyOwner {
        uint256 total = this.balance;
        uint256 operationsSplit = 40;
        uint256 indexSplit = 60;
        operations.transfer(total * operationsSplit / 100);
        index.transfer(total * indexSplit / 100);
    }
}