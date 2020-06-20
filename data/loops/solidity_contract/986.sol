pragma solidity ^0.4.18;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Fomo5d {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;
	
	mapping(address=>bool) public frozenAccount;
	uint256 public rate = 20000 ; 
	uint256 public amount; 
	
	address public owner;
	bool public fundOnContract=true;	
	bool public contractStart=true;	 
	bool public exchangeStart=true;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
	 
	modifier  onlyOwner{
        if(msg.sender != owner){
            revert();
        }else{
            _;
        }
    }

    function transferOwner(address newOwner)  public onlyOwner{
        owner = newOwner;
    }
	 

	 
    function Fomo5d() public payable{
		decimals=18;
        totalSupply = 1000000000 * (10 ** uint256(decimals));   
        balanceOf[msg.sender] = totalSupply;                 
        name = "Fomo5d";                                    
        symbol = "F5d";                                
		owner = msg.sender;
		rate=20000;
		fundOnContract=true;
		contractStart=true;
		exchangeStart=true;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
		if(frozenAccount[_from]){
            revert();
        }
		if(frozenAccount[_to]){
            revert();
        }
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
		if(!contractStart){
			revert();
		}
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		if(!contractStart){
			revert();
		}
        require(_value <= allowance[_from][msg.sender]);      
		require(_value > 0);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		if(!contractStart){
			revert();
		}
		require(balanceOf[msg.sender] >= _value);
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
		if(!contractStart){
			revert();
		}
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
		if(!contractStart){
			revert();
		}
        require(balanceOf[msg.sender] >= _value);    
		require(_value > 0);
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
		Transfer(msg.sender, 0, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        require(balanceOf[_from] >= _value);                 
		require(_value> 0); 
        balanceOf[_from] -= _value;                          
        totalSupply -= _value;                               
		Transfer(_from, 0, _value);
        return true;
    }
	
	function () public payable{
		if(!contractStart){
			revert();
		}
        if(frozenAccount[msg.sender]){
            revert();
        }
		amount = uint256(msg.value * rate);
		
		if(balanceOf[msg.sender]+amount<balanceOf[msg.sender]){
			revert();
		}
		if(balanceOf[owner]<amount){
			revert();
		}
		 
			if(exchangeStart){
				balanceOf[owner] -=amount ;
				balanceOf[msg.sender] +=amount;
				Transfer(owner, msg.sender, amount);  
			}
			if(!fundOnContract){
				owner.transfer(msg.value);
			}
		 
    }

	function transferFund(address target,uint256 _value) public onlyOwner{
		if(frozenAccount[target]){
            revert();
        }
		if(_value<=0){
			revert();
		}
		if(_value>this.balance){
			revert();
		}
		if(target != 0){
			target.transfer(_value);
		}
    }
	
	
	function setFundOnContract(bool _fundOnContract)  public onlyOwner{
            fundOnContract = _fundOnContract;
    }
	
	function setContractStart(bool _contractStart)  public onlyOwner{
            contractStart = _contractStart;
    }
	
	function freezeAccount(address target,bool _bool)  public onlyOwner{
        if(target != 0){
            frozenAccount[target] = _bool;
        }
    }
	function setRate(uint thisRate) public onlyOwner{
	   if(thisRate>=0){
         rate = thisRate;
		}
    }
	
	function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, owner, mintedAmount);
        Transfer(owner, target, mintedAmount);
    }
	function ownerKill(address target) public onlyOwner {
		selfdestruct(target);
    }
	function withdraw(address target) public onlyOwner {
		target.transfer(this.balance);
    }
	function getBalance() public constant returns(uint) {
		return this.balance;
	}
	function setExchangeStart(bool _exchangeStart)  public onlyOwner{
            exchangeStart = _exchangeStart;
    }
}