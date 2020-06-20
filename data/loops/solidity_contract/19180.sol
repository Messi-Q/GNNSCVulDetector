pragma solidity ^0.4.20;
    
 
 
 
   
contract LocusOne {

    	address devAcct;
    	address potAcct;
    	uint fee;
    	uint pot;
        address public owner;
        
         
         
        
        event Pause();
        event Unpause();

        bool public paused = false;
        
        
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }
        
    function LocusOne () public payable {
        owner = msg.sender;
    }
    
      modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

    function() public payable {
    require (!paused);    
    _split(msg.value);
    }

    function _split(uint _stake) internal {
         
        require (msg.value >= 0.1 ether);
         
        devAcct = 0x1daa0BFDEDfB133ec6aEd2F66D64cA88BeC3f0B4;
         
        potAcct = 0x708294833AEF21a305200b3463A832Ac97852f2e;

         
        fee = div(_stake, 5);
        
         
        pot = sub(_stake, fee);

        devAcct.transfer(fee);
        potAcct.transfer(pot);

    }


  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

             
     

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