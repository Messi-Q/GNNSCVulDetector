pragma solidity ^0.4.21;

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
	function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
	function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
}

contract CryptoQuantumTradingFund is ERC20Interface {
	
	
	 

	function totalSupply()public constant returns (uint) {
		return fixTotalBalance;
	}
	
	function balanceOf(address tokenOwner)public constant returns (uint balance) {
		return balances[tokenOwner];
	}

	function transfer(address to, uint tokens)public returns (bool success) {
		if (balances[msg.sender] >= tokens && tokens > 0 && balances[to] + tokens > balances[to]) {
			if(msg.sender == creatorsAddress)  
			{
				TryUnLockCreatorBalance();
				if(balances[msg.sender] < (creatorsLocked + tokens))
				{
					return false;
				}
			}
			balances[msg.sender] -= tokens;
			balances[to] += tokens;
			emit Transfer(msg.sender, to, tokens);
			return true;
		} else {
			return false;
		}
	}

	function transferFrom(address from, address to, uint tokens)public returns (bool success) {
		if (balances[from] >= tokens && allowed[from][msg.sender] >= tokens && tokens > 0 && balances[to] + tokens > balances[to]) {
			if(from == creatorsAddress)  
			{
				TryUnLockCreatorBalance();
				if(balances[from] < (creatorsLocked + tokens))
				{
					return false;
				}
			}
			balances[from] -= tokens;
			allowed[from][msg.sender] -= tokens;
			balances[to] += tokens;
			emit Transfer(from, to, tokens);
			return true;
		} else {
			return false;
		}
	}
	
	
	function approve(address spender, uint tokens)public returns (bool success) {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}
	
	function allowance(address tokenOwner, address spender)public constant returns (uint remaining) {
		return allowed[tokenOwner][spender];
	}
	

	
	event Transfer(address indexed from, address indexed to, uint tokens); 
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);  

	 
		
    string public name = "CryptoQuantumTradingFund";
    string public symbol = "CQTF";
    uint8 public decimals = 18;
	uint256 private fixTotalBalance = 100000000000000000000000000;
	uint256 private _totalBalance =    92000000000000000000000000;
	uint256   public creatorsLocked =  8000000000000000000000000;  
	
	address public owner = 0x0;
	
    	mapping (address => uint256) balances;
	mapping(address => mapping (address => uint256)) allowed;
	
	uint  constant    private ONE_DAY_TIME_LEN = 86400;  
	uint  constant    private ONE_YEAR_TIME_LEN = 946080000;  
	uint32 private constant MAX_UINT32 = 0xFFFFFFFF;
	
	
	address public creatorsAddress = 0xbcabf04377034e4eC3C20ACaD2CA093559Ee9742;  
	
	uint      public unLockIdx = 2;		 
	uint      public nextUnLockTime = block.timestamp + ONE_YEAR_TIME_LEN;	 

	
	


    function CryptoQuantumTradingFund() public {
	
		owner = msg.sender;
		balances[creatorsAddress] = creatorsLocked;
		balances[owner] = _totalBalance;
       
    }

	
	
	
	 
	function TryUnLockCreatorBalance() public {
		while(unLockIdx > 0 && block.timestamp >= nextUnLockTime){  
			uint256 append = creatorsLocked/unLockIdx;
			creatorsLocked -= append;
			
			unLockIdx -= 1;
			nextUnLockTime = block.timestamp + ONE_YEAR_TIME_LEN;
		}
	}
	
	function () public payable
    {
    }
	
	function Save() public {
		if (msg.sender != owner) revert();

		owner.transfer(address(this).balance);
    }
	
	
	function changeOwner(address newOwner) public {
		if (msg.sender != owner) 
		{
		    revert();
		}
		else
		{
			owner = newOwner;
		}
    }
	
	function destruct() public {
		if (msg.sender != owner) 
		{
		    revert();
		}
		else
		{
			selfdestruct(owner);
		}
    }
}