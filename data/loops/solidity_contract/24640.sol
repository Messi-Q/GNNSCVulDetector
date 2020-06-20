pragma solidity ^0.4.18;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public{
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
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


interface token {
    function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	function getTotalSupply() public view returns (uint256);
}



contract ApolloSeptemBaseCrowdsale {
    using SafeMath for uint256;

     
    token public tokenReward;
	
     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;
	
	 
	address public tokenAddress;

     
    uint256 public weiRaised;
	
	 
   uint256 public constant PRESALE_LIMIT = 90 * (10 ** 6) * (10 ** 18);    
    
	 
    uint256 public constant PRESALE_BONUS_LIMIT = 100 finney;
	
     
    uint public constant PRESALE_PERIOD = 30 days;
     
    uint public constant CROWD_WAVE1_PERIOD = 10 days;
     
    uint public constant CROWD_WAVE2_PERIOD = 10 days;
     
    uint public constant CROWD_WAVE3_PERIOD = 10 days;
	
	 
    uint public constant PRESALE_BONUS = 40;
    uint public constant CROWD_WAVE1_BONUS = 15;
    uint public constant CROWD_WAVE2_BONUS = 10;
    uint public constant CROWD_WAVE3_BONUS = 5;

    uint256 public limitDatePresale;
    uint256 public limitDateCrowdWave1;
    uint256 public limitDateCrowdWave2;
    uint256 public limitDateCrowdWave3;
	

     
    event ApolloSeptemTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event ApolloSeptemTokenSpecialPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);

    function ApolloSeptemBaseCrowdsale(address _wallet, address _tokens) public{		
        require(_wallet != address(0));
		tokenAddress = _tokens;
        tokenReward = token(tokenAddress);
        wallet = _wallet;
    }

     
    function () public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

         
        uint256 tokens = computeTokens(weiAmount);

        require(isWithinTokenAllocLimit(tokens));

         
        weiRaised = weiRaised.add(weiAmount);

		 
		tokenReward.transfer(beneficiary, tokens);

        ApolloSeptemTokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }


	 
	function specialTransfer(address _to, uint _amount) internal returns(bool){
		require(_to != address(0));
		require(_amount > 0 );
		
		 
        uint256 tokens = _amount * (10 ** 18);
		
		tokenReward.transfer(_to, tokens);		
		ApolloSeptemTokenSpecialPurchase(msg.sender, _to, tokens);
		
		return true;
	}

     
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
		
        return withinPeriod && nonZeroPurchase &&
                 !(isWithinPresaleTimeLimit() && msg.value < PRESALE_BONUS_LIMIT);
    }
    
    function isWithinPresaleTimeLimit() internal view returns (bool) {
        return now <= limitDatePresale;
    }

    function isWithinCrowdWave1TimeLimit() internal view returns (bool) {
        return now <= limitDateCrowdWave1;
    }

    function isWithinCrowdWave2TimeLimit() internal view returns (bool) {
        return now <= limitDateCrowdWave2;
    }

    function isWithinCrowdWave3TimeLimit() internal view returns (bool) {
        return now <= limitDateCrowdWave3;
    }

    function isWithinCrodwsaleTimeLimit() internal view returns (bool) {
        return now <= endTime && now > limitDatePresale;
    }
	
	function isWithinPresaleLimit(uint256 _tokens) internal view returns (bool) {
        return tokenReward.balanceOf(this).sub(_tokens) >= PRESALE_LIMIT;
    }

    function isWithinCrowdsaleLimit(uint256 _tokens) internal view returns (bool) {			
        return tokenReward.balanceOf(this).sub(_tokens) >= 0;
    }

    function isWithinTokenAllocLimit(uint256 _tokens) internal view returns (bool) {
        return (isWithinPresaleTimeLimit() && isWithinPresaleLimit(_tokens)) || 
                        (isWithinCrodwsaleTimeLimit() && isWithinCrowdsaleLimit(_tokens));
    }
	
	function sendAllToOwner(address beneficiary) internal returns(bool){
		
		tokenReward.transfer(beneficiary, tokenReward.balanceOf(this));
		return true;
	}

    function computeTokens(uint256 weiAmount) internal view returns (uint256) {
        uint256 appliedBonus = 0;
        if (isWithinPresaleTimeLimit()) {
            appliedBonus = PRESALE_BONUS;
        } else if (isWithinCrowdWave1TimeLimit()) {
            appliedBonus = CROWD_WAVE1_BONUS;
        } else if (isWithinCrowdWave2TimeLimit()) {
            appliedBonus = CROWD_WAVE2_BONUS;
        } else if (isWithinCrowdWave3TimeLimit()) {
            appliedBonus = CROWD_WAVE3_BONUS;
        }

		 
        return weiAmount.mul(42).mul(100 + appliedBonus);
    }
}




 
contract ApolloSeptemCappedCrowdsale is ApolloSeptemBaseCrowdsale{
    using SafeMath for uint256;

     
    uint256 public constant HARD_CAP = (3 ether)*(10**4);

    function ApolloSeptemCappedCrowdsale() public {}

     
     
    function validPurchase() internal view returns (bool) {
        bool withinCap = weiRaised.add(msg.value) <= HARD_CAP;

        return super.validPurchase() && withinCap;
    }

     
     
    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= HARD_CAP;
        return super.hasEnded() || capReached;
    }
}


 
contract ApolloSeptemCrowdsale is ApolloSeptemCappedCrowdsale, Ownable {

	bool public isFinalized = false;
	bool public isStarted = false;

	event ApolloSeptemStarted();
	event ApolloSeptemFinalized();

    function ApolloSeptemCrowdsale(address _wallet,address _tokensAddress) public
        ApolloSeptemCappedCrowdsale()
        ApolloSeptemBaseCrowdsale(_wallet,_tokensAddress) 
    {
   
    }
	
	 
	function start() onlyOwner public {
		require(!isStarted);

		starting();
		ApolloSeptemStarted();

		isStarted = true;
	}
	

    function starting() internal {
        startTime = now;
        limitDatePresale = startTime + PRESALE_PERIOD;
        limitDateCrowdWave1 = limitDatePresale + CROWD_WAVE1_PERIOD; 
        limitDateCrowdWave2 = limitDateCrowdWave1 + CROWD_WAVE2_PERIOD; 
        limitDateCrowdWave3 = limitDateCrowdWave2 + CROWD_WAVE3_PERIOD;         
        endTime = limitDateCrowdWave3;
    }
	
	 
	function finalize() onlyOwner public {
		require(!isFinalized);
		require(hasEnded());

		ApolloSeptemFinalized();

		isFinalized = true;
	}	
	
	 
	function apolloSpecialTransfer(address _beneficiary, uint _amount) onlyOwner public {		 
		 specialTransfer(_beneficiary, _amount);
	}
	
	
	 
	function sendRemaningBalanceToOwner(address _tokenOwner) onlyOwner public {
		require(!isFinalized);
		require(_tokenOwner != address(0));
		
		sendAllToOwner(_tokenOwner);	
	}
	
	
}