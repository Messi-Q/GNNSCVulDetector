pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
     
    uint public percent;
    mapping(address => uint256) public percentOf;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event RewardToken(address backer, uint amount, uint percent);

     
    function Crowdsale(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint weiCostOfEachToken,
        address addressOfTokenUsedAsReward,
        uint initPercent
    ) {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = weiCostOfEachToken * 1 wei;
        tokenReward = token(addressOfTokenUsedAsReward);
        percent = initPercent;
    }

     
    function () payable {
        if (crowdsaleClosed) {
            uint amount2 = balanceOf[msg.sender];
            uint rewardPercent = percent - percentOf[msg.sender];
            require(amount2 > 0 && rewardPercent > 0);
            percentOf[msg.sender] = percent;
             
            uint rewardAmount2 = amount2 * 10**18 * rewardPercent / price / 100;
            tokenReward.transfer(msg.sender, rewardAmount2);
            RewardToken(msg.sender, rewardAmount2, rewardPercent);
        } else {
            uint amount = msg.value;
            balanceOf[msg.sender] += amount;
            amountRaised += amount;
            percentOf[msg.sender] = percent;
             
            uint rewardAmount = amount * 10**18 * percent / price / 100;
            tokenReward.transfer(msg.sender, rewardAmount);
            FundTransfer(msg.sender, amount, true);
            RewardToken(msg.sender, rewardAmount, percent);
        }
    }

    modifier afterDeadline() { if (now >= deadline) _; }

     
    function checkGoalReached() afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }


     
    function safeWithdrawal() afterDeadline {
        require(crowdsaleClosed);

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
    
     
    function releaseTenPercent() afterDeadline {
        require(crowdsaleClosed);

        require(percent <= 90);
        if (fundingGoalReached && beneficiary == msg.sender) {
            percent += 10;
        }
    }
}