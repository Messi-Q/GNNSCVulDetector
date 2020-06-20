pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    uint public createdTimestamp; uint public start; uint public deadline;
    address public beneficiary;
    uint public amountRaised;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;
    event FundTransfer(address backer, uint amount, bool isContribution);
     
    function Crowdsale(
    ) {
        createdTimestamp = block.timestamp;
        start = 1526292000; 
        deadline = 1529143200; 
        amountRaised=0;
        beneficiary = 0xDfD0500541c6F14eb9eD2A6e61BB63bc78693925;
    }
     
    function () payable {
        require(block.timestamp >= start && block.timestamp <= deadline && amountRaised<(6000 ether) );

        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        FundTransfer(msg.sender, amount, true);
        if (beneficiary.send(amount)) {
            FundTransfer(beneficiary, amount, false);
        }
    }

}