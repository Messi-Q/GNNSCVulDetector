pragma solidity ^0.4.18;

 

 
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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 

contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

contract JcnToken is CappedToken {

	string public name = "JizzCoins";
	string public symbol = "JCN";
	uint8 public decimals = 18;

	uint256 public constant HARD_CAP = 100000000 * (10 ** uint256(18));			 

	 
	function JcnToken() public
	CappedToken(HARD_CAP) 
	{	
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

 

contract JcnCrowdsale is Crowdsale {

	uint256 public constant FOUNDERS_SHARE = 30000000 * (10 ** uint256(18));	 
	uint256 public constant RESERVE_FUND = 15000000 * (10 ** uint256(18));		 
	uint256 public constant CONTENT_FUND = 5000000 * (10 ** uint256(18));		 
	uint256 public constant BOUNTY_FUND = 5000000 * (10 ** uint256(18));		 

	 
	enum IcoPhases { EarlyBirdPresale, Presale, EarlyBirdCrowdsale, FullCrowdsale }
	struct Phase {
		uint256 startTime;
		uint256 endTime;
		uint256 minimum;	 
		uint8 bonus;
	}
	mapping (uint => Phase) ico;

	 
	function JcnCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public
	Crowdsale(_startTime, _endTime, _rate, _wallet) 
	{       
		 

		 
		ico[uint(IcoPhases.EarlyBirdPresale)] = Phase(1515578400, 1516442399, 750000000000000000, 25);	
		
		 
		ico[uint(IcoPhases.Presale)] = Phase(1516442400, 1517479199, 500000000000000000, 15);
		
		 
		ico[uint(IcoPhases.EarlyBirdCrowdsale)] = Phase(1517479200, 1518256799, 250000000000000000, 5);
		
		 
		ico[uint(IcoPhases.FullCrowdsale)] = Phase(1518256800, 1523350799, 1000000000000000, 0);

		 
		uint256 reserved_tokens = FOUNDERS_SHARE.add(RESERVE_FUND).add(CONTENT_FUND).add(BOUNTY_FUND);
		token.mint(wallet, reserved_tokens);
	}

	 
	function createTokenContract() internal returns (MintableToken) {
		return new JcnToken();
	}

	 
	 
	function buyTokens(address beneficiary) public payable {
		require(beneficiary != address(0));
		require(validPurchase());

		uint256 weiAmount = msg.value;

		 
		uint256 tokens = weiAmount.mul(rate);

		 
		 

		 
		uint256 minimum = currentIcoPhaseMinimum();

		 
		require(weiAmount >= minimum);

		 
		uint bonus = currentIcoPhaseBonus();

		 
		tokens = tokens.add((tokens.mul(bonus)).div(100));

		 
		 

		 
		weiRaised = weiRaised.add(weiAmount);

		token.mint(beneficiary, tokens);
		TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

		forwardFunds();
	}

	 
	function currentIcoPhaseBonus() public view returns (uint8) {

		for (uint i = 0; i < 4; i++) {
			if(ico[i].startTime <= now && ico[i].endTime >= now){
				return ico[i].bonus;
			}
		}
		return 0;	 
	}

	 
	function currentIcoPhaseMinimum() public view returns (uint256) {

		for (uint i = 0; i < 4; i++) {
			if(ico[i].startTime <= now && ico[i].endTime >= now){
				return ico[i].minimum;
			}
		}
		return 0;	 
	}
}