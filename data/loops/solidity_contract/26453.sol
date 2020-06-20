pragma solidity ^0.4.0;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract MyFirstEthereumToken {
     
     
    address public owner;
	 
    string public name = "MyFirstEthereumToken";
    string public symbol = "MFET";
    uint8 public decimals = 18;	 
 
    uint256 public totalSupply; 
	uint256 public totalExtraTokens = 0;
	uint256 public totalContributed = 0;
	
	bool public onSale = false;

	 
    mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowance;

     
     
    event Sent(address from, address to, uint amount);
	 
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    event Burn(address indexed from, uint256 value);	
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

	function name() public constant returns (string) { return name; }
    function symbol() public constant returns (string) { return symbol; }
    function decimals() public constant returns (uint8) { return decimals; }
	function totalSupply() public constant returns (uint256) { return totalSupply; }
	function balanceOf(address _owner) public constant returns (uint256) { return balances[_owner]; }
	
     
    function MyFirstEthereumToken(uint256 initialSupply) public payable
	{
		owner = msg.sender;
		
		 
        totalSupply = initialSupply * 10 ** uint256(decimals);   
		 
		 
        balances[msg.sender] = totalSupply; 
		 
         
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success)
	{
        return _transfer(msg.sender, _to, _value);
    }
	
     
    function _transfer(address _from, address _to, uint _value) internal returns (bool success)
	{
		 
		 
		 
		require(_value > 0);
		 
        require(_to != 0x0);	      
		 
        require(balances[_from] >= _value);	
		 
        require(balances[_to] + _value > balances[_to]);	 
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
		 
        Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
		
		return true;
    }

     
    function send(address _to, uint256 _value) public 
	{
        _send(_to, _value);
    }
	
     
    function _send(address _to, uint256 _value) internal 
	{	
		address _from = msg.sender;
		
		 
		 
		 
		require(_value > 0);
		 
        require(_to != 0x0);	      
		 
        require(balances[_from] >= _value);	
		 
        require(balances[_to] + _value > balances[_to]);	 
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
		 
        Sent(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }

    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) 
	{
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) 
	{
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) 
	{
        tokenRecipient spender = tokenRecipient(_spender);
		
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
	
	 	
    function createTokens(uint256 _amount) public
	{
	    require(msg.sender == owner);
         
        
        balances[owner] += _amount; 
        totalSupply += _amount;
		
        Transfer(0, owner, _amount);
    }

	 	
    function safeWithdrawAll() public returns (bool)
	{
	    require(msg.sender == owner);
		
		uint256 _gasPrice = 30000000000;
		
		require(this.balance > _gasPrice);
		
		uint256 _totalAmount = this.balance - _gasPrice;
		
		owner.transfer(_totalAmount);
		
		return true;
    }
	
	 	
    function safeWithdraw(uint256 _amount) public returns (bool)
	{
	    require(msg.sender == owner);
		
		uint256 _gasPrice = 30000000000;
		
		require(_amount > 0);
		
		uint256 totalAmount = _amount + _gasPrice; 
		
		require(this.balance >= totalAmount);
		
		owner.transfer(totalAmount);
		
		return true;
    }
    
	function getBalanceContract() public constant returns(uint)
	{
		require(msg.sender == owner);
		
        return this.balance;
    }
	
	 
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);    
        balances[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balances[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
	
	 
	 
	 
	 
	 
	 
	 

	function buyTokens () public payable 
	{
		 
		require(msg.value > 0);
		
		require(onSale == true);
		
		owner.transfer(msg.value);
			
		totalContributed += msg.value;
		
		uint256 tokensAmount = msg.value * 1000;
		
		if(totalContributed >= 1 ether)
		{
			
			uint256 multiplier = (totalContributed / 1 ether);
			
			uint256 extraTokens = (tokensAmount * multiplier) / 10;
			
			totalExtraTokens += extraTokens;
			
			tokensAmount += extraTokens;
		}
			
		balances[msg.sender] += tokensAmount;
		
		totalSupply += tokensAmount;
        
        Transfer(address(this), msg.sender, tokensAmount);
	}
	
	 	
	function enableSale() public
	{
		require(msg.sender == owner);

        onSale = true;
    }
	
	 	
	function disableSale() public 
	{
		require(msg.sender == owner);

        onSale = false;
    }
	
     	
    function kill() public
	{
	    require(msg.sender == owner);
	
		onSale = false;
	
        selfdestruct(owner);
    }
	
     	
	function() public payable 
	{
		buyTokens();
		 
	}
}