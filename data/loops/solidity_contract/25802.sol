pragma solidity ^0.4.18;


 
contract ERC20Basic {
	uint256 public totalSupply;
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract DetailedERC20 is ERC20 {
	string public name;
	string public symbol;
	uint8 public decimals;

	function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
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


 
contract Pausable is Ownable {
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

	 
	function pause() onlyOwner whenNotPaused public {
		paused = true;
		Pause();
	}

	 
	function unpause() onlyOwner whenPaused public {
		paused = false;
		Unpause();
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

 
contract BurnableToken is BasicToken {

	event Burn(address indexed burner, uint256 value);

	 
	function burn(uint256 _value) public {
		require(_value <= balances[msg.sender]);
		 
		 

		address burner = msg.sender;
		balances[burner] = balances[burner].sub(_value);
		totalSupply = totalSupply.sub(_value);
		Burn(burner, _value);
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


 

contract PausableToken is StandardToken, Pausable {

	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
		return super.approve(_spender, _value);
	}

	function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
		return super.increaseApproval(_spender, _addedValue);
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
		return super.decreaseApproval(_spender, _subtractedValue);
	}
}

contract BftToken is DetailedERC20, CappedToken, BurnableToken, PausableToken {

	CappedCrowdsale public crowdsale;

	function BftToken(
		uint256 _tokenCap,
		uint8 _decimals,
		CappedCrowdsale _crowdsale
	)
	DetailedERC20("BF Token", "BFT", _decimals)
	CappedToken(_tokenCap) public {

		crowdsale = _crowdsale;
	}

	 
	 

	MintableToken public newToken = MintableToken(0x0);
	event LogRedeem(address beneficiary, uint256 amount);

	modifier hasUpgrade() {
		require(newToken != MintableToken(0x0));
		_;
	}

	function upgrade(MintableToken _newToken) onlyOwner public {
		newToken = _newToken;
	}

	 
	function burn(uint256 _value) public {
		revert();
		_value = _value;  
	}

	function redeem() hasUpgrade public {

		var balance = balanceOf(msg.sender);

		 
		super.burn(balance);

		 
		require(newToken.mint(msg.sender, balance));
		LogRedeem(msg.sender, balance);
	}

	 
	 

	modifier canDoTransfers() {
		require(hasCrowdsaleFinished());
		_;
	}

	function hasCrowdsaleFinished() view public returns(bool) {
		return crowdsale.hasEnded();
	}

	function transfer(address _to, uint256 _value) public canDoTransfers returns (bool) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public canDoTransfers returns (bool) {
		return super.transferFrom(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public canDoTransfers returns (bool) {
		return super.approve(_spender, _value);
	}

	function increaseApproval(address _spender, uint _addedValue) public canDoTransfers returns (bool success) {
		return super.increaseApproval(_spender, _addedValue);
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public canDoTransfers returns (bool success) {
		return super.decreaseApproval(_spender, _subtractedValue);
	}

	 
	 

	function changeSymbol(string _symbol) onlyOwner public {
		symbol = _symbol;
	}

	function changeName(string _name) onlyOwner public {
		name = _name;
	}
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

contract BftCrowdsale is CappedCrowdsale, Pausable {

	uint8 public constant tokenDecimals = 18;
	uint256 public constant etherInWei = 10**uint256(tokenDecimals);
	uint256 public constant tokenCap = 1000000000 * etherInWei;

	uint256 public SALE_CAP_USD;
	uint256 public BUYER_CAP_LOW_USD;
	uint256 public BUYER_CAP_HIGH_USD;

	uint256 public constant PRICE_MULTIPLIER = 100;
	uint256 public constant TOKENS_PER_USD = 10;

	uint256 public etherPrice = PRICE_MULTIPLIER;
	uint256 public buyerCapLowEther = etherInWei;
	uint256 public buyerCapHighEther = etherInWei;
	uint256 public saleHardCapEther = etherInWei;
	uint256 public mintRate = TOKENS_PER_USD;

	address public preSaleBfPlatform;
	address public company;
	address public rewardPool;
	address public shareholders;
	address public tokenSaleCosts;

	 
	TokenTimelock public companyHolding2y;
	TokenTimelock public shareholdersHolding1y;

	 
	mapping(address => bool) whitelist;

	mapping(address => bool) operators;
	event LogOperatorAdd(address newOperator);
	event LogOperatorRem(address newOperator);

	modifier onlyOperator() {
		require(operators[msg.sender]);
		_;
	}

	modifier onlyWhitelisted(address _address) {
		require(whitelist[_address]);
		_;
	}

	function BftCrowdsale(
		uint256 _startTime,
		uint256 _endTime,
		uint256 _etherPrice,
		address _wallet,

	 
		address _preSaleBfPlatform,
		address _company,
		address _rewardPool,
		address _shareholders,
		address _tokenSaleCosts,

	 
		address _operator,
		address _admin,

		uint256 _saleCapUsd,
		uint256 _buyerCapLowUsd,
		uint256 _buyerCapHighUsd
	)
	CappedCrowdsale(saleHardCapEther)
	Crowdsale(_startTime, _endTime, mintRate, _wallet) public {

		require(_preSaleBfPlatform != address(0x0));
		require(_company != address(0x0));
		require(_rewardPool != address(0x0));
		require(_shareholders != address(0x0));
		require(_tokenSaleCosts != address(0x0));
		require(_operator != address(0x0));

		SALE_CAP_USD = _saleCapUsd;
		BUYER_CAP_LOW_USD = _buyerCapLowUsd;
		BUYER_CAP_HIGH_USD = _buyerCapHighUsd;

		preSaleBfPlatform = _preSaleBfPlatform;
		company = _company;
		rewardPool = _rewardPool;
		shareholders = _shareholders;
		tokenSaleCosts = _tokenSaleCosts;

		addOperator(_operator);
		updateEtherPrice(_etherPrice);
		createHoldings();
		preMintTokens();

		 
		transferOwnership(_admin);
	}

	function updateEtherPrice(uint256 _price) onlyOwner public {
		require(_price > 0);
		require(now < startTime);

		etherPrice = _price;
		buyerCapLowEther = BUYER_CAP_LOW_USD.mul(etherInWei).mul(PRICE_MULTIPLIER).div(etherPrice);
		buyerCapHighEther = BUYER_CAP_HIGH_USD.mul(etherInWei).mul(PRICE_MULTIPLIER).div(etherPrice);
		saleHardCapEther = SALE_CAP_USD.mul(etherInWei).mul(PRICE_MULTIPLIER).div(etherPrice);
		mintRate = TOKENS_PER_USD.mul(etherPrice).div(PRICE_MULTIPLIER);

		 
		cap = saleHardCapEther;
		rate = mintRate;
	}

	function createHoldings() internal {
		companyHolding2y = new TokenTimelock(token, company, startTime+2 years);
		shareholdersHolding1y = new TokenTimelock(token, shareholders, startTime+1 years);
	}

	function preMintTokens() internal {
		token.mint(preSaleBfPlatform, 300000000 * etherInWei);
		token.mint(companyHolding2y, 300000000 * etherInWei);
		token.mint(rewardPool, 200000000 * etherInWei);
		token.mint(shareholdersHolding1y, 100000000 * etherInWei);
		token.mint(tokenSaleCosts, 70000000 * etherInWei);
	}

	function checkSaleEnded() internal {
		 
		if(saleHardCapEther.sub(weiRaised) < buyerCapLowEther) {
			token.mint(rewardPool, tokenCap.sub(token.totalSupply()));
		}
	}

	 
	 
	function validPurchase() whenNotPaused
	internal view returns (bool) {
		bool aboveLowBuyerCap = (msg.value >= buyerCapLowEther);
		bool underMaxBuyerCap = (msg.value <= buyerCapHighEther);
		return super.validPurchase() && aboveLowBuyerCap && underMaxBuyerCap;
	}

	 
	 
	function hasEnded() public view returns (bool) {
		bool tokenCapReached = token.totalSupply() == tokenCap;
		return super.hasEnded() || tokenCapReached;
	}

	function buyTokens(address beneficiary)
	onlyWhitelisted(beneficiary)
	whenNotPaused
	public payable {
		require(token.balanceOf(beneficiary)==0);
		super.buyTokens(beneficiary);
		checkSaleEnded();
	}

	 
	 
	function createTokenContract() internal returns (MintableToken) {
		return new BftToken(tokenCap, tokenDecimals, this);
	}

	function addWhitelist(address[] beneficiaries) onlyOperator public {
		for (uint i = 0; i < beneficiaries.length; i++) {
			whitelist[beneficiaries[i]] = true;
		}
	}

	function remWhitelist(address[] beneficiaries) onlyOperator public {
		for (uint i = 0; i < beneficiaries.length; i++) {
			whitelist[beneficiaries[i]] = false;
		}
	}

	function isWhitelisted(address beneficiary) view public returns(bool) {
		return whitelist[beneficiary];
	}

	function addOperator(address _operator) onlyOwner public {
		operators[_operator] = true;
		LogOperatorAdd(_operator);
	}

	function remOperator(address _operator) onlyOwner public {
		operators[_operator] = false;
		LogOperatorAdd(_operator);
	}

	function isOperator(address _operator) view public returns(bool) {
		return operators[_operator];
	}

	function transferTokenOwnership(address _newOwner) onlyOwner public {
		 
		require(hasEnded());
		 
		token.finishMinting();
		token.transferOwnership(_newOwner);
	}
}