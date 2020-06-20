pragma solidity ^0.4.20;

interface Token {
    function totalSupply() constant external returns (uint256);
    
    function transfer(address receiver, uint amount) external returns (bool success);
    function burn(uint256 _value) external returns (bool success);
    function startTrading() external;
}

contract Owned {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
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


interface AquaPriceOracle {
  function getAudCentWeiPrice() external constant returns (uint);
  function getAquaTokenAudCentsPrice() external constant returns (uint);
  event NewPrice(uint _audCentWeiPrice, uint _aquaTokenAudCentsPrice);
}


 
contract AquaSale is Owned {
    using SafeMath for uint256;
    
    uint256 constant ONE_HUNDRED = 100;

     
    mapping (address => uint) internal buyerBalances;
    
     
    
     
    address public teamTrustAccount;
    
     
     
    uint public teamSharePercent;
    
     
    uint public lowTokensToSellGoal;
    
     
    uint public highTokensToSellGoal;
    
     
    uint public soldTokens;
    
     
    uint public startTime;
    
     
    uint public deadline;

     
    Token public tokenReward;
    
     
    AquaPriceOracle public tokenPriceOracle;
    

     
    bool public fundingGoalReached = false;
    
     
    bool public highFundingGoalReached = false;

     
     
     
    event GoalReached(uint amntRaisedWei, bool isHigherGoal);
    
     
     
     
     
    event FundsTransfer(address backer, uint amount, bool isContribution);

     
     
     
     
     
     
     
     
     
     
    function AquaSale(
        address ifSuccessfulSendTo,
        uint _lowTokensToSellGoal,
        uint _highTokensToSellGoal,
        uint startAfterMinutes,
        uint durationInMinutes,
        address addressOfTokenUsedAsReward,
        address addressOfTokenPriceOracle,
        address addressOfTeamTrusAccount,
        uint _teamSharePercent
    ) public {
        owner = ifSuccessfulSendTo;
        lowTokensToSellGoal = _lowTokensToSellGoal;
        highTokensToSellGoal = _highTokensToSellGoal;
        startTime = now.add(startAfterMinutes.mul(1 minutes));
        deadline = startTime.add(durationInMinutes.mul(1 minutes));
        tokenReward = Token(addressOfTokenUsedAsReward);
        tokenPriceOracle = AquaPriceOracle(addressOfTokenPriceOracle);
        teamTrustAccount = addressOfTeamTrusAccount;
        teamSharePercent = _teamSharePercent;
    }
    
     
     
     
    function buyerBalance(address _buyer) public constant returns(uint) {
        return buyerBalances[_buyer];
    }

     
    function () public payable {
        purchaseTokens();
    }
    
     
    function purchaseTokens() public payable {
        require(!highFundingGoalReached && now >= startTime );
        uint amount = msg.value;
        uint noTokens = amount.div(
            tokenPriceOracle.getAquaTokenAudCentsPrice().mul(tokenPriceOracle.getAudCentWeiPrice())
            );
        buyerBalances[msg.sender] = buyerBalances[msg.sender].add(amount);
        soldTokens = soldTokens.add(noTokens);
        checkGoalsReached();

        tokenReward.transfer(msg.sender, noTokens);

        FundsTransfer(msg.sender, amount, true);
    }
    
     
     
     
     
    function refund() public {
        require(!fundingGoalReached && buyerBalances[msg.sender] > 0
                && now >= deadline);
        uint amount = buyerBalances[msg.sender];
        buyerBalances[msg.sender] = 0;
        msg.sender.transfer(amount);
        FundsTransfer(msg.sender, amount, false);
    }

     
     
    function withdraw() onlyOwner public {
        require( (fundingGoalReached && now >= deadline) || highFundingGoalReached );
        uint raisedFunds = this.balance;
        uint teamTokens = soldTokens.mul(teamSharePercent).div(ONE_HUNDRED.sub(teamSharePercent));
        uint totalTokens = tokenReward.totalSupply();
        if (totalTokens < teamTokens.add(soldTokens)) {
            teamTokens = totalTokens.sub(soldTokens);
        }
        tokenReward.transfer(teamTrustAccount, teamTokens);
        uint distributedTokens = teamTokens.add(soldTokens);
        if (totalTokens > distributedTokens) {
            tokenReward.burn(totalTokens.sub(distributedTokens));
        }
        tokenReward.startTrading();
        Owned(address(tokenReward)).transferOwnership(owner);
        owner.transfer(raisedFunds);
        FundsTransfer(owner, raisedFunds, false);
    }
    
     
    
    function checkGoalsReached() internal {
        if (fundingGoalReached) {
            if (highFundingGoalReached) {
                return;
            }
            if (soldTokens >= highTokensToSellGoal) {
                highFundingGoalReached = true;
                GoalReached(this.balance, true);
                return;
            }
        }
        else {
            if (soldTokens >= lowTokensToSellGoal) {
                fundingGoalReached = true;
                GoalReached(this.balance, false);
            }
            if (soldTokens >= highTokensToSellGoal) {
                highFundingGoalReached = true;
                GoalReached(this.balance, true);
                return;
            }
        }
    }
    
}