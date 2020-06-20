pragma solidity 0.4.23;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
  	require(msg.sender != address(0));

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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
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

contract EthernalCup is Ownable {
	using SafeMath for uint256;


	 
	event Buy(
		address owner,
		uint country,
		uint price
	);

	event BuyCup(
		address owner,
		uint price
	);

	uint public constant LOCK_START = 1531663200;  
	uint public constant LOCK_END = 1500145200;  
	uint public constant TOURNAMENT_ENDS = 1531677600;  

	int public constant BUY_INCREASE = 20;

	uint startPrice = 0.1 ether;

	 
	 
	uint cupStartPrice = 25 ether;

	uint public constant DEV_FEE = 3;
	uint public constant POOL_FEE = 5;

	bool public paused = false;

	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 

	struct Country {
		address owner;
		uint8 id;
		uint price;
	}

	struct EthCup {
		address owner;
		uint price;
	}

	EthCup public cup;

	mapping (address => uint) public balances;
	mapping (uint8 => Country) public countries;

	 
	 
	address public withdrawWallet;

	function () public payable {

		balances[withdrawWallet] += msg.value;
	}

	constructor() public {
		require(msg.sender != address(0));

		withdrawWallet = msg.sender;
	}

	modifier unlocked() {
		require(getTime() < LOCK_START || getTime() > LOCK_END);
		_;
	}

	 
	modifier isPaused() {
		require(paused == true);
		_;
	}

	 
	modifier buyAvailable() {
		require(paused == false);
		_;
	}

	 
	modifier cupAvailable() {
		require(cup.owner != address(0));
		_;
	}

	function addCountries() external onlyOwner {

		for(uint8 i = 0; i < 32; i++) {
			countries[i] = Country(withdrawWallet, i, startPrice);
		}			
	}

	 
	 
	function setWithdrawWallet(address _address) external onlyOwner {

		uint balance = balances[withdrawWallet];

		balances[withdrawWallet] = 0;  

		withdrawWallet = _address;

		 
		balances[withdrawWallet] = balance;
	}


	 
	 
	function buy(uint8 id) external payable buyAvailable unlocked {

		require(id < 32);
		
		uint price = getPrice(countries[id].price);

		require(msg.value > startPrice);
		require(msg.value >= price);

		uint fee = msg.value.mul(DEV_FEE).div(100);

		 
		balances[countries[id].owner] += msg.value.sub(fee);
	

		 
		balances[withdrawWallet] += fee;

		 
		countries[id].owner = msg.sender;
		countries[id].price = msg.value;

		 
		emit Buy(msg.sender, id, msg.value);

	}

	 
	function buyCup() external payable buyAvailable cupAvailable {

		uint price = getPrice(cup.price);

		require(msg.value >= price);

		uint fee = msg.value.mul(DEV_FEE).div(100);

		 
		balances[cup.owner] += msg.value.sub(fee);
	
		 
		balances[withdrawWallet] += fee;

		 
		cup.owner = msg.sender;
		cup.price = msg.value;

		 
		emit BuyCup(msg.sender, msg.value);

	}

	 
	function getPrice(uint price) public pure returns (uint) {

		return uint(int(price) + ((int(price) * BUY_INCREASE) / 100));
	}


	 
	function withdraw() external returns (bool) {

		uint amount = balances[msg.sender];

		require(amount > 0);

		balances[msg.sender] = 0;

		if(!msg.sender.send(amount)) {
			balances[msg.sender] = amount;

			return false;
		}

		return true;
	}

	 
	function getBalance() external view returns(uint) {
		return balances[msg.sender];
	}

	 
	function getBalanceByAddress(address user) external view onlyOwner returns(uint) {
		return balances[user];
	}

	 
	 
	function getCountryById(uint8 id) external view returns (address, uint, uint) {
		return (
			countries[id].owner,
			countries[id].id,
			countries[id].price
		);
	}

	 
	 
	 
	 
	function pause() external onlyOwner {

		require(paused == false);

		paused = true;
	}

	 
	function resume() external onlyOwner {

		require(paused == true);

		paused = false;
	}

	 
	 
	function awardCup(uint8 id) external onlyOwner isPaused {

		address owner = countries[id].owner;

		require(getTime() > TOURNAMENT_ENDS);
		require(cup.owner == address(0));
		require(cup.price == 0);
		require(owner != address(0));

		cup = EthCup(owner, cupStartPrice);

	}

	function getTime() public view returns (uint) {
		return now;
	}

}