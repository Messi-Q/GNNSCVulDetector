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

 

 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

contract MyRefundVault is RefundVault, Pausable {

  function MyRefundVault(address _wallet) RefundVault(_wallet) 
  {
  }

  function getDeposit(address contributor) public view returns(uint256 depositedValue)
  {
    return deposited[contributor];    
  }

  function refundWhenNotClosed(address contributor) public onlyOwner whenNotPaused returns(uint256 weiRefunded) {
    require(state != State.Closed);
    uint256 depositedValue = deposited[contributor];
    deposited[contributor] = 0;
    uint256 refundFees = depositedValue.div(100);
    uint256 refundValue = depositedValue.sub(refundFees);
    if(refundFees > 0)
      wallet.transfer(refundFees);
    if(refundValue > 0)
      contributor.transfer(refundValue);
    Refunded(contributor, depositedValue);
    return depositedValue;
  }

  function isRefundPaused() public view returns(bool) {
    return paused;
  }

  function myRefund(address investor) public onlyOwner whenNotPaused returns(uint256 refunedValue) {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
    return depositedValue;
  }

}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
     
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

 

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}

 

contract MyRefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  MyRefundVault public vault;

  function MyRefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new MyRefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefundOnUnsuccessfulEvent() public {
    require(isFinalized);
    require(!goalReached());
    uint256 refundedValue = vault.myRefund(msg.sender);
    weiRaised = weiRaised.sub(refundedValue);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

  function getDeposit(address contributor) public view returns(uint256 depositedValue) {
    return vault.getDeposit(contributor);
  }

  function pauseRefund() public onlyOwner {
  	vault.pause();
  }

  function unpauseRefund() public onlyOwner {
    vault.unpause();
  }

  function isRefundPaused() public view returns(bool) {
    return vault.isRefundPaused();
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

 

contract SilcToken is MintableToken, BurnableToken {
	string public name = "SILC";
	string public symbol = "SILC";
	uint8 public decimals = 18;

	function burn(address burner, uint256 _value) public onlyOwner {
	    require(_value <= balances[burner]);
	     
	     

	    balances[burner] = balances[burner].sub(_value);
	    totalSupply = totalSupply.sub(_value);
	    Burn(burner, _value);
	}

}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

 

contract SilcCrowdsale is CappedCrowdsale, MyRefundableCrowdsale {

   
   
  enum CrowdsaleStage { phase1, phase2, phase3 }
  CrowdsaleStage public stage = CrowdsaleStage.phase1;  
   

   
   
  uint256 public maxTokens = 20000000000000000000000000000;           
  uint256 public tokensForEcosystem = 3500000000000000000000000000;   
  uint256 public tokensForTeam = 2500000000000000000000000000;        
  uint256 public tokensForAdvisory = 1000000000000000000000000000;    

  uint256 public totalTokensForSale = 3000000000000000000000000000;   
   

   
  uint256 public rateForPhase1 = 110000;
  uint256 public rateForPhase2 = 105000;
  uint256 public rateForPhase3 = 100000;

   
   
  int256 public totalWeiRaisedDuringPhase1;
  int256 public totalWeiRaisedDuringPhase2;
  int256 public totalWeiRaisedDuringPhase3;
   

  uint256 public totalTokenSupply;

   
  event EthTransferred(string text);
  event EthRefunded(string text);


   
   
  function SilcCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, uint256 _goal, uint256 _cap) 
    CappedCrowdsale(_cap) 
    FinalizableCrowdsale() 
    MyRefundableCrowdsale(_goal) 
    Crowdsale(_startTime, _endTime, _rate, _wallet) public {
      require(_goal <= _cap);
  }
   

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new SilcToken();  
  }
   

   
   

   
  function setCrowdsaleStage(uint value) public onlyOwner {

      CrowdsaleStage _stage;

      if (uint(CrowdsaleStage.phase1) == value) {
        _stage = CrowdsaleStage.phase1;
      } else if (uint(CrowdsaleStage.phase2) == value) {
        _stage = CrowdsaleStage.phase2;
      } else if (uint(CrowdsaleStage.phase3) == value) {
        _stage = CrowdsaleStage.phase3;
      }


      stage = _stage;

      if (stage == CrowdsaleStage.phase1) {
        setCurrentRate(rateForPhase1);
      } else if (stage == CrowdsaleStage.phase2) {
        setCurrentRate(rateForPhase2);
      } else if (stage == CrowdsaleStage.phase3) {
        setCurrentRate(rateForPhase3);
      }
  }

   
  function setCurrentRate(uint256 _rate) private {
      rate = _rate;
  }

  function calculateWeiForStage(int256 value) {
      if (stage == CrowdsaleStage.phase1) {
        totalWeiRaisedDuringPhase1 = totalWeiRaisedDuringPhase1 + value;
      } else if (stage == CrowdsaleStage.phase2) {
        totalWeiRaisedDuringPhase2 = totalWeiRaisedDuringPhase2 + value;
      } else if (stage == CrowdsaleStage.phase3) {
        totalWeiRaisedDuringPhase3 = totalWeiRaisedDuringPhase3 + value;
      }
  }

   

   
   
  function () external payable {
       
       
       
       
       
       
      require(msg.value >= 0.1 ether);  
      buyTokens(msg.sender);
      totalTokenSupply = token.totalSupply();
      calculateWeiForStage(int256(msg.value));
  }

  mapping (address => uint256) tokenIssued;

  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    tokenIssued[beneficiary] = tokenIssued[beneficiary].add(tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function getTokenIssued(address contributor) public view returns (uint256 token) {
    return tokenIssued[contributor];
  }

  function forwardFunds() internal {
      if (stage == CrowdsaleStage.phase1) {
           
           
          EthTransferred("forwarding funds to refundable vault");
          super.forwardFunds();
      } else if (stage == CrowdsaleStage.phase2) {
          EthTransferred("forwarding funds to refundable vault");
          super.forwardFunds();
      } else if (stage == CrowdsaleStage.phase3) {
          EthTransferred("forwarding funds to refundable vault");
          super.forwardFunds();
      }
  }
   

   
   

  function finish(address _teamFund, address _ecosystemFund, address _advisoryFund) public onlyOwner {

    require(!isFinalized);
    uint256 alreadyMinted = token.totalSupply();
    require(alreadyMinted < maxTokens);

    uint256 unsoldTokens = totalTokensForSale - alreadyMinted;
    if (unsoldTokens > 0) {
      tokensForEcosystem = tokensForEcosystem + unsoldTokens;
    }

    token.mint(_teamFund,tokensForTeam);
    token.mint(_ecosystemFund,tokensForEcosystem);
    token.mint(_advisoryFund,tokensForAdvisory);
    finalize();
  }
   

   
  function mintSilcToken(address _to, uint256 _amount) public onlyOwner {
    token.mint(_to, _amount);
  }

  function transferTokenOwnership(address newOwner) public onlyOwner {
    token.transferOwnership(newOwner);
  }

  function transferVaultOwnership(address newOwner) public onlyOwner {
    vault.transferOwnership(newOwner);
  }
   

  event LogEvent(bytes32 message, uint256 value);
  event RefundRequestCompleted(address contributor, uint256 weiRefunded, uint256 burnedToken);
  function refundRequest() public {
    address contributor = msg.sender;
    SilcToken silcToken = SilcToken(address(token));
    uint256 tokenValance = token.balanceOf(contributor);
    require(tokenValance != 0);
    require(tokenValance >= tokenIssued[contributor]);
     
    silcToken.burn(contributor, tokenIssued[contributor]);   
    tokenIssued[contributor] = 0;
     
    uint256 weiRefunded = vault.refundWhenNotClosed(contributor);
    weiRaised = weiRaised.sub(weiRefunded);

    calculateWeiForStage(int256(weiRefunded) * -1);

    RefundRequestCompleted(contributor, weiRefunded, tokenValance);
  }

   
  function hasEnded() public view returns (bool) {
    return true;
  }
}