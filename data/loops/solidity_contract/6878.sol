pragma solidity ^0.4.18;

 
 
 
contract SafeMath {
  uint256 constant private MAX_UINT256 =
  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  function safeAdd (uint256 x, uint256 y) constant internal returns (uint256 z) {
    assert (x <= MAX_UINT256 - y);
    return x + y;
  }

  function safeSub (uint256 x, uint256 y) constant internal returns (uint256 z) {
    assert (x >= y);
    return x - y;
  }

  function safeMul (uint256 x, uint256 y)  constant internal  returns (uint256 z) {
    if (y == 0) return 0;  
    assert (x <= MAX_UINT256 / y);
    return x * y;
  }
  
  
   function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 
contract RebateCoin is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals = 18;
    uint256 private _supply;
    uint256 private _totalSupply;

    uint public tokenPrice = 100 * (10**13);  
 
	uint private SaleStage1_start = 1527811200;
	uint256 private SaleStage1_supply = 24 * (10**24);
	uint private SaleStage1_tokenPrice = 84 * (10**13);  

	uint private SaleStage2_start = 1530403200;
	uint256 private SaleStage2_supply = 10 * (10**24);
	uint private SaleStage2_tokenPrice = 108 * (10**13);  

	uint private SaleStage3_start = 1533081600;
	uint256 private SaleStage3_supply = 50 * (10**24);
	uint private SaleStage3_tokenPrice = 134 * (10**13);  
	
    uint public startDate = 1527811200;
    uint public endDate = 1535760000;

	uint256 public bounty = 10 * (10**23);

	uint256 public hardcap = 22800 ether;
	uint256 public softcap = 62250 ether;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    function RebateCoin() public {
        symbol = "RBC";
        name = "Rebate Coin";
	_totalSupply = safeAdd(_totalSupply, bounty);
	 
    }


     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function reward_list(address[] memory to, uint[] memory tokens) public returns (bool success) {
	require(msg.sender == owner);
        require(to.length == tokens.length);
	    for (uint i = 0; i < to.length; ++i) {
		reward(to[i],tokens[i]);
	    }
        return true;
    }
    
    function reward(address to, uint tokens) public returns (bool success) {
        require(msg.sender == owner);
	require( tokens <= bounty);		
	bounty = safeSub(bounty, tokens);
	balances[to] = safeAdd(balances[to], tokens);
	
        Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        if (tokens > 0 && from != to) {
            allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            Transfer(from, to, tokens);
	}
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
    function extendDeadline(uint _newDeadline) public returns (bool success){
        require(msg.sender == owner);
        require(_newDeadline > 0);
        endDate = _newDeadline;
        return true;
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

     
     
     
    function () public payable {
        require(now >= startDate && now <= endDate);
        uint tokens;
        if (now >= SaleStage3_start) {
            tokens = safeDiv(msg.value * (10**18),SaleStage3_tokenPrice);
	    _supply = safeAdd(SaleStage3_supply,safeAdd(SaleStage2_supply,SaleStage1_supply));
        } else if(now >= SaleStage2_start) {
            tokens = safeDiv(msg.value * (10**18),SaleStage2_tokenPrice);
	    _supply = safeAdd(SaleStage2_supply,SaleStage1_supply);
        } else if(now >= SaleStage1_start) {
            tokens = safeDiv(msg.value * (10**18),SaleStage1_tokenPrice);
	    _supply = SaleStage1_supply;
	} else {}
	
	require( safeAdd(_totalSupply, tokens) <= _supply);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}