pragma solidity ^0.4.19;

contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value)   returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value)   returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract MintableToken is StandardToken, Ownable {
  bool public mintingFinished = false;
  
   
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state  );
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  modifier onlyMintAgent() {
     
    if(!mintAgents[msg.sender]) {
        revert();
    }
    _;
  }
  
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
   
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

   
  function mint(address _to, uint256 _amount) onlyMintAgent canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyMintAgent returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract ReleasableToken is ERC20, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;
  
   
  mapping(address => uint) public lock_addresses;
  
  event AddLockAddress(address addr, uint lock_time);  

   
  modifier canTransfer(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            revert();
        }
    }
	else {
		 
		if(now < lock_addresses[_sender]) {
			revert();
		}
	}
    _;
  }
  
  function ReleasableToken() {
	releaseAgent = msg.sender;
  }
  
   
  function addLockAddressInternal(address addr, uint lock_time) inReleaseState(false) internal {
	if(addr == 0x0) revert();
	lock_addresses[addr]= lock_time;
	AddLockAddress(addr, lock_time);
  }
  
  
   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }
  
   
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        revert();
    }
    _;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        revert();
    }
    _;
  }  

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}

contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    if (halted) revert();
    _;
  }

  modifier onlyInEmergency {
    if (!halted) revert();
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}

contract CrowdsaleLimit {
  using SafeMath for uint256;

   
  uint public startsAt;
   
  uint public endsAt;
   
  uint public TOKEN_MAX;
   
  uint public PRESALE_TOKEN_IN_WEI = 9 finney;
   
  uint public presale_eth_fund= 0;
  
   
  uint public CROWDSALE_TOKEN_IN_WEI = 10 finney;  
  
   
  uint public PRESALE_ETH_IN_WEI_FUND_MAX = 0 ether; 
   
  uint public CROWDSALE_ETH_IN_WEI_FUND_MIN = 100 ether;
   
  uint public CROWDSALE_ETH_IN_WEI_FUND_MAX = 1000 ether;
   
  uint public CROWDSALE_ETH_IN_WEI_ACCEPTED_MIN = 100 finney;    
   
  uint public CROWDSALE_GASPRICE_IN_WEI_MAX = 0;
 
   
  uint public crowdsale_eth_fund= 0;
   
  uint public crowdsale_eth_refund = 0;
   
   
  mapping(address => uint) public team_addresses_token_percentage;
  mapping(uint => address) public team_addresses_idx;
  uint public team_address_count= 0;
  uint public team_token_percentage_total= 0;
  uint public team_token_percentage_max= 0;
    
  event EndsAtChanged(uint newEndsAt);
  event AddTeamAddress(address addr, uint release_time, uint token_percentage);
  event Refund(address investor, uint weiAmount);
    
   
  modifier allowCrowdsaleAmountLimit(){	
	if (msg.value == 0) revert();
	if (msg.value < CROWDSALE_ETH_IN_WEI_ACCEPTED_MIN) revert();
	if((crowdsale_eth_fund.add(msg.value)) > CROWDSALE_ETH_IN_WEI_FUND_MAX) revert();
	if((CROWDSALE_GASPRICE_IN_WEI_MAX > 0) && (tx.gasprice > CROWDSALE_GASPRICE_IN_WEI_MAX)) revert();
	_;
  }  
   
  function CrowdsaleLimit(uint _start, uint _end, uint _token_max, uint _presale_token_in_wei, uint _crowdsale_token_in_wei, uint _presale_eth_inwei_fund_max, uint _crowdsale_eth_inwei_fund_min, uint _crowdsale_eth_inwei_fund_max, uint _crowdsale_eth_inwei_accepted_min, uint _crowdsale_gasprice_inwei_max, uint _team_token_percentage_max) {
	require(_start != 0);
	require(_end != 0);
	require(_start < _end);
	
	if( (_presale_token_in_wei == 0) ||
	    (_crowdsale_token_in_wei == 0) ||
		(_crowdsale_eth_inwei_fund_min == 0) ||
		(_crowdsale_eth_inwei_fund_max == 0) ||
		(_crowdsale_eth_inwei_accepted_min == 0) ||
		(_team_token_percentage_max >= 100))   
		revert();
		
	startsAt = _start;
    endsAt = _end;
	
	TOKEN_MAX = _token_max;
		
	PRESALE_TOKEN_IN_WEI = _presale_token_in_wei;
	
	CROWDSALE_TOKEN_IN_WEI = _crowdsale_token_in_wei;	
	PRESALE_ETH_IN_WEI_FUND_MAX = _presale_eth_inwei_fund_max;
	CROWDSALE_ETH_IN_WEI_FUND_MIN = _crowdsale_eth_inwei_fund_min;
	CROWDSALE_ETH_IN_WEI_FUND_MAX = _crowdsale_eth_inwei_fund_max;
	CROWDSALE_ETH_IN_WEI_ACCEPTED_MIN = _crowdsale_eth_inwei_accepted_min;
	CROWDSALE_GASPRICE_IN_WEI_MAX = _crowdsale_gasprice_inwei_max;
	
	team_token_percentage_max= _team_token_percentage_max;
  }
    
   
  function calculateTokenPresale(uint value, uint decimals)   public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return value.mul(multiplier).div(PRESALE_TOKEN_IN_WEI);
  }
  
   
  function calculateTokenCrowsale(uint value, uint decimals)   public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return value.mul(multiplier).div(CROWDSALE_TOKEN_IN_WEI);
  }
  
   
  function isMinimumGoalReached() public constant returns (bool) {
    return crowdsale_eth_fund >= CROWDSALE_ETH_IN_WEI_FUND_MIN;
  }
  
   
  function addTeamAddressInternal(address addr, uint release_time, uint token_percentage) internal {
	if((team_token_percentage_total.add(token_percentage)) > team_token_percentage_max) revert();
	if((team_token_percentage_total.add(token_percentage)) > 100) revert();
	if(team_addresses_token_percentage[addr] != 0) revert();
	
	team_addresses_token_percentage[addr]= token_percentage;
	team_addresses_idx[team_address_count]= addr;
	team_address_count++;
	
	team_token_percentage_total = team_token_percentage_total.add(token_percentage);

	AddTeamAddress(addr, release_time, token_percentage);
  }
   
   
  function hasEnded() public constant returns (bool) {
    return now > endsAt;
  }
}

contract Crowdsale is CrowdsaleLimit, Haltable {
  using SafeMath for uint256;

  CrowdsaleToken public token;
  
   
  address public multisigWallet;
    
   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;
  
   
  mapping (address => bool) public presaleWhitelist;
  
  bool public whitelist_enable= true;
  
   
  uint public tokensSold = 0;
  
   
  uint public investorCount = 0;
  
   
  uint public loadedRefund = 0;
  
   
  bool public finalized;
  
  enum State{Unknown, PreFunding, Funding, Success, Failure, Finalized, Refunding}
    
   
  event Invested(address investor, uint weiAmount, uint tokenAmount);
  
   
  event Whitelisted(address addr, bool status);
  
  event createTeamTokenEvent(address addr, uint tokens);
  
  event Finalized();
  
   
  modifier inState(State state) {
    if(getState() != state) revert();
    _;
  }

  function Crowdsale(address _token, address _multisigWallet, uint _start, uint _end, uint _token_max, uint _presale_token_in_wei, uint _crowdsale_token_in_wei, uint _presale_eth_inwei_fund_max, uint _crowdsale_eth_inwei_fund_min, uint _crowdsale_eth_inwei_fund_max, uint _crowdsale_eth_inwei_accepted_min, uint _crowdsale_gasprice_inwei_max, uint _team_token_percentage_max, bool _whitelist_enable) 
           CrowdsaleLimit(_start, _end, _token_max, _presale_token_in_wei, _crowdsale_token_in_wei, _presale_eth_inwei_fund_max, _crowdsale_eth_inwei_fund_min, _crowdsale_eth_inwei_fund_max, _crowdsale_eth_inwei_accepted_min, _crowdsale_gasprice_inwei_max, _team_token_percentage_max)
  {
    require(_token != 0x0);
    require(_multisigWallet != 0x0);
	
	token = CrowdsaleToken(_token);	
	multisigWallet = _multisigWallet;
	
	whitelist_enable= _whitelist_enable;
  }
  
   
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    else if (now < startsAt) return State.PreFunding;
    else if (now <= endsAt && !isMinimumGoalReached()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && crowdsale_eth_fund > 0 && loadedRefund >= crowdsale_eth_fund) return State.Refunding;
    else return State.Failure;
  }
   
   
  function setPresaleWhitelist(address addr, bool status) onlyOwner inState(State.PreFunding) {
	require(whitelist_enable==true);

    presaleWhitelist[addr] = status;
    Whitelisted(addr, status);
  }
  
   
  function addTeamAddress(address addr, uint release_time, uint token_percentage) onlyOwner inState(State.PreFunding) external {
	super.addTeamAddressInternal(addr, release_time, token_percentage);
	token.addLockAddress(addr, release_time);   
  }
  
   
  function createTeamTokenByPercentage() onlyOwner internal {
	uint total= token.totalSupply();
	 
	uint tokens= total.mul(team_token_percentage_total).div(100-team_token_percentage_total);
	
	for(uint i=0; i<team_address_count; i++) {
		address addr= team_addresses_idx[i];
		if(addr==0x0) continue;
		
		uint ntoken= tokens.mul(team_addresses_token_percentage[addr]).div(team_token_percentage_total);
		token.mint(addr, ntoken);		
		createTeamTokenEvent(addr, ntoken);
	}
  }
  
   
  function () stopInEmergency allowCrowdsaleAmountLimit payable {
	require(msg.sender != 0x0);
    buyTokensCrowdsale(msg.sender);
  }

   
  function buyTokensCrowdsale(address receiver) internal   {
	uint256 weiAmount = msg.value;
	uint256 tokenAmount= 0;
	
	if(getState() == State.PreFunding) {
		if(whitelist_enable==true) {
			if(!presaleWhitelist[receiver]) {
				revert();
			}
		}
		
		if((PRESALE_ETH_IN_WEI_FUND_MAX > 0) && ((presale_eth_fund.add(weiAmount)) > PRESALE_ETH_IN_WEI_FUND_MAX)) revert();		
		
		tokenAmount = calculateTokenPresale(weiAmount, token.decimals());
		presale_eth_fund = presale_eth_fund.add(weiAmount);
	}
	else if((getState() == State.Funding) || (getState() == State.Success)) {
		tokenAmount = calculateTokenCrowsale(weiAmount, token.decimals());
		
    } else {
       
      revert();
    }
	
	if(tokenAmount == 0) {
		revert();
	}	
	
	if(investedAmountOf[receiver] == 0) {
       investorCount++;
    }
    
	 
    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);
	
     
	crowdsale_eth_fund = crowdsale_eth_fund.add(weiAmount);
	tokensSold = tokensSold.add(tokenAmount);
	
	if((TOKEN_MAX > 0) && (tokensSold > TOKEN_MAX)) revert();

    token.mint(receiver, tokenAmount);

    if(!multisigWallet.send(weiAmount)) revert();
	
	 
    Invested(receiver, weiAmount, tokenAmount);
  }
 
   
  function loadRefund() public payable inState(State.Failure) {
    if(msg.value == 0) revert();
    loadedRefund = loadedRefund.add(msg.value);
  }
  
   
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0) revert();
    investedAmountOf[msg.sender] = 0;
    crowdsale_eth_refund = crowdsale_eth_refund.add(weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue)) revert();
  }
  
  function setEndsAt(uint time) onlyOwner {
    if(now > time) {
      revert();
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }
  
   
   
  function doFinalize() public inState(State.Success) onlyOwner stopInEmergency {
    
	if(finalized) {
      revert();
    }

	createTeamTokenByPercentage();
    token.finishMinting();	
        
    finalized = true;
	Finalized();
  }
  
}

contract CrowdsaleToken is ReleasableToken, MintableToken {

  string public name;

  string public symbol;

  uint public decimals;
    
   
  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable) {

    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply = _initialSupply;

    decimals = _decimals;

    balances[owner] = totalSupply;

    if(totalSupply > 0) {
      Mint(owner, totalSupply);
    }

     
    if(!_mintable) {
      mintingFinished = true;
      if(totalSupply == 0) {
        revert();  
      }
    }
  }

   
   
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }
  
   
  function addLockAddress(address addr, uint lock_time) onlyMintAgent inReleaseState(false) public {
	super.addLockAddressInternal(addr, lock_time);
  }

}