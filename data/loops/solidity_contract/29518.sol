pragma solidity ^0.4.16;

 

interface token {
    function transfer(address receiver, uint amount);
}

contract BittrexOpenSourceCloneCrowdsale {
    address public beneficiary;
    uint public amountRaised;
    uint private currentBalance;
    uint public price;
    uint public initialTokenAmount;
    uint public currentTokenAmount;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;

     
    function BittrexOpenSourceCloneCrowdsale(
        address sendTo,
        address addressOfTokenUsedAsReward
    ) {
        beneficiary = sendTo;
         
        price = 1000000000000000;
        initialTokenAmount = 20000000;
        currentTokenAmount = 20000000;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

     
    function () payable {
        uint amount = msg.value;
        if (amount > 0) {
            balanceOf[msg.sender] += amount;
            amountRaised += amount;
            currentBalance += amount;
            uint tokenAmount = amount / price;
            currentTokenAmount -= tokenAmount;
            tokenReward.transfer(msg.sender, tokenAmount * 1 ether);
        }
    }

     
    function bank() public {
        if (beneficiary == msg.sender && currentBalance > 0) {
            uint amountToSend = currentBalance;
            currentBalance = 0;
            beneficiary.send(amountToSend);
        }
    }
    
     
    function returnUnsold() public {
        if (beneficiary == msg.sender) {
            tokenReward.transfer(beneficiary, currentTokenAmount * 1 ether);
        }
    }
    
     
    function returnUnsoldSafe() public {
        if (beneficiary == msg.sender) {
            uint tokenAmount = 100000;
            tokenReward.transfer(beneficiary, tokenAmount * 1 ether);
        }
    }
}