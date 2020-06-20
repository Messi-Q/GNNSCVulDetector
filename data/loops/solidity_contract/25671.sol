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

 
contract ERC20 {
	 

	function totalSupply() public view returns (uint256);
	function balanceOf(address who) public view returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function allowance(address owner, address spender) public view returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);

}


 
contract StandardToken is ERC20 {

	using SafeMath for uint256;

	mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) internal allowed;


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


 
contract CYBC is StandardToken, Ownable{
	using SafeMath for uint256;

	string public name = "CybCoin";
	string public symbol = "CYBC";
	uint8 public constant decimals = 8;

	uint256 private _N = (10 ** uint256(decimals));
	uint256 public INITIAL_SUPPLY = _N.mul(1000000000);
	uint256 public endTime = 1530403200;
	uint256 public cap = _N.mul(200000000);
	uint256 public rate = 6666;
	uint256 public totalTokenSales = 0;

	mapping(address => uint8) public ACL;
	mapping (address => string) public keys;
	event LogRegister (address _user, string _key);

	address public wallet = 0x7a0035EA0F2c08aF87Cc863D860d669505EA0b20;
	address public accountS = 0xe0b91C928DbC439399ed6babC4e6A0BeC2F048C7;
	address public accountA = 0x98207620eC7346471C98DDd1A4C7c75d344C344f;
	address public accountB = 0x6C7A09b9283c364a7Dff11B4fb4869B211D21fCb;
	address public accountC = 0x8df62d0B4a8b1131119527a148A9C54D4cC7F91D;

	 
	function CYBC() public {
		totalSupply_ = INITIAL_SUPPLY;

		balances[accountS] = _N.mul(200000000);
		balances[accountA] = _N.mul(300000000);
		balances[accountB] = _N.mul(300000000);
		balances[accountC] = _N.mul(200000000);

		ACL[wallet]=1;
		ACL[accountS]=1;
		ACL[accountA]=1;
		ACL[accountB]=1;
		ACL[accountC]=1;
	}

	function transfer(address _to, uint256 _value) public isSaleClose returns (bool) {
		require(ACL[msg.sender] != 2);
		require(ACL[_to] != 2);

		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value)  public isSaleClose returns (bool) {
		require(ACL[msg.sender] != 2);
		require(ACL[_from] != 2);
		require(ACL[_to] != 2);

		return super.transferFrom(_from, _to, _value);
	}

	function setRate(uint256 _rate)  public onlyOwner {
		require(_rate > 0);
		rate = _rate;
	}

	function () public payable {
		ethSale(msg.sender);
	}

	function ethSale(address _beneficiary) public isSaleOpen payable {
		require(_beneficiary != address(0));
		require(msg.value != 0);
		uint256 ethInWei = msg.value;
		uint256 tokenWeiAmount = ethInWei.div(10**10);
		uint256 tokens = tokenWeiAmount.mul(rate);
		totalTokenSales = totalTokenSales.add(tokens);
		wallet.transfer(ethInWei);
		balances[accountS] = balances[accountS].sub(tokens);
		balances[_beneficiary] = balances[_beneficiary].add(tokens);
		Transfer(accountS, _beneficiary, tokens);
	}

	function cashSale(address _beneficiary, uint256 _tokens) public isSaleOpen onlyOwner {
		require(_beneficiary != address(0));
		require(_tokens != 0);
		totalTokenSales = totalTokenSales.add(_tokens);
		balances[accountS] = balances[accountS].sub(_tokens);
		balances[_beneficiary] = balances[_beneficiary].add(_tokens);
		Transfer(accountS, _beneficiary, _tokens);
	}

	modifier isSaleOpen() {
		require(totalTokenSales < cap);
		require(now < endTime);
		_;
	}

	modifier isSaleClose() {
		if( ACL[msg.sender] != 1 )  {
			require(totalTokenSales >= cap || now >= endTime);
		}
		_;
	}

	function setWallet(address addr) onlyOwner public {
		require(addr != address(0));
		wallet = addr;
	}
	function setAccountA(address addr) onlyOwner public {
		require(addr != address(0));
		accountA = addr;
	}

	function setAccountB(address addr) onlyOwner public {
		require(addr != address(0));
		accountB = addr;
	}

	function setAccountC(address addr) onlyOwner public {
		require(addr != address(0));
		accountC = addr;
	}

	function setAccountS(address addr) onlyOwner public {
		require(addr != address(0));
		accountS = addr;
	}

	function setACL(address addr,uint8 flag) onlyOwner public {
		require(addr != address(0));
		require(flag >= 0);
		require(flag <= 255);
		ACL[addr] = flag;
	}

	function setName(string _name)  onlyOwner public {
		name = _name;
	}

	function setSymbol(string _symbol) onlyOwner public {
		symbol = _symbol;
	}

	function register(string _key) public {
		require(ACL[msg.sender] != 2);
		require(bytes(_key).length <= 128);
		keys[msg.sender] = _key;
		LogRegister(msg.sender, _key);
	}

}