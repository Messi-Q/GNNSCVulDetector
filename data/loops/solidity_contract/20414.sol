pragma solidity 0.4.21;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract Moneda {
  event Transfer(address indexed from, address indexed to, uint256 value);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function burn() public;
}

contract MonedaICO {
    using SafeMath for uint256;
    
    struct DateRate {
        uint256 date;
        uint256 rate;
    }

     
    uint256 constant public preICOLimit = 20000000e18;  
    DateRate public preICO = DateRate(1525132799, 6750);  
    uint256 public pre_tokensSold = 0;
    
     
    DateRate public icoStarts = DateRate(1526342400, 5750);  
    DateRate public icoEndOfStageA = DateRate(1529020800, 5500);  
    DateRate public icoEndOfStageB = DateRate(1530316800, 5250);  
    DateRate public icoEnds = DateRate(1531699199, 5000);  
    uint256 constant public icoLimit = 250000000e18;  
    uint256 public tokensSold = 0;

     
    uint constant public fundingGoal = 10000000e18;  
     
    uint public amountRaised;
     
    mapping(address => uint) public balances;
     
    bool public crowdsaleEnded = false;
     
    address public tokenOwner;
     
    Moneda public tokenReward;
     
    address public wallet;
     
    event GoalReached(address tokenOwner, uint amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution, uint amountRaised);
    
    function MonedaICO(Moneda token, address walletAddr, address tokenOwnerAddr) public {
        tokenReward = token;
        wallet = walletAddr;
        tokenOwner = tokenOwnerAddr;
    }

    function () external payable {
        require(msg.sender != wallet);
        exchange(msg.sender);
    }

    function exchange(address receiver) public payable {
        uint256 amount = msg.value;
        uint256 price = getRate();
        uint256 numTokens = amount.mul(price);
        
        bool isPreICO = (now <= preICO.date);
        bool isICO = (now >= icoStarts.date && now <= icoEnds.date);
        
        require(isPreICO || isICO);
        require(numTokens > 500);
        
        if (isPreICO) {
            require(!crowdsaleEnded && pre_tokensSold.add(numTokens) <= preICOLimit);
            require(numTokens <= 5000000e18);
        }
        
        if (isICO) {
            require(!crowdsaleEnded && tokensSold.add(numTokens) <= icoLimit);
        }

        wallet.transfer(amount);
        balances[receiver] = balances[receiver].add(amount);
        amountRaised = amountRaised.add(amount);

        if (isPreICO)
            pre_tokensSold = pre_tokensSold.add(numTokens);
        if (isICO)
            tokensSold = tokensSold.add(numTokens);
        
        assert(tokenReward.transferFrom(tokenOwner, receiver, numTokens));
        emit FundTransfer(receiver, amount, true, amountRaised);
    }

    function getRate() public view returns (uint256) {
        if (now <= preICO.date)
            return preICO.rate;
            
        if (now < icoEndOfStageA.date)
            return icoStarts.rate;
            
        if (now < icoEndOfStageB.date)
            return icoEndOfStageA.rate;
            
        if (now < icoEnds.date)
            return icoEndOfStageB.rate;
        
        return icoEnds.rate;
    }
    
     
    function checkGoalReached() public {
        require(now >= icoEnds.date);
        if (pre_tokensSold.add(tokensSold) >= fundingGoal){
            tokenReward.burn();  
            emit GoalReached(tokenOwner, amountRaised);
        }
        crowdsaleEnded = true;
    }
    
     
     
    function safeWithdrawal() public {
        require(now >= icoEnds.date);
        uint amount = balances[msg.sender];
        if (address(this).balance >= amount) {
            balances[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false, amountRaised);
            }
        }
    }
}