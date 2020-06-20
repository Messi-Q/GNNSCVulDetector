pragma solidity 0.4.18;


 
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

interface token {
    function transfer(address receiver, uint amount) public;
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


 
contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        if (halted) revert();
        _;
    }

    modifier onlyInEmergency {
        if (!halted) revert();
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}

 

contract Crowdsale  is Haltable {
    using SafeMath for uint256;
    event FundTransfer(address backer, uint amount, bool isContribution);
     
    event EndsAtChanged(uint deadline);
    event CSClosed(bool crowdsaleClosed);

    address public beneficiary;
    uint public amountRaised;
    uint public amountAvailable;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public crowdsaleClosed = false;

    uint public numTokensLeft;
    uint public numTokensSold;
     
     

     
    function Crowdsale(
        address ifSuccessfulSendTo,
        address addressOfTokenUsedAsReward,
        uint unixTimestampEnd,
        uint initialTokenSupply
    ) public {
        owner = msg.sender;

        if(unixTimestampEnd == 0) {
            revert();
        }
        uint dec = 1000000000;
        numTokensLeft = initialTokenSupply.mul(dec);
        deadline = unixTimestampEnd;

         
        if(now >= deadline) {
            revert();
        }

        beneficiary = ifSuccessfulSendTo;
        price = 0.000000000000166666 ether;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

     
    function () public stopInEmergency payable {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        uint leastAmount = 600000000000;
        uint numTokens = amount.div(price);

        uint stageOne = 1520856000; 
        uint stageTwo = 1521460800; 
        uint stageThree = 1522065600; 
        uint stageFour = 1522670400; 
         

        uint numBonusTokens;
        uint totalNumTokens;

         
         
         
        if(now < stageOne)
        {
             
            numBonusTokens = (numTokens.div(100)).mul(40);
            totalNumTokens = numTokens.add(numBonusTokens);
        }
        else if(now < stageTwo)
        {
             
            numBonusTokens = (numTokens.div(100)).mul(20);
            totalNumTokens = numTokens.add(numBonusTokens);
        }
        else if(now < stageThree){
             
            numBonusTokens = (numTokens.div(100)).mul(15);
            totalNumTokens = numTokens.add(numBonusTokens);
        }
        else if(now < stageFour){
             
            numBonusTokens = (numTokens.div(100)).mul(10);
            totalNumTokens = numTokens.add(numBonusTokens);
        }
        else{
            numBonusTokens = 0;
            totalNumTokens = numTokens.add(numBonusTokens);
        }

         
        if (numTokens <= leastAmount) {
            revert();
        } else {
            balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
            amountRaised = amountRaised.add(amount);
            amountAvailable = amountAvailable.add(amount);
            numTokensSold = numTokensSold.add(totalNumTokens);
            numTokensLeft = numTokensLeft.sub(totalNumTokens);
            tokenReward.transfer(msg.sender, totalNumTokens);
            FundTransfer(msg.sender, amount, true);
        }
    }

     
     
     
    function safeWithdrawal() public onlyOwner{
        if(amountAvailable < 0)
        {
            revert();
        }
        else
        {
            uint amtA = amountAvailable;
            amountAvailable = 0;
            beneficiary.transfer(amtA);
        }
    }

     
     
     
    function withdrawTheUnsoldTokens() public onlyOwner afterDeadline{
        if(numTokensLeft <= 0)
        {
            revert();
        }
        else
        {
            uint ntl = numTokensLeft;
            numTokensLeft=0;
            tokenReward.transfer(beneficiary, ntl);
            crowdsaleClosed = true;
            CSClosed(crowdsaleClosed);
        }
    }

     
     
     

    modifier afterDeadline() { if (now >= deadline) _; }

    function setDeadline(uint time) public onlyOwner {
        if(now > time || msg.sender==beneficiary)
        {
            revert();  
        }
        deadline = time;
        EndsAtChanged(deadline);
    }

     
}