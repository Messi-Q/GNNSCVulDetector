pragma solidity 0.4.24;
 
library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances; 

 
}

 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
 function Ownable() {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract MintableToken is ERC20, Ownable {
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
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }
   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}




 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}


 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}



 
contract EscrowAccountCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;
  EscrowVault public vault;
   
   function EscrowAccountCrowdsale() public {
    vault = new EscrowVault(wallet);
  }
   
  function returnInvestoramount(address _beneficiary, uint256 _percentage) internal onlyOwner {
    vault.refund(_beneficiary,_percentage);
  }

  function afterWhtelisted(address _beneficiary) internal onlyOwner{
      vault.closeAfterWhitelisted(_beneficiary);
  }
   
  function _forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

}

 
contract EscrowVault is Ownable {
  using SafeMath for uint256;
  mapping (address => uint256) public deposited;
  address public wallet;
  event Closed();
  event Refunded(address indexed beneficiary, uint256 weiAmount);
   
  function EscrowVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
   
  }
   
  function deposit(address investor) onlyOwner  payable {
    deposited[investor] = deposited[investor].add(msg.value);
  }
   function closeAfterWhitelisted(address _beneficiary) onlyOwner public {
   
    uint256 depositedValue = deposited[_beneficiary];
    deposited[_beneficiary] = 0;
    wallet.transfer(depositedValue);
  }
   

   
  function refund(address investor, uint256 _percentage)onlyOwner  {
    uint256 depositedValue = deposited[investor];
    depositedValue=depositedValue.sub(_percentage);
   
    investor.transfer(depositedValue);
    wallet.transfer(_percentage);
    emit Refunded(investor, depositedValue);
     deposited[investor] = 0;
  }
}

 
contract PostDeliveryCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

   
   
  
  function withdrawTokens() public {
   require(hasClosed());
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
  }
  
  
   function failedWhitelist(address _beneficiary) internal  {
    require(_beneficiary != address(0));
    uint256 amount = balances[_beneficiary];
    balances[_beneficiary] = 0;
  }
  function getInvestorDepositAmount(address _investor) public constant returns(uint256 paid){
     
     return balances[_investor];
 }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

}


contract CryptoAssetCrowdsale is TimedCrowdsale, MintedCrowdsale,EscrowAccountCrowdsale,PostDeliveryCrowdsale {

 enum Stage {PROCESS1_FAILED, PROCESS1_SUCCESS,PROCESS2_FAILED, PROCESS2_SUCCESS,PROCESS3_FAILED, PROCESS3_SUCCESS} 	
 	 
	enum Phase {PHASE1, PHASE2,PHASE3}
	 
	Phase public phase;
 
  struct whitelisted{
       Stage  stage;
 }
  uint256 public adminCharge_p1=0.010 ether;
  uint256 public adminCharge_p2=0.13 ether;
  uint256 public adminCharge_p3=0.14 ether;
  uint256 public cap=750 ether; 
  uint256 public goal=4500 ether; 
  uint256 public minContribAmount = 0.1 ether;  
  mapping(address => whitelisted) public whitelist;
   
  mapping (address => uint256) public investedAmountOf;
     
  uint256 public investorCount;
     
  uint256 public constant DECIMALFACTOR = 10**uint256(18);
  event updateRate(uint256 tokenRate, uint256 time);
  
    
  
 function CryptoAssetCrowdsale(uint256 _starttime, uint256 _endTime, uint256 _rate, address _wallet,ERC20 _token)
  TimedCrowdsale(_starttime,_endTime)Crowdsale(_rate, _wallet,_token)
  {
      phase = Phase.PHASE1;
  }
    
   
  function () external payable {
    buyTokens(msg.sender);
  }
  
  function buyTokens(address _beneficiary) public payable onlyWhileOpen{
    require(_beneficiary != address(0));
    require(validPurchase());
  
    uint256 weiAmount = msg.value;
     
    uint256 tokens = weiAmount.mul(rate);
    uint256 volumebasedBonus=0;
    if(phase == Phase.PHASE1){
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase1(tokens)).div(100);

    }else if(phase == Phase.PHASE2){
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase2(tokens)).div(100);

    }else{
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase3(tokens)).div(100);

    }

    tokens=tokens.add(volumebasedBonus);
    _preValidatePurchase( _beneficiary,  weiAmount);
    weiRaised = weiRaised.add(weiAmount);
    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    _forwardFunds();
    if(investedAmountOf[msg.sender] == 0) {
            
           investorCount++;
        }
         
        investedAmountOf[msg.sender] = investedAmountOf[msg.sender].add(weiAmount);
  }
    function tokensaleToOtherCoinUser(address beneficiary, uint256 weiAmount) public onlyOwner onlyWhileOpen {
    require(beneficiary != address(0) && weiAmount > 0);
    uint256 tokens = weiAmount.mul(rate);
    uint256 volumebasedBonus=0;
    if(phase == Phase.PHASE1){
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase1(tokens)).div(100);

    }else if(phase == Phase.PHASE2){
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase2(tokens)).div(100);

    }else{
    volumebasedBonus = tokens.mul(getTokenVolumebasedBonusRateForPhase3(tokens)).div(100);

    }

    tokens=tokens.add(volumebasedBonus);
    weiRaised = weiRaised.add(weiAmount);
    _processPurchase(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }
    
    function validPurchase() internal constant returns (bool) {
    bool minContribution = minContribAmount <= msg.value;
    return  minContribution;
  }
  
  
  function getTokenVolumebasedBonusRateForPhase1(uint256 value) internal constant returns (uint256) {
        uint256 bonusRate = 0;
        uint256 valume = value.div(DECIMALFACTOR);

        if (valume <= 50000 && valume >= 149999) {
            bonusRate = 30;
        } else if (valume <= 150000 && valume >= 299999) {
            bonusRate = 35;
        } else if (valume <= 300000 && valume >= 500000) {
            bonusRate = 40;
        } else{
            bonusRate = 25;
        }

        return bonusRate;
    }
  
   function getTokenVolumebasedBonusRateForPhase2(uint256 value) internal constant returns (uint256) {
        uint256 bonusRate = 0;
        uint valume = value.div(DECIMALFACTOR);

        if (valume <= 50000 && valume >= 149999) {
            bonusRate = 25;
        } else if (valume <= 150000 && valume >= 299999) {
            bonusRate = 30;
        } else if (valume <= 300000 && valume >= 500000) {
            bonusRate = 35;
        } else{
            bonusRate = 20;
        }

        return bonusRate;
    }
    
     function getTokenVolumebasedBonusRateForPhase3(uint256 value) internal constant returns (uint256) {
        uint256 bonusRate = 0;
        uint valume = value.div(DECIMALFACTOR);

        if (valume <= 50000 && valume >= 149999) {
            bonusRate = 20;
        } else if (valume <= 150000 && valume >= 299999) {
            bonusRate = 25;
        } else if (valume <= 300000 && valume >= 500000) {
            bonusRate = 30;
        } else{
            bonusRate = 15;
        }

        return bonusRate;
    }
  
   
  	function startPhase2(uint256 _startTime) public onlyOwner {
      	require(_startTime>0);
      	phase = Phase.PHASE2;
      	openingTime=_startTime;
      
   }
   
      
  	function startPhase3(uint256 _startTime) public onlyOwner {
      	require(0> _startTime);
      	phase = Phase.PHASE3;
        openingTime=_startTime;

   }

  
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary].stage==Stage.PROCESS3_SUCCESS);
    _;
  }

   
  function addToWhitelist(address _beneficiary,uint256 _stage) external onlyOwner {
      require(_beneficiary != address(0));
      require(_stage>0);  
 if(_stage==1){
     whitelist[_beneficiary].stage=Stage.PROCESS1_FAILED;
     returnInvestoramount(_beneficiary,adminCharge_p1);
     failedWhitelist(_beneficiary);
     investedAmountOf[_beneficiary]=0;
 }else if(_stage==2){
     whitelist[_beneficiary].stage=Stage.PROCESS1_SUCCESS;
 }else if(_stage==3){
     whitelist[_beneficiary].stage=Stage.PROCESS2_FAILED;
     returnInvestoramount(_beneficiary,adminCharge_p2);
     failedWhitelist(_beneficiary);
          investedAmountOf[_beneficiary]=0;
 }else if(_stage==4){
     whitelist[_beneficiary].stage=Stage.PROCESS2_SUCCESS;
 }else if(_stage==5){
     whitelist[_beneficiary].stage=Stage.PROCESS3_FAILED;
     returnInvestoramount(_beneficiary,adminCharge_p3);
     failedWhitelist(_beneficiary);
          investedAmountOf[_beneficiary]=0;
     }else if(_stage==6){
     whitelist[_beneficiary].stage=Stage.PROCESS3_SUCCESS;
     afterWhtelisted( _beneficiary);
 }
 
 }
 
   
  function withdrawTokens() public isWhitelisted(msg.sender)  {
    require(hasClosed());
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
   
  }
  
  
  function changeEndtime(uint256 _endTime) public onlyOwner {
    require(_endTime > 0); 
    closingTime = _endTime;
    }

  
  function changeRate(uint256 _rate) public onlyOwner {
    require(_rate > 0); 
    rate = _rate;
    emit updateRate(_rate,block.timestamp);
    }
   
  function changeAdminCharges(uint256 _p1,uint256 _p2,uint256 _p3) public onlyOwner {
    require(_p1 > 0);
    require(_p2 > 0); 
    require(_p3 > 0); 
    adminCharge_p1=_p1;
    adminCharge_p2=_p2;
    adminCharge_p3=_p3;
    
    }
    
  
  function changeMinInvestment(uint256 _minInvestment) public onlyOwner {
     require(_minInvestment > 0);
     minContribAmount=_minInvestment;
  }
   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }
   
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }
  
  	 
	function tokenDistribution(address _to, uint256 _value)public onlyOwner {
        require (
           _to != 0x0 && _value > 0);
        _processPurchase(_to, _value);
        whitelist[_to].stage=Stage.PROCESS3_SUCCESS;
    }
}