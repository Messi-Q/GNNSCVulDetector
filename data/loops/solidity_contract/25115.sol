pragma solidity ^0.4.18;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Ownable {
    
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
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

contract GUT is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "Geekz Utility Token";
  string public constant symbol = "GUT";
  uint32 public constant decimals = 18;

  address public addressTeam;
  address public addressReserveFund;

  uint public summTeam = 4000000 * 1 ether;
  uint public summReserveFund = 1000000 * 1 ether;

  function GUT() public {
    addressTeam = 0x142c0dba7449ceae2Dc0A5ce048D65b690630274;   
    addressReserveFund = 0xc709565D92a6B9a913f4d53de730712e78fe5B8C;  

     
    balances[addressTeam] = balances[addressTeam].add(summTeam);
    balances[addressReserveFund] = balances[addressReserveFund].add(summReserveFund);

    totalSupply = summTeam.add(summReserveFund);
  }
  function getTotalSupply() public constant returns(uint256){
      return totalSupply;
  }
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  uint256 public totalTokens;
   
  uint softcap;
   
  mapping(address => uint) public balances;
   
  GUT public token;
   
  
   
     
  uint256 public startEarlyStage1;
  uint256 public startEarlyStage2;
  uint256 public startEarlyStage3;
  uint256 public startEarlyStage4;
     
  uint256 public endEarlyStage1;
  uint256 public endEarlyStage2;
  uint256 public endEarlyStage3;
  uint256 public endEarlyStage4;   
  
   
     
  uint256 public startFinalStage1;
  uint256 public startFinalStage2;
     
  uint256 public endFinalStage1;    
  uint256 public endFinalStage2;  
  
   
  uint256 public maxEarlyStage;
  uint256 public maxFinalStage;

  uint256 public totalEarlyStage;
  uint256 public totalFinalStage;
  
   
  uint256 public rateEarlyStage1;
  uint256 public rateEarlyStage2;
  uint256 public rateEarlyStage3;
  uint256 public rateEarlyStage4;
  uint256 public rateFinalStage1;
  uint256 public rateFinalStage2;   
  
   
   
  uint public mintStart;  

   
  address public wallet;

   
  uint256 public minQuanValues; 

 
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  function Crowdsale() public {
    token = createTokenContract();
     
    totalTokens = 25000000 * 1 ether;
     
    softcap = 400 * 1 ether;   
     
    minQuanValues = 100000000000000000;  
     
     
       
    startEarlyStage1 = 1519804800; 
    startEarlyStage2 = startEarlyStage1 + 2 * 1 days;
    startEarlyStage3 = startEarlyStage2 + 2 * 1 days;
    startEarlyStage4 = startEarlyStage3 + 2 * 1 days;
       
    endEarlyStage1 = startEarlyStage1 + 2 * 1 days;
    endEarlyStage2 = startEarlyStage2 + 2 * 1 days;
    endEarlyStage3 = startEarlyStage3 + 2 * 1 days;
    endEarlyStage4 = startEarlyStage4 + 2 * 1 days;   
     
       
    startFinalStage1 = 1520582400; 
    startFinalStage2 = startFinalStage1 + 6 * 1 days;
       
    endFinalStage1 = startFinalStage1 + 6 * 1 days;    
    endFinalStage2 = startFinalStage2 + 16 * 1 days;         
     
    maxEarlyStage = 4000000 * 1 ether;
    maxFinalStage = 16000000 * 1 ether;
     
    rateEarlyStage1 = 10000;
    rateEarlyStage2 = 7500;
    rateEarlyStage3 = 5000;
    rateEarlyStage4 = 4000;
    rateFinalStage1 = 3000;
    rateFinalStage2 = 2000; 
     
     
    mintStart = endFinalStage2;  
     
    wallet = 0x80B48F46CD1857da32dB10fa54E85a2F18B96412;
  }

  
  function setRateEarlyStage1(uint _rateEarlyStage1) public {
    rateEarlyStage1 = _rateEarlyStage1;
  }
  function setRateEarlyStage2(uint _rateEarlyStage2) public {
    rateEarlyStage2 = _rateEarlyStage2;
  }  
  function setRateEarlyStage3(uint _rateEarlyStage3) public {
    rateEarlyStage3 = _rateEarlyStage3;
  }  
  function setRateEarlyStage4(uint _rateEarlyStage4) public {
    rateEarlyStage4 = _rateEarlyStage4;
  }  
  
  function setRateFinalStage1(uint _rateFinalStage1) public {
    rateFinalStage1 = _rateFinalStage1;
  }  
  function setRateFinalStage2(uint _rateFinalStage2) public {
    rateFinalStage2 = _rateFinalStage2;
  }   
  
  function createTokenContract() internal returns (GUT) {
    return new GUT();
  }

   
  function () external payable {
    procureTokens(msg.sender);
  }

   
  function procureTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    require(beneficiary != address(0));
     
    require(weiAmount >= minQuanValues);
     
    if (now >= startEarlyStage1 && now < endEarlyStage1 && totalEarlyStage < maxEarlyStage){
      tokens = weiAmount.mul(rateEarlyStage1);
      if (maxEarlyStage.sub(totalEarlyStage) < tokens){
        tokens = maxEarlyStage.sub(totalEarlyStage); 
        weiAmount = tokens.div(rateEarlyStage1);
        backAmount = msg.value.sub(weiAmount);
      }
      totalEarlyStage = totalEarlyStage.add(tokens);
    }
     
    if (now >= startEarlyStage2 && now < endEarlyStage2 && totalEarlyStage < maxEarlyStage){
      tokens = weiAmount.mul(rateEarlyStage2);
      if (maxEarlyStage.sub(totalEarlyStage) < tokens){
        tokens = maxEarlyStage.sub(totalEarlyStage); 
        weiAmount = tokens.div(rateEarlyStage2);
        backAmount = msg.value.sub(weiAmount);
      }
      totalEarlyStage = totalEarlyStage.add(tokens);
    }    
     
    if (now >= startEarlyStage3 && now < endEarlyStage3 && totalEarlyStage < maxEarlyStage){
      tokens = weiAmount.mul(rateEarlyStage3);
      if (maxEarlyStage.sub(totalEarlyStage) < tokens){
        tokens = maxEarlyStage.sub(totalEarlyStage); 
        weiAmount = tokens.div(rateEarlyStage3);
        backAmount = msg.value.sub(weiAmount);
      }
      totalEarlyStage = totalEarlyStage.add(tokens);
    }    
     
    if (now >= startEarlyStage4 && now < endEarlyStage4 && totalEarlyStage < maxEarlyStage){
      tokens = weiAmount.mul(rateEarlyStage4);
      if (maxEarlyStage.sub(totalEarlyStage) < tokens){
        tokens = maxEarlyStage.sub(totalEarlyStage); 
        weiAmount = tokens.div(rateEarlyStage4);
        backAmount = msg.value.sub(weiAmount);
      }
      totalEarlyStage = totalEarlyStage.add(tokens);
    }   
     
    if (now >= startFinalStage1 && now < endFinalStage1 && totalFinalStage < maxFinalStage){
      tokens = weiAmount.mul(rateFinalStage1);
      if (maxFinalStage.sub(totalFinalStage) < tokens){
        tokens = maxFinalStage.sub(totalFinalStage); 
        weiAmount = tokens.div(rateFinalStage1);
        backAmount = msg.value.sub(weiAmount);
      }
      totalFinalStage = totalFinalStage.add(tokens);
    }       
     
    if (now >= startFinalStage2 && now < endFinalStage2 && totalFinalStage < maxFinalStage){
      tokens = weiAmount.mul(rateFinalStage2);
      if (maxFinalStage.sub(totalFinalStage) < tokens){
        tokens = maxFinalStage.sub(totalFinalStage); 
        weiAmount = tokens.div(rateFinalStage2);
        backAmount = msg.value.sub(weiAmount);
      }
      totalFinalStage = totalFinalStage.add(tokens);
    }        
    
    require(tokens > 0);
    token.mint(beneficiary, tokens);
    balances[msg.sender] = balances[msg.sender].add(msg.value);
     
    
    if (backAmount > 0){
      msg.sender.transfer(backAmount);    
    }
    TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
  }

   
  function mintTokens(address _to, uint256 _amount) onlyOwner public returns (bool) {
    require(_amount > 0);
    require(_to != address(0));
    require(now >= mintStart);
    require(_amount <= totalTokens.sub(token.getTotalSupply()));
    token.mint(_to, _amount);
    return true;
  }
  
  function refund() public{
    require(this.balance < softcap && now > endFinalStage2);
    require(balances[msg.sender] > 0);
    uint value = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.transfer(value);
  }
  
  function transferToMultisig() public onlyOwner {
    require(this.balance >= softcap && now > endFinalStage2);  
      wallet.transfer(this.balance);
  }  
}