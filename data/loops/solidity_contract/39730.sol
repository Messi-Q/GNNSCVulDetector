pragma solidity ^0.4.6;

contract token {
	function transferFrom(address sender, address receiver, uint amount) returns(bool success){}
	function burn() {}
}

 
contract Crowdsale {
     
	address public beneficiary = 0x003230bbe64eccd66f62913679c8966cf9f41166;
	 
	uint public fundingGoal = 50000000;
	 
	uint public maxGoal = 440000000;
	 
	uint public amountRaised;
	 
	uint public start = 1488294000;
	 
	uint public tokensSold;
	 
	uint[4] public deadlines = [1488297600, 1488902400, 1489507200,1490112000];
	uint[4] public prices = [833333333333333, 909090909090909,952380952380952, 1000000000000000];
	 
	token public tokenReward;
	 
	mapping(address => uint256) public balanceOf;
	bool fundingGoalReached = false;
	bool crowdsaleClosed = false;
	 
	event GoalReached(address beneficiary, uint amountRaised);
	event FundTransfer(address backer, uint amount, bool isContribution);



     
    function Crowdsale( ) {
        tokenReward = token(0xbe87e87965b96d8174eae4e3724a6d7417c488b0);
    }

     
    function () payable{
        invest(msg.sender);
    }

     
    function invest(address receiver) payable{
    	uint amount = msg.value;
	uint numTokens = amount / getPrice();
	if (crowdsaleClosed||now<start||tokensSold+numTokens>maxGoal) throw;
	balanceOf[receiver] += amount;
	amountRaised += amount;
	tokensSold+=numTokens;
	if(!tokenReward.transferFrom(beneficiary, receiver, numTokens)) throw;
        FundTransfer(receiver, amount, true);
    }

     
    function getPrice() constant returns (uint256 price){
        for(var i = 0; i < deadlines.length; i++)
            if(now<deadlines[i])
                return prices[i];
        return prices[prices.length-1]; 
    }

    modifier afterDeadline() { if (now >= deadlines[deadlines.length-1]) _; }

     
    function checkGoalReached() afterDeadline {
        if (tokensSold >= fundingGoal){
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

     
    function safeWithdrawal() afterDeadline {
         
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
            tokenReward.burn();  
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                 
                fundingGoalReached = false;
            }
        }
    }
}