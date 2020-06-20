pragma solidity ^0.4.18;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
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


 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

contract Vend is MintableToken {
  	string public constant name = "VEND";
  	string public constant symbol = "VEND";
  	uint8 public constant decimals = 18;

  	 
    function finishMinting() onlyOwner canMint public returns (bool) {
      mintingFinished = true;
      MintFinished();
      return true;
    }

}



contract VendCrowdsale is Crowdsale , Ownable, CappedCrowdsale {

	 
	enum Stage {PRESALE, PUBLICSALE}

	 
	Stage public stage;

	uint256 private constant DECIMALFACTOR = 10**uint256(18);

	uint256 public publicAllocation = 120000000 * DECIMALFACTOR;  
	uint256 public advisorsAllocation = 20000000 * DECIMALFACTOR;  
	uint256 public marketAllocation = 20000000 * DECIMALFACTOR;  
	uint256 public founderAllocation = 40000000* DECIMALFACTOR;  

	uint256 public softCap = 9000 ether;
             

	bool public isGoalReached = false;
	 
	mapping (address => uint256) public investedAmountOf;
	 
	uint256 public investorCount;

	uint256 public minContribAmount = 0.1 ether;  

	event MinimumGoalReached();
	event Burn (address indexed burner, uint256 value);


	 
	function VendCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _cap)
    	Crowdsale (_startTime, _endTime, _rate, _wallet) CappedCrowdsale(_cap * DECIMALFACTOR)
  {
    	stage = Stage.PRESALE;
  }
  	function createTokenContract() internal returns (MintableToken) {
    	return new Vend();
  }

  	 
  	 
  	 
  	 

  	function buyTokens(address beneficiary) public payable {

       	require(validPurchase());
       	uint256 weiAmount = msg.value;
       	 
       	uint256 tokens = weiAmount.mul(rate);
       	uint256 timebasedBonus = tokens.mul(getTimebasedBonusRate()).div(100);
       	uint256 volumebasedBonus = tokens.mul(getVolumebasedBonusRate(weiAmount)).div(100);
       	tokens = tokens.add(timebasedBonus);
       	tokens = tokens.add(volumebasedBonus);
		assert (tokens <= publicAllocation);
		   
       	if(investedAmountOf[beneficiary] == 0) {
            
           	investorCount++;
        }
         
        investedAmountOf[beneficiary] = investedAmountOf[beneficiary].add(weiAmount);
        if (stage == Stage.PRESALE) {
            assert (tokens <= publicAllocation);
            publicAllocation = publicAllocation.sub(tokens);
        } else {
            assert (tokens <= publicAllocation);
            publicAllocation = publicAllocation.sub(tokens);

        }
       forwardFunds();
       weiRaised = weiRaised.add(weiAmount);
       token.mint(beneficiary, tokens);
       TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
       if (!isGoalReached && weiRaised >= softCap) {
             isGoalReached = true;
             MinimumGoalReached();
         }
     }

      
    function validPurchase() internal constant returns (bool) {
       bool minContribution = minContribAmount <= msg.value;
       bool withinPeriod = now >= startTime && now <= endTime;
       bool nonZeroPurchase = msg.value != 0;
       bool Publicsale =publicAllocation !=0;
       return withinPeriod && minContribution && nonZeroPurchase && Publicsale;
    }
    
    function getNow() public constant returns (uint) {
       return (now);
    }
   	 
    function getTimebasedBonusRate() internal constant returns (uint256) {
       uint256 bonusRate = 0;
         if (stage == Stage.PUBLICSALE) {
       uint256 nowTime = getNow();
       uint256 week1 = startTime + (7 days);
       uint256 week2 = startTime + (14 days);
       uint256 week3 = startTime + (21 days);
       uint256 week4 = startTime + (14 days);

       if (nowTime <= week1) {
           bonusRate = 15;
       }else if (nowTime <= week2) {
           bonusRate = 15;
       }else if (nowTime <= week3) {
           bonusRate = 10;
       } else if (nowTime <= week4) {
           bonusRate = 10;
       }
         }
       return bonusRate;
   }
   	 
    function getVolumebasedBonusRate(uint256 value) internal constant returns (uint256) {
        uint256 bonusRate = 0;
        if (stage == Stage.PRESALE) {
            uint256 volume = value.div(1 ether);
        if (volume >= 70 && volume <= 100 ) {
            bonusRate = 15;
        }else if (volume >= 40 && volume <= 69 ) {
            bonusRate = 10;
        }else if (volume >= 10 && volume <= 39 ) {
            bonusRate = 5;
        }
        }
        return bonusRate;
        }
   	 
  	function startPublicsale(uint256 _startTime, uint256 _endTime) public onlyOwner {
      	require(_endTime >= _startTime);
      	stage = Stage.PUBLICSALE;
      	 
      	startTime = _startTime;
      	endTime = _endTime;
   }

  	 
  	function isMinimumGoalReached() public constant returns (bool reached) {
        return weiRaised >= softCap;
  	}

      
    function changeEnd(uint256 _endTime) public onlyOwner {
    	require(_endTime!=0);
        endTime = _endTime;
        
    }

     
   	function changeRate(uint256 _rate) public onlyOwner {
     	require(_rate != 0);
      	rate = _rate;

   }
   

     
    function transferAdvisorsToken(address _to, uint256 _value) onlyOwner {
    	require (
           _to != 0x0 && _value > 0 && advisorsAllocation >= _value
        );
        token.mint(_to, _value);
        advisorsAllocation = advisorsAllocation.sub(_value);
    }

     
    function transferMarketallocationTokens(address _to, uint256 _value) onlyOwner {
        require (
           _to != 0x0 && _value > 0 && marketAllocation >= _value
        );
        token.mint(_to, _value);
        marketAllocation = marketAllocation.sub(_value);
	}
	

	 
	function transferFounderTokens(address _to, uint256 _value) onlyOwner {
        require (
           _to != 0x0 && _value > 0 && founderAllocation >= _value
        );
        token.mint(_to, _value);
        founderAllocation = founderAllocation.sub(_value);
    }

     
	function burnToken(uint256 _value) onlyOwner {
    	require(_value > 0);
     	publicAllocation = publicAllocation.sub(_value);

    	Burn(msg.sender, _value);
	}
}