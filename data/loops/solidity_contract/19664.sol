pragma solidity ^0.4.18;

 
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
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
		emit OwnershipTransferred(owner, newOwner);
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

 
contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length >= size + 4);
		_;
	}
	
	uint256 totalSupply_;

	 
	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	 
	function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);

		 
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
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

	 
	function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool) {
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
contract VVDB is StandardToken {
	string public constant name = "Voorgedraaide van de Blue";
	string public constant symbol = "VVDB";
	uint256 public constant decimals = 18;
	uint256 public constant initialSupply = 100000000 * (10 ** uint256(decimals));
	
	function VVDB(address _ownerAddress) public {
		totalSupply_ = initialSupply;
		 
		balances[_ownerAddress] = 80000000 * (10 ** uint256(decimals));
		balances[0xcD7f6b528F5302a99e5f69aeaa97516b1136F103] = 20000000 * (10 ** uint256(decimals));
	}
}

 

contract VVDBCrowdsale is Ownable {
	using SafeMath for uint256;

	 
	VVDB public token;

	 
	address public wallet;

	 
	uint256 public rate = 760;

	 
	uint256 public weiRaised;
	
	uint256 public round1TokensRemaning	= 6000000 * 1 ether;
	uint256 public round2TokensRemaning	= 6000000 * 1 ether;
	uint256 public round3TokensRemaning	= 6000000 * 1 ether;
	uint256 public round4TokensRemaning	= 6000000 * 1 ether;
	uint256 public round5TokensRemaning	= 6000000 * 1 ether;
	uint256 public round6TokensRemaning	= 6000000 * 1 ether;
	
	mapping(address => uint256) round1Balances;
	mapping(address => uint256) round2Balances;
	mapping(address => uint256) round3Balances;
	mapping(address => uint256) round4Balances;
	mapping(address => uint256) round5Balances;
	mapping(address => uint256) round6Balances;
	
	uint256 public round1StartTime = 1522864800;  
	uint256 public round2StartTime = 1522951200;  
	uint256 public round3StartTime = 1523037600;  
	uint256 public round4StartTime = 1523124000;  
	uint256 public round5StartTime = 1523210400;  
	uint256 public round6StartTime = 1523296800;  
	uint256 public icoEndTime = 1524506400;  
		
	 
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

	 
	event RateChanged(address indexed owner, uint256 oldRate, uint256 newRate);
	
	 
	function VVDBCrowdsale(address _token, address _wallet) public {
		require(_wallet != address(0));
		require(_token != address(0));

		wallet = _wallet;
		token = VVDB(_token);
	}

	 
	 
	 

	 
	function () external payable {
		buyTokens(msg.sender);
	}

	 
	function buyTokens(address _beneficiary) public payable {

		uint256 weiAmount = msg.value;
		_preValidatePurchase(_beneficiary, weiAmount);

		 
		uint256 tokens = _getTokenAmount(weiAmount);
		
		require(canBuyTokens(tokens));

		 
		weiRaised = weiRaised.add(weiAmount);

		_processPurchase(_beneficiary, tokens);

		updateRoundBalance(tokens);

		emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

		_updatePurchasingState(_beneficiary, weiAmount);

		_forwardFunds();
		_postValidatePurchase(_beneficiary, weiAmount);
	}

	 
	 
	 
	
	function canBuyTokens(uint256 _tokens) internal constant returns (bool) 
	{
		uint256 currentTime = now;
		uint256 purchaserTokenSum = 0;
		if (currentTime<round1StartTime || currentTime>icoEndTime) return false;

		if (currentTime >= round1StartTime && currentTime < round2StartTime)
		{
			purchaserTokenSum = _tokens + round1Balances[msg.sender];
			return purchaserTokenSum <= (10000 * (10 ** uint256(18))) && _tokens <= round1TokensRemaning;

		} else if (currentTime >= round2StartTime && currentTime < round3StartTime)
		{
			purchaserTokenSum = _tokens + round2Balances[msg.sender];
			return purchaserTokenSum <= (2000 * (10 ** uint256(18))) && _tokens <= round2TokensRemaning;

		} else if (currentTime >= round3StartTime && currentTime < round4StartTime)
		{
			purchaserTokenSum = _tokens + round3Balances[msg.sender];
			return purchaserTokenSum <= (2000 * (10 ** uint256(18))) && _tokens <= round3TokensRemaning;

		} else if (currentTime >= round4StartTime && currentTime < round5StartTime)
		{
			purchaserTokenSum = _tokens + round4Balances[msg.sender];
			return purchaserTokenSum <= (2000 * (10 ** uint256(18))) && _tokens <= round4TokensRemaning;

		} else if (currentTime >= round5StartTime && currentTime < round6StartTime)
		{
			purchaserTokenSum = _tokens + round5Balances[msg.sender];
			return purchaserTokenSum <= (2000 * (10 ** uint256(18))) && _tokens <= round5TokensRemaning;

		} else if (currentTime >= round6StartTime && currentTime < icoEndTime)
		{
			purchaserTokenSum = _tokens + round6Balances[msg.sender];
			return purchaserTokenSum <= (2000 * (10 ** uint256(18))) && _tokens <= round6TokensRemaning;
		}
	}
	
	function updateRoundBalance(uint256 _tokens) internal 
	{
		uint256 currentTime = now;

		if (currentTime >= round1StartTime && currentTime < round2StartTime)
		{
			round1Balances[msg.sender] = round1Balances[msg.sender].add(_tokens);
			round1TokensRemaning = round1TokensRemaning.sub(_tokens);

		} else if (currentTime >= round2StartTime && currentTime < round3StartTime)
		{
			round2Balances[msg.sender] = round2Balances[msg.sender].add(_tokens);
			round2TokensRemaning = round2TokensRemaning.sub(_tokens);

		} else if (currentTime >= round3StartTime && currentTime < round4StartTime)
		{
			round3Balances[msg.sender] = round3Balances[msg.sender].add(_tokens);
			round3TokensRemaning = round3TokensRemaning.sub(_tokens);

		} else if (currentTime >= round4StartTime && currentTime < round5StartTime)
		{
			round4Balances[msg.sender] = round4Balances[msg.sender].add(_tokens);
			round4TokensRemaning = round4TokensRemaning.sub(_tokens);

		} else if (currentTime >= round5StartTime && currentTime < round6StartTime)
		{
			round5Balances[msg.sender] = round5Balances[msg.sender].add(_tokens);
			round5TokensRemaning = round5TokensRemaning.sub(_tokens);

		} else if (currentTime >= round6StartTime && currentTime < icoEndTime)
		{
			round6Balances[msg.sender] = round6Balances[msg.sender].add(_tokens);
			round6TokensRemaning = round6TokensRemaning.sub(_tokens);
		}
	}

	 
	function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
	}

	 
	function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
	}

	 
	function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
		token.transfer(_beneficiary, _tokenAmount);
	}

	 
	function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
		_deliverTokens(_beneficiary, _tokenAmount);
	}

	 
	function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal pure {
		require(_beneficiary != address(0));
		require(_weiAmount != 0);
	}

	 
	function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
		return _weiAmount.mul(rate);
	}

	 
	function _forwardFunds() internal {
		wallet.transfer(msg.value);
	}
	
	function tokenBalance() constant public returns (uint256) {
		return token.balanceOf(this);
	}
	
	 
	function changeRate(uint256 _rate) onlyOwner public returns (bool) {
		emit RateChanged(msg.sender, rate, _rate);
		rate = _rate;
		return true;
	}
	
	 
	function getRate() public view returns (uint256) {
		return rate;
	}

	function transferBack(uint256 tokens) onlyOwner public returns (bool) {
		token.transfer(owner, tokens);
		return true;
	}
}