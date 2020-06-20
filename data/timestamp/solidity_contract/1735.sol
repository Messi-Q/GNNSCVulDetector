pragma solidity ^0.4.16;
contract moduleTokenInterface{
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed a_owner, address indexed _spender, uint256 _value);
    event OwnerChang(address indexed _old,address indexed _new,uint256 _coin_change);
	event adminUsrChange(address usrAddr,address changeBy,bool isAdded);
	event onAdminTransfer(address to,uint256 value);
}

contract moduleToken is moduleTokenInterface {
    
    struct transferPlanInfo{
        uint256 transferValidValue;
        bool isInfoValid;
    }
    
    struct ethPlanInfo{
	    uint256 ethNum;
	    uint256 coinNum;
	    bool isValid;
	}
	
	 
	struct transferEthAgreement{
		 
	    mapping(address=>bool) signUsrList;		
		
		 
		uint32 signedUsrCount;
		
		 
	    uint256 transferEthInWei;
		
		 
		address to;
		
		 
		address infoOwner;
		
		 
	    uint32 magic;
	    
	     
	    bool isValid;
	}
	
	

    string public name;                    
    uint8 public decimals;                
    string public symbol;                
    address public owner;
    
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
	
	 
	bool public canRecvEthDirect=false;
    
    
     
     
    
     
	uint256 public coinPriceInWei;
	
	 
	mapping(address=>transferPlanInfo) public transferPlanList;
	
	 
	 
	mapping(address => ethPlanInfo) public ethPlanList;
	
	uint public blockTime=block.timestamp;
    
    bool public isTransPaused=true; 
    
      
    struct adminUsrInfo{
        bool isValid;
	    string userName;
		string descInfo;
    }
    mapping(address=>adminUsrInfo) public adminOwners;  
    bool public isAdminOwnersValid;
    uint32 public adminUsrCount; 
    mapping(uint256=>transferEthAgreement) public transferEthAgreementList;

    function moduleToken(
        uint256 _initialAmount,
        uint8 _decimalUnits) public 
    {
        owner=msg.sender; 
		if(_initialAmount<=0){
		    totalSupply = 100000000000;    
		    balances[owner]=100000000000;
		}else{
		    totalSupply = _initialAmount;    
		    balances[owner]=_initialAmount;
		}
		if(_decimalUnits<=0){
		    decimals=2;
		}else{
		    decimals = _decimalUnits;
		}
        name = "CareerOn Token"; 
        symbol = "COT";
    }
    
    function changeContractName(string _newName,string _newSymbol) public {
        require(msg.sender==owner || adminOwners[msg.sender].isValid);
        name=_newName;
        symbol=_newSymbol;
    }
    
    
    function transfer(
        address _to, 
        uint256 _value) public returns (bool success) 
    {
        if(isTransPaused){
            emit Transfer(msg.sender, _to, 0); 
            revert();
            return;
        }
         
         
		if(_to==address(this)){
			emit Transfer(msg.sender, _to, 0); 
            revert();
            return;
		}
		if(balances[msg.sender] < _value || 
			balances[_to] + _value <= balances[_to])
		{
			emit Transfer(msg.sender, _to, 0); 
            revert();
            return;
		}
        if(transferPlanList[msg.sender].isInfoValid && transferPlanList[msg.sender].transferValidValue<_value)
		{
			emit Transfer(msg.sender, _to, 0); 
            revert();
            return;
		}
        balances[msg.sender] -= _value; 
        balances[_to] += _value; 
        if(transferPlanList[msg.sender].isInfoValid){
            transferPlanList[msg.sender].transferValidValue -=_value;
        }
        emit Transfer(msg.sender, _to, _value); 
        return true;
    }


    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value) public returns (bool success) 
    {
        if(isTransPaused){
            emit Transfer(_from, _to, 0); 
            revert();
            return;
        }
		if(_to==address(this)){
			emit Transfer(_from, _to, 0); 
            revert();
            return;
		}
        if(balances[_from] < _value ||
			allowed[_from][msg.sender] < _value)
		{
			emit Transfer(_from, _to, 0); 
            revert();
            return;
		}
        if(transferPlanList[_from].isInfoValid && transferPlanList[_from].transferValidValue<_value)
		{
			emit Transfer(_from, _to, 0); 
            revert();
            return;
		}
        balances[_to] += _value; 
        balances[_from] -= _value;  
        allowed[_from][msg.sender] -= _value; 
        if(transferPlanList[_from].isInfoValid){
            transferPlanList[_from].transferValidValue -=_value;
        }
        emit Transfer(_from, _to, _value); 
        return true;
    }
    
    function balanceOf(address accountAddr) public constant returns (uint256 balance) {
        return balances[accountAddr];
    }


    function approve(address _spender, uint256 _value) public returns (bool success) 
    { 
        require(msg.sender!=_spender && _value>0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(
        address _owner, 
        address _spender) public constant returns (uint256 remaining) 
    {
        return allowed[_owner][_spender]; 
    }
	
	 
	
	 
	function changeOwner(address newOwner) public{
        require(msg.sender==owner && msg.sender!=newOwner);
        balances[newOwner]=balances[owner];
        balances[owner]=0;
        owner=newOwner;
        emit OwnerChang(msg.sender,newOwner,balances[owner]); 
    }
    
    function setPauseStatus(bool isPaused)public{
        if(msg.sender!=owner && !adminOwners[msg.sender].isValid){
            revert();
            return;
        }
        isTransPaused=isPaused;
    }
    
     
	function setTransferPlan(address addr,
	                        uint256 allowedMaxValue,
	                        bool isValid) public
	{
	    if(msg.sender!=owner && !adminOwners[msg.sender].isValid){
	        revert();
	        return ;
	    }
	    transferPlanList[addr].isInfoValid=isValid;
	    if(transferPlanList[addr].isInfoValid){
	        transferPlanList[addr].transferValidValue=allowedMaxValue;
	    }
	}
    
     
	function TransferEthToAddr(address _to,uint256 _value)public payable{
        require(msg.sender==owner && !isAdminOwnersValid);
        _to.transfer(_value);
    }
    
    function createTransferAgreement(uint256 agreeMentId,
                                      uint256 transferEthInWei,
                                      address to) public {
        require(adminOwners[msg.sender].isValid && 
        transferEthAgreementList[agreeMentId].magic!=123456789 && 
        transferEthAgreementList[agreeMentId].magic!=987654321);
        transferEthAgreementList[agreeMentId].magic=123456789;
        transferEthAgreementList[agreeMentId].infoOwner=msg.sender;
        transferEthAgreementList[agreeMentId].transferEthInWei=transferEthInWei;
        transferEthAgreementList[agreeMentId].to=to;
        transferEthAgreementList[agreeMentId].isValid=true;
        transferEthAgreementList[agreeMentId].signUsrList[msg.sender]=true;
        transferEthAgreementList[agreeMentId].signedUsrCount=1;
        
    }
	
	function disableTransferAgreement(uint256 agreeMentId) public {
		require(transferEthAgreementList[agreeMentId].infoOwner==msg.sender &&
			    transferEthAgreementList[agreeMentId].magic==123456789);
		transferEthAgreementList[agreeMentId].isValid=false;
		transferEthAgreementList[agreeMentId].magic=987654321;
	}
	
	function sign(uint256 agreeMentId,address to,uint256 transferEthInWei) public payable{
		require(transferEthAgreementList[agreeMentId].magic==123456789 &&
		transferEthAgreementList[agreeMentId].isValid &&
		transferEthAgreementList[agreeMentId].transferEthInWei==transferEthInWei &&
		transferEthAgreementList[agreeMentId].to==to &&
		adminOwners[msg.sender].isValid &&
		!transferEthAgreementList[agreeMentId].signUsrList[msg.sender]&&
		adminUsrCount>=2
		);
		transferEthAgreementList[agreeMentId].signUsrList[msg.sender]=true;
		transferEthAgreementList[agreeMentId].signedUsrCount++;
		
		if(transferEthAgreementList[agreeMentId].signedUsrCount<=adminUsrCount/2)
		{
			return;
		}
		to.transfer(transferEthInWei);
		transferEthAgreementList[agreeMentId].isValid=false;
		transferEthAgreementList[agreeMentId].magic=987654321;
		emit onAdminTransfer(to,transferEthInWei);
		return;
	}
	
	struct needToAddAdminInfo{
		uint256 magic;
		mapping(address=>uint256) postedPeople;
		uint32 postedCount;
	}
	mapping(address=>needToAddAdminInfo) public needToAddAdminInfoList;
	function addAdminOwners(address usrAddr,
					  string userName,
					  string descInfo)public 
	{
		needToAddAdminInfo memory info;
		 
		if(!adminOwners[msg.sender].isValid && owner!=msg.sender){
			revert();
			return;
		}
		 
		if(usrAddr==owner){
			revert();
			return;
		}
		 
		if(adminOwners[usrAddr].isValid){
			revert();
			return;
		}
		 
		if(usrAddr==msg.sender){
			revert();
			return;
		}
		 
		if(adminUsrCount<2){
			if(msg.sender!=owner){
				revert();
				return;
			}
			adminOwners[usrAddr].isValid=true;
			adminOwners[usrAddr].userName=userName;
			adminOwners[usrAddr].descInfo=descInfo;
			adminUsrCount++;
			if(adminUsrCount>=2) isAdminOwnersValid=true;
			emit adminUsrChange(usrAddr,msg.sender,true);
			return;
		}
		 
		if(msg.sender==owner){
			 
			if(needToAddAdminInfoList[usrAddr].magic==123456789){
				revert();
				return;
			}
			 
			info.magic=123456789;
			info.postedCount=0;
			needToAddAdminInfoList[usrAddr]=info;
			return;
			
		} 
		else if(adminOwners[msg.sender].isValid)
		{
			 
			if(needToAddAdminInfoList[usrAddr].magic!=123456789){
				revert();
				return;
			}
			 
			if(needToAddAdminInfoList[usrAddr].postedPeople[msg.sender]==123456789){
				revert();
				return;
			}
			needToAddAdminInfoList[usrAddr].postedCount++;
			needToAddAdminInfoList[usrAddr].postedPeople[msg.sender]=123456789;
			if(adminUsrCount>=2 && 
			   needToAddAdminInfoList[usrAddr].postedCount>adminUsrCount/2){
				adminOwners[usrAddr].userName=userName;
				adminOwners[usrAddr].descInfo=descInfo;
				adminOwners[usrAddr].isValid=true;
				needToAddAdminInfoList[usrAddr]=info;
				adminUsrCount++;
				emit adminUsrChange(usrAddr,msg.sender,true);
				return;
			}
			
		}else{
			return revert(); 
		}		
	}
	struct needDelFromAdminInfo{
		uint256 magic;
		mapping(address=>uint256) postedPeople;
		uint32 postedCount;
	}
	mapping(address=>needDelFromAdminInfo) public needDelFromAdminInfoList;
	function delAdminUsrs(address usrAddr) public {
		needDelFromAdminInfo memory info;
		 
		if(!adminOwners[usrAddr].isValid){
			revert();
			return;
		}
		 
		if(adminUsrCount<4){
			revert();
			return;
		}
		 
		if(adminUsrCount%2!=0){
			revert();
			return;
		}
		 
		if(usrAddr==msg.sender){
			revert();
			return;
		}
		if(msg.sender==owner){
			 
			if(needDelFromAdminInfoList[usrAddr].magic==123456789){
				revert();
				return;
			}
			 
			info.magic=123456789;
			info.postedCount=0;
			needDelFromAdminInfoList[usrAddr]=info;
			return;
		}
		 
		
		 
		if(needDelFromAdminInfoList[usrAddr].magic!=123456789){
			revert();
			return;
		}
		 
		if(needDelFromAdminInfoList[usrAddr].postedPeople[msg.sender]==123456789){
			revert();
			return;
		}
		needDelFromAdminInfoList[usrAddr].postedCount++;
		needDelFromAdminInfoList[usrAddr].postedPeople[msg.sender]=123456789;
		 
		if(needDelFromAdminInfoList[usrAddr].postedCount<=adminUsrCount/2){
			return;
		}
		 
		adminOwners[usrAddr].isValid=false;
		if(adminUsrCount>=1) adminUsrCount--;
		if(adminUsrCount<=1) isAdminOwnersValid=false;
		needDelFromAdminInfoList[usrAddr]=info;
		emit adminUsrChange(usrAddr,msg.sender,false);
	}
	
	 
	function setEthPlan(address addr,uint256 _ethNum,uint256 _coinNum,bool _isValid) public {
	    require(msg.sender==owner &&
	        _ethNum>=0 &&
	        _coinNum>=0 &&
	        (_ethNum + _coinNum)>0 &&
	        _coinNum<=balances[owner]);
	    ethPlanList[addr].isValid=_isValid;
	    if(ethPlanList[addr].isValid){
	        ethPlanList[addr].ethNum=_ethNum;
	        ethPlanList[addr].coinNum=_coinNum;
	    }
	}
	
	 
	function setCoinPrice(uint256 newPriceInWei) public returns(uint256 oldPriceInWei){
	    require(msg.sender==owner);
	    uint256 _old=coinPriceInWei;
	    coinPriceInWei=newPriceInWei;
	    return _old;
	}
	
	function balanceInWei() public constant returns(uint256 nowBalanceInWei){
	    return address(this).balance;
	}
	
	function changeRecvEthStatus(bool _canRecvEthDirect) public{
		if(msg.sender!=owner){
			revert();
			return;
		}
		canRecvEthDirect=_canRecvEthDirect;
	}
	
	 
     
     
	 
    function () public payable {
		if(canRecvEthDirect){
			return;
		}
        if(ethPlanList[msg.sender].isValid==true &&
            msg.value>=ethPlanList[msg.sender].ethNum &&
            ethPlanList[msg.sender].coinNum>=0 &&
            ethPlanList[msg.sender].coinNum<=balances[owner]){
                ethPlanList[msg.sender].isValid=false;
                balances[owner] -= ethPlanList[msg.sender].coinNum; 
                balances[msg.sender] += ethPlanList[msg.sender].coinNum; 
		        emit Transfer(this, msg.sender, ethPlanList[msg.sender].coinNum); 
        }else if(!ethPlanList[msg.sender].isValid &&
            coinPriceInWei>0 &&
            msg.value/coinPriceInWei<=balances[owner] &&
            msg.value/coinPriceInWei+balances[msg.sender]>balances[msg.sender]){
            uint256 buyCount=msg.value/coinPriceInWei;
            balances[owner] -=buyCount;
            balances[msg.sender] +=buyCount;
            emit Transfer(this, msg.sender, buyCount); 
               
        }else{
            revert();
        }
    }
}