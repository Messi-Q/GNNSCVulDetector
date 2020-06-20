pragma solidity ^0.4.19;

 
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

 
 
 
 
 
 
 
contract EthDickMeasuringGamev3 {
    address owner;
    address public largestPenisOwner;
    uint256 public largestPenis;
    uint256 public withdrawDate;

    function EthDickMeasuringGamev3() public{
        owner = msg.sender;
        largestPenisOwner = 0;
        largestPenis = 0;
    }

    function () public payable{
        require(largestPenis < msg.value);
        address prevOwner = largestPenisOwner;
        uint256 prevSize = largestPenis;
        
        largestPenisOwner = msg.sender;
        largestPenis = msg.value;
        withdrawDate = 1 days;
        
         
         
        if(prevOwner != 0x0)
            prevOwner.transfer(SafeMath.div(SafeMath.mul(prevSize, 80),100));

    }

    function withdraw() public{
        require(now >= withdrawDate);
        address roundWinner = largestPenisOwner;

         
        largestPenis = 0;
        largestPenisOwner = 0;

         
         
        owner.transfer(SafeMath.div(SafeMath.mul(this.balance, 1),100));
        
         
        roundWinner.transfer(this.balance);
    }
}