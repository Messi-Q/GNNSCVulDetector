pragma solidity ^0.4.21;

 

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

contract JcnxxxToken is MintableToken {

	string public name = "JCN Token";
	string public symbol = "JCNXXX";
	uint8 public decimals = 18;
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

 
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

 

 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

 

contract JcnxxxCrowdsale is FinalizableCrowdsale, MintedCrowdsale, CappedCrowdsale {

	uint256 public constant FOUNDERS_SHARE = 30000000 * (10 ** uint256(18));	 
	uint256 public constant RESERVE_FUND = 15000000 * (10 ** uint256(18));		 
	uint256 public constant CONTENT_FUND = 5000000 * (10 ** uint256(18));		 
	uint256 public constant BOUNTY_FUND = 5000000 * (10 ** uint256(18));		 
	uint256 public constant HARD_CAP = 100000000 * (10 ** uint256(18));			 

	 
	enum IcoPhases { PrivateSale, EarlyBirdPresale, Presale, EarlyBirdCrowdsale, FullCrowdsale }
	struct Phase {
		uint256 startTime;
		uint256 endTime;
		uint256 minimum;	 
		uint8 bonus;
	}
	mapping (uint => Phase) ico;

	 
	function JcnxxxCrowdsale(uint256 _openingTime, uint256 _closingTime, uint256 _rate, address _wallet, MintableToken _token) public
	CappedCrowdsale(HARD_CAP.div(_rate))
	FinalizableCrowdsale()
	MintedCrowdsale()
	TimedCrowdsale(_openingTime, _closingTime)
	Crowdsale(_rate, _wallet, _token) 
	{       
		 

		 
		ico[uint(IcoPhases.PrivateSale)] = Phase(1531126800, 1537001999, 10000000000000000000, 50);	

		 
		ico[uint(IcoPhases.EarlyBirdPresale)] = Phase(1537002000, 1537865999, 750000000000000000, 25);	
		
		 
		ico[uint(IcoPhases.Presale)] = Phase(1537866000, 1538729999, 500000000000000000, 15);
		
		 
		ico[uint(IcoPhases.EarlyBirdCrowdsale)] = Phase(1538730000, 1539593999, 250000000000000000, 5);
		
		 
		ico[uint(IcoPhases.FullCrowdsale)] = Phase(1539594000, 1542275999, 1000000000000000, 2);
	}

	 
	function mintReservedTokens() onlyOwner public {

		 
		uint256 reserved_tokens = FOUNDERS_SHARE.add(RESERVE_FUND).add(CONTENT_FUND).add(BOUNTY_FUND);
		require(MintableToken(token).mint(wallet, reserved_tokens));
	}

	 
	function airdrop(address[] _to, uint256[] _value) onlyOwner public returns (bool) {

		 
		 
		require(!isFinalized);
		require(_to.length == _value.length);
        require(_to.length <= 100);

         
        for(uint8 i = 0; i < _to.length; i++) {
            require(MintableToken(token).mint(_to[i], (_value[i].mul((10 ** uint256(18))))) == true);
        }
        return true;
	}

	 
	 
	 

	 
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
		super._preValidatePurchase(_beneficiary, _weiAmount);

		 
		uint256 minimum = _currentIcoPhaseMinimum();

		 
		require(_weiAmount >= minimum);
	}

	 
	function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {

		uint256 tokens = _weiAmount.mul(rate);

		 
		uint bonus = _currentIcoPhaseBonus();

		 
		return tokens.add((tokens.mul(bonus)).div(100));
	}

	 
	function finalization() internal {

		uint256 _tokenAmount = HARD_CAP.sub(token.totalSupply());
		require(MintableToken(token).mint(wallet, _tokenAmount));

		super.finalization();
	}

	 
	 
	 

	 
	function _currentIcoPhaseBonus() public view returns (uint8) {

		for (uint i = 0; i < 5; i++) {
			if(ico[i].startTime <= now && ico[i].endTime >= now){
				return ico[i].bonus;
			}
		}
		return 0;	 
	}

	 
	function _currentIcoPhaseMinimum() public view returns (uint256) {

		for (uint i = 0; i < 5; i++) {
			if(ico[i].startTime <= now && ico[i].endTime >= now){
				return ico[i].minimum;
			}
		}
		return 0;	 
	}
}