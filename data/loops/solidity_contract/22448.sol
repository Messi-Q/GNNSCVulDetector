 

pragma solidity ^0.4.20;

contract EthAnte {
    
    uint public timeOut;
    uint public feeRate;
    address public TechnicalRise = 0x7c0Bf55bAb08B4C1eBac3FC115C394a739c62538;
    address public lastBidder;
    
    function EthAnte() public payable { 
        lastBidder = msg.sender;
	    timeOut = now + 1 hours;
	    feeRate = 10;  
	} 
	
	function fund() public payable {
	    require(msg.value >= 1 finney);
	    
	     
	     
	    if (timeOut <= now) {
	        TechnicalRise.transfer((address(this).balance - msg.value) / feeRate);
	        lastBidder.transfer((address(this).balance - msg.value) - address(this).balance / feeRate);
	    }
	    
	    timeOut = now + 1 hours;
	    lastBidder = msg.sender;
	}

	function () public payable {
		fund();
	}
}