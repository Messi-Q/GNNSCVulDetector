pragma solidity ^0.4.18;

 
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

 
contract ERC20Basic {
	function totalSupply() public view returns (uint256);
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

 
contract KOIOSToken is StandardToken, Ownable {
	using SafeMath for uint256;

	string public name = "KOIOS";
	string public symbol = "KOI";
	uint256 public decimals = 5;

	uint256 public totalSupply = 1000000000 * (10 ** uint256(decimals));

	 
	function KOIOSToken(string _name, string _symbol, uint256 _decimals, uint256 _totalSupply) public {
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		totalSupply = _totalSupply;

		totalSupply_ = _totalSupply;
		balances[msg.sender] = totalSupply;
	}

	 
	function () public payable {
		revert();
	}
}

 
contract KOIOSTokenSale is Ownable {

	using SafeMath for uint256;

	 
	KOIOSToken public token;

	 
	uint256 public startingTimestamp = 1518696000;

	 
	uint256 public endingTimestamp = 1521115200;

	 
	uint256 public tokenPriceInEth = 0.0001 ether;

	 
	uint256 public tokensForSale = 400000000 * 1E5;

	 
	uint256 public totalTokenSold;

	 
	uint256 public totalEtherRaised;

	 
	mapping(address => uint256) public etherRaisedPerWallet;

	 
	address public wallet;

	 
	bool internal isClose = false;

	 
	event WalletChange(address _wallet, uint256 _timestamp);

	 
	event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount, uint256 _timestamp);

	 
	event TransferManual(address indexed _from, address indexed _to, uint256 _value, string _message);

	 
	function KOIOSTokenSale(address _token, uint256 _startingTimestamp, uint256 _endingTimestamp, uint256 _tokensPerEth, uint256 _tokensForSale, address _wallet) public {
		 
		token = KOIOSToken(_token);

		startingTimestamp = _startingTimestamp;
		endingTimestamp = _endingTimestamp;
		tokenPriceInEth =  1E18 / _tokensPerEth;  
		tokensForSale = _tokensForSale;

		 
		wallet = _wallet;
	}

	 
	function isValidPurchase(uint256 value, uint256 amount) internal constant returns (bool) {
		 
		bool validTimestamp = startingTimestamp <= block.timestamp && endingTimestamp >= block.timestamp;

		 
		bool validValue = value != 0;

		 
		bool validRate = tokenPriceInEth > 0;

		 
		bool validAmount = tokensForSale.sub(totalTokenSold) >= amount && amount > 0;

		 
		return validTimestamp && validValue && validRate && validAmount && !isClose;
	}

	
	 
	function calculate(uint256 value) public constant returns (uint256) {
		uint256 tokenDecimals = token.decimals();
		uint256 tokens = value.mul(10 ** tokenDecimals).div(tokenPriceInEth);
		return tokens;
	}
	
	 
	function() public payable {
		buyTokens(msg.sender);
	}

	 
	function buyTokens(address beneficiary) public payable {
		require(beneficiary != address(0));

		 
		uint256 value = msg.value;

		 
		uint256 tokens = calculate(value);

		 
		require(isValidPurchase(value , tokens));

		 
		totalTokenSold = totalTokenSold.add(tokens);
		totalEtherRaised = totalEtherRaised.add(value);
		etherRaisedPerWallet[msg.sender] = etherRaisedPerWallet[msg.sender].add(value);

		 
		token.transfer(beneficiary, tokens);
		
		 
		TokenPurchase(msg.sender, beneficiary, value, tokens, now);
	}

	 
	function transferManual(address _to, uint256 _value, string _message) onlyOwner public returns (bool) {
		require(_to != address(0));

		 
		token.transfer(_to , _value);
		TransferManual(msg.sender, _to, _value, _message);
		return true;
	}

	 	
	function setWallet(address _wallet) onlyOwner public returns(bool) {
		 
		wallet = _wallet;
		WalletChange(_wallet , now);
		return true;
	}

	 
	function withdraw() onlyOwner public {
		wallet.transfer(this.balance);
	}

	 	
	function close() onlyOwner public {
		 
		uint256 tokens = token.balanceOf(this); 
		token.transfer(owner , tokens);

		 
		withdraw();

		 
		isClose = true;
	}
}


 
contract KOIOSTokenPreSale is Ownable {

	using SafeMath for uint256;

	 
	KOIOSToken public token;

	 
	uint256 public startingTimestamp = 1527811200;

	 
	uint256 public endingTimestamp = 1528156799;

	 
	uint256 public tokenPriceInEth = 0.00005 ether;

	 
	uint256 public tokensForSale = 400000000 * 1E5;

	 
	uint256 public totalTokenSold;

	 
	uint256 public totalEtherRaised;

	 
	mapping(address => uint256) public etherRaisedPerWallet;

	 
	address public wallet;

	 
	bool internal isClose = false;

	 
	event WalletChange(address _wallet, uint256 _timestamp);

	 
	event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _amount, uint256 _timestamp);

	 
	event TransferManual(address indexed _from, address indexed _to, uint256 _value, string _message);

	 
	mapping(address => uint256) public lockupPhase1;
	uint256 public phase1Duration = 90 * 86400;

	 
	mapping(address => uint256) public lockupPhase2;
	uint256 public phase2Duration = 120 * 86400;
	
	 
	mapping(address => uint256) public lockupPhase3;
	uint256 public phase3Duration = 150 * 86400;
	
	 
	mapping(address => uint256) public lockupPhase4;
	uint256 public phase4Duration = 180 * 86400;

	uint256 public totalLockedBonus; 

	 
	function KOIOSTokenPreSale(address _token, uint256 _startingTimestamp, uint256 _endingTimestamp, uint256 _tokensPerEth, uint256 _tokensForSale, address _wallet) public {
		 
		token = KOIOSToken(_token);

		startingTimestamp = _startingTimestamp;
		endingTimestamp = _endingTimestamp;
		tokenPriceInEth =  1E18 / _tokensPerEth;  
		tokensForSale = _tokensForSale;

		 
		wallet = _wallet;
	}

	 
	function isValidPurchase(uint256 value, uint256 amount) internal constant returns (bool) {
		 
		bool validTimestamp = startingTimestamp <= block.timestamp && endingTimestamp >= block.timestamp;

		 
		bool validValue = value != 0;

		 
		bool validRate = tokenPriceInEth > 0;

		 
		bool validAmount = tokensForSale.sub(totalTokenSold) >= amount && amount > 0;

		 
		return validTimestamp && validValue && validRate && validAmount && !isClose;
	}

	function getBonus(uint256 _value) internal pure returns (uint256) {
		uint256 bonus = 0; 
		if(_value >= 1E18) {
			bonus = _value.mul(50).div(1000);
		}if(_value >= 5E18) {
			bonus = _value.mul(75).div(1000);
		}if(_value >= 10E18) {
			bonus = _value.mul(100).div(1000);
		}if(_value >= 20E18) {
			bonus = _value.mul(150).div(1000);
		}if(_value >= 30E18) {
			bonus = _value.mul(200).div(1000);
		}
		return bonus;
	}
	

	 
	function calculate(uint256 value) public constant returns (uint256) {
		uint256 tokenDecimals = token.decimals();

		uint256 tokens = value.mul(10 ** tokenDecimals).div(tokenPriceInEth);
		return tokens;
	}

	function lockBonus(address _sender, uint bonusTokens) internal returns (bool) {
		uint256 lockedBonus = bonusTokens.div(4);

		lockupPhase1[_sender] = lockupPhase1[_sender].add(lockedBonus);
		lockupPhase2[_sender] = lockupPhase2[_sender].add(lockedBonus);
		lockupPhase3[_sender] = lockupPhase3[_sender].add(lockedBonus);
		lockupPhase4[_sender] = lockupPhase4[_sender].add(lockedBonus);
		totalLockedBonus = totalLockedBonus.add(bonusTokens);

		return true;
	}
	
	
	 
	function() public payable {
		buyTokens(msg.sender);
	}

	 
	function buyTokens(address beneficiary) public payable {
		require(beneficiary != address(0));

		 
		uint256 _value = msg.value;

		 
		uint256 tokens = calculate(_value);

		 
		uint256 bonusTokens = calculate(getBonus(_value));

		lockBonus(beneficiary, bonusTokens);

		uint256 _totalTokens = tokens.add(bonusTokens);
            
		 
		require(isValidPurchase(_value , _totalTokens));

		 
		totalTokenSold = totalTokenSold.add(_totalTokens);
		totalEtherRaised = totalEtherRaised.add(_value);
		etherRaisedPerWallet[msg.sender] = etherRaisedPerWallet[msg.sender].add(_value);

		 
		token.transfer(beneficiary, tokens);

		
		 
		TokenPurchase(msg.sender, beneficiary, _value, tokens, now);
	}

	function isValidRelease(uint256 amount) internal constant returns (bool) {
		 
		bool validAmount = amount > 0;

		 
		return validAmount;
	}

	function releaseBonus() public {
		uint256 releaseTokens = 0;
		if(block.timestamp > (startingTimestamp.add(phase1Duration)))
		{
			releaseTokens = releaseTokens.add(lockupPhase1[msg.sender]);
			lockupPhase1[msg.sender] = 0;
		}
		if(block.timestamp > (startingTimestamp.add(phase2Duration)))
		{
			releaseTokens = releaseTokens.add(lockupPhase2[msg.sender]);
			lockupPhase2[msg.sender] = 0;
		}
		if(block.timestamp > (startingTimestamp.add(phase3Duration)))
		{
			releaseTokens = releaseTokens.add(lockupPhase3[msg.sender]);
			lockupPhase3[msg.sender] = 0;
		}
		if(block.timestamp > (startingTimestamp.add(phase4Duration)))
		{
			releaseTokens = releaseTokens.add(lockupPhase4[msg.sender]);
			lockupPhase4[msg.sender] = 0;
		}

		 
		totalLockedBonus = totalLockedBonus.sub(releaseTokens);
		token.transfer(msg.sender, releaseTokens);
	}

	function releasableBonus(address _owner) public constant returns (uint256) {
		uint256 releaseTokens = 0;
		if(block.timestamp > (startingTimestamp.add(phase1Duration)))
		{
			releaseTokens = releaseTokens.add(lockupPhase1[_owner]);
		}
		if(block.timestamp > (startingTimestamp.add(phase2Duration)))
		{
			releaseTokens = releaseTokens.add(lockupPhase2[_owner]);
		}
		if(block.timestamp > (startingTimestamp.add(phase3Duration)))
		{
			releaseTokens = releaseTokens.add(lockupPhase3[_owner]);
		}
		if(block.timestamp > (startingTimestamp.add(phase4Duration)))
		{
			releaseTokens = releaseTokens.add(lockupPhase4[_owner]);
		}
		return releaseTokens;		
	}

	 
	function transferManual(address _to, uint256 _value, string _message) onlyOwner public returns (bool) {
		require(_to != address(0));

		 
		token.transfer(_to , _value);
		TransferManual(msg.sender, _to, _value, _message);
		return true;
	}

	 	
	function setWallet(address _wallet) onlyOwner public returns(bool) {
		 
		wallet = _wallet;
		WalletChange(_wallet , now);
		return true;
	}

	 
	function withdraw() onlyOwner public {
		wallet.transfer(this.balance);
	}

	 	
	function close() onlyOwner public {
		 
		uint256 tokens = token.balanceOf(this).sub(totalLockedBonus); 
		token.transfer(owner , tokens);

		 
		withdraw();

		 
		isClose = true;
	}
}