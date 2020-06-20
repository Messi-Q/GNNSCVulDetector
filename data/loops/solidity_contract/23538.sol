pragma solidity 0.4.19;

 
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

 
contract LendingBlockToken is StandardToken, BurnableToken, Ownable {
	string public constant name = "Lendingblock";
	string public constant symbol = "LND";
	uint8 public constant decimals = 18;
	uint256 public transferableTime = 1546300800; 
	address public tokenEventAddress;

	 
	modifier afterTransferableTime() {
		if (now <= transferableTime) {
			require(msg.sender == tokenEventAddress || msg.sender == owner);
		}
		_;
	}

	 
	function LendingBlockToken(address _owner) public {
		tokenEventAddress = msg.sender;
		owner = _owner;
		totalSupply = 1e9 * 1e18;
		balances[_owner] = totalSupply;
		Transfer(address(0), _owner, totalSupply);
	}

	 
	function transfer(address _to, uint256 _value)
		public
		afterTransferableTime
		returns (bool)
	{
		return super.transfer(_to, _value);
	}

	 
	function transferFrom(address _from, address _to, uint256 _value)
		public
		afterTransferableTime
		returns (bool)
	{
		return super.transferFrom(_from, _to, _value);
	}

	 
	function setTransferableTime(uint256 _transferableTime)
		external
		onlyOwner
	{
		require(_transferableTime < transferableTime);
		transferableTime = _transferableTime;
	}
}

 
contract LendingBlockTokenEvent is Ownable {
	using SafeMath for uint256;

	LendingBlockToken public token;
	address public wallet;
	bool public eventEnded;
	uint256 public startTimePre;
	uint256 public startTimeMain;
	uint256 public endTimePre;
	uint256 public endTimeMain;
	uint256 public ratePre;
	uint256 public rateMain;
	uint256 public minCapPre;
	uint256 public minCapMain;
	uint256 public maxCapPre;
	uint256 public maxCapMain;
	uint256 public weiTotal;
	mapping(address => bool) public whitelistedAddressPre;
	mapping(address => bool) public whitelistedAddressMain;
	mapping(address => uint256) public contributedValue;

	event TokenPre(address indexed participant, uint256 value, uint256 tokens);
	event TokenMain(address indexed participant, uint256 value, uint256 tokens);
	event SetPre(uint256 startTimePre, uint256 endTimePre, uint256 minCapPre, uint256 maxCapPre, uint256 ratePre);
	event SetMain(uint256 startTimeMain, uint256 endTimeMain, uint256 minCapMain, uint256 maxCapMain, uint256 rateMain);
	event WhitelistPre(address indexed whitelistedAddress, bool whitelistedStatus);
	event WhitelistMain(address indexed whitelistedAddress, bool whitelistedStatus);

	 
	modifier eventNotEnded() {
		require(eventEnded == false);
		_;
	}

	 
	function LendingBlockTokenEvent(address _wallet) public {
		token = new LendingBlockToken(msg.sender);
		wallet = _wallet;
	}

	 
	function joinPre()
		public
		payable
		eventNotEnded
	{
		require(now >= startTimePre); 
		require(now <= endTimePre); 
		require(msg.value >= minCapPre); 
		require(whitelistedAddressPre[msg.sender] == true); 

		uint256 weiValue = msg.value;
		contributedValue[msg.sender] = contributedValue[msg.sender].add(weiValue); 
		require(contributedValue[msg.sender] <= maxCapPre); 

		uint256 tokens = weiValue.mul(ratePre); 
		weiTotal = weiTotal.add(weiValue); 

		token.transfer(msg.sender, tokens); 
		TokenPre(msg.sender, weiValue, tokens); 

		forwardFunds(); 
	}

	 
	function joinMain()
		public
		payable
		eventNotEnded
	{
		require(now >= startTimeMain); 
		require(now <= endTimeMain); 
		require(msg.value >= minCapMain); 
		require(whitelistedAddressMain[msg.sender] == true); 

		uint256 weiValue = msg.value;
		contributedValue[msg.sender] = contributedValue[msg.sender].add(weiValue); 
		require(contributedValue[msg.sender] <= maxCapMain); 

		uint256 tokens = weiValue.mul(rateMain); 
		weiTotal = weiTotal.add(weiValue); 

		token.transfer(msg.sender, tokens); 
		TokenMain(msg.sender, weiValue, tokens); 

		forwardFunds(); 
	}

	 
	function forwardFunds() internal {
		wallet.transfer(msg.value);
	}

	 
	function setPre(
		uint256 _startTimePre,
		uint256 _endTimePre,
		uint256 _minCapPre,
		uint256 _maxCapPre,
		uint256 _ratePre
	)
		external
		onlyOwner
		eventNotEnded
	{
		require(now < _startTimePre); 
		require(_startTimePre < _endTimePre); 
		require(_minCapPre <= _maxCapPre); 
		startTimePre = _startTimePre;
		endTimePre = _endTimePre;
		minCapPre = _minCapPre;
		maxCapPre = _maxCapPre;
		ratePre = _ratePre;
		SetPre(_startTimePre, _endTimePre, _minCapPre, _maxCapPre, _ratePre);
	}

	 
	function setMain(
		uint256 _startTimeMain,
		uint256 _endTimeMain,
		uint256 _minCapMain,
		uint256 _maxCapMain,
		uint256 _rateMain
	)
		external
		onlyOwner
		eventNotEnded
	{
		require(now < _startTimeMain); 
		require(_startTimeMain < _endTimeMain); 
		require(_minCapMain <= _maxCapMain); 
		require(_startTimeMain > endTimePre); 
		startTimeMain = _startTimeMain;
		endTimeMain = _endTimeMain;
		minCapMain = _minCapMain;
		maxCapMain = _maxCapMain;
		rateMain = _rateMain;
		SetMain(_startTimeMain, _endTimeMain, _minCapMain, _maxCapMain, _rateMain);
	}

	 
	function setWhitelistedAddressPre(address[] whitelistedAddress, bool whitelistedStatus)
		external
		onlyOwner
		eventNotEnded
	{
		for (uint256 i = 0; i < whitelistedAddress.length; i++) {
			whitelistedAddressPre[whitelistedAddress[i]] = whitelistedStatus;
			WhitelistPre(whitelistedAddress[i], whitelistedStatus);
		}
	}

	 
	function setWhitelistedAddressMain(address[] whitelistedAddress, bool whitelistedStatus)
		external
		onlyOwner
		eventNotEnded
	{
		for (uint256 i = 0; i < whitelistedAddress.length; i++) {
			whitelistedAddressMain[whitelistedAddress[i]] = whitelistedStatus;
			WhitelistMain(whitelistedAddress[i], whitelistedStatus);
		}
	}

	 
	function endEvent()
		external
		onlyOwner
		eventNotEnded
	{
		require(now > endTimeMain); 
		require(endTimeMain > 0); 
		uint256 leftTokens = token.balanceOf(this); 
		if (leftTokens > 0) {
			token.burn(leftTokens); 
		}
		eventEnded = true; 
	}

	 
	function () external payable {
		if (now <= endTimePre) { 
			joinPre();
		} else if (now <= endTimeMain) { 
			joinMain();
		} else {
			revert();
		}
	}

}