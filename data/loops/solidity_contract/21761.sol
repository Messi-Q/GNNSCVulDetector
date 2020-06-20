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
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
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
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract BurnableByOwner is BasicToken, Ownable {

  event Burn(address indexed burner, uint256 value);
  function burn(address _address, uint256 _value) public onlyOwner{
    require(_value <= balances[_address]);
     
     

    address burner = _address;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}

contract Wolf is Ownable, MintableToken, BurnableByOwner {
  using SafeMath for uint256;    
  string public constant name = "Wolf";
  string public constant symbol = "Wolf";
  uint32 public constant decimals = 18;

  address public addressTeam;
  address public addressCashwolf;
  address public addressFutureInvest;


  uint public summTeam = 15000000000 * 1 ether;
  uint public summCashwolf = 10000000000 * 1 ether;
  uint public summFutureInvest = 10000000000 * 1 ether;


  function Wolf() public {
	addressTeam = 0xb5AB520F01DeE8a42A2bfaEa8075398414774778;
	addressCashwolf = 0x3366e9946DD375d1966c8E09f889Bc18C5E1579A;
	addressFutureInvest = 0x7134121392eE0b6DC9382BBd8E392B4054CdCcEf;
	

     
    balances[addressTeam] = balances[addressTeam].add(summTeam);
    balances[addressCashwolf] = balances[addressCashwolf].add(summCashwolf);
	balances[addressFutureInvest] = balances[addressFutureInvest].add(summFutureInvest);

    totalSupply = summTeam.add(summCashwolf).add(summFutureInvest);
  }
  function getTotalSupply() public constant returns(uint256){
      return totalSupply;
  }
}



 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  uint256 public softcap;
   
  mapping(address => uint) public balancesSoftCap;
  struct BuyInfo {
    uint summEth;
    uint summToken;
    uint dateEndRefund;
  }
  mapping(address => mapping(uint => BuyInfo)) public payments;
  mapping(address => uint) public paymentCounter;
   
  Wolf public token;
   
   
  uint256 public startICO;
   
  uint256 public endICO;
  uint256 public period;
  uint256 public endICO14; 
   
  uint256 public hardCap;
  uint256 public totalICO;
   
  uint256 public rate;   
   
  address public wallet;
   
  uint256 public minNumbPerSubscr; 
  uint256 public maxNumbPerSubscr; 

 
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  function Crowdsale() public {
    token = createTokenContract();
     
    softcap = 100 * 1 ether;   
     
    minNumbPerSubscr = 10000000000000000;  
    maxNumbPerSubscr = 100 * 1 ether;
     
     
    startICO = 1521878400; 
    period = 30;
     
    endICO = startICO + period * 1 days;
    endICO14 = endICO + 14 * 1 days;
     
    hardCap = 65000000000 * 1 ether;
     
    rate = 1000000;
     
    wallet = 0x7472106A07EbAB5a202e195c0dC22776778b44E6;
  }

  function setStartICO(uint _startICO) public onlyOwner{
    startICO = _startICO;
    endICO = startICO + period * 1 days;
    endICO14 = endICO + 14 * 1 days;    
  }

  function setPeriod(uint _period) public onlyOwner{
    period = _period;
    endICO = startICO + period * 1 days;
    endICO14 = endICO + 14 * 1 days;    
  }
  
  function setRate(uint _rate) public  onlyOwner{
    rate = _rate;
  }
  
  function createTokenContract() internal returns (Wolf) {
    return new Wolf();
  }

   
  function () external payable {
    procureTokens(msg.sender);
  }

   
  function procureTokens(address beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    uint256 backAmount;
    require(beneficiary != address(0));
     
    require(weiAmount >= minNumbPerSubscr && weiAmount <= maxNumbPerSubscr);
    if (now >= startICO && now <= endICO && totalICO < hardCap){
      tokens = weiAmount.mul(rate);
      if (hardCap.sub(totalICO) < tokens){
        tokens = hardCap.sub(totalICO); 
        weiAmount = tokens.div(rate);
        backAmount = msg.value.sub(weiAmount);
      }
      totalICO = totalICO.add(tokens);
    }

    require(tokens > 0);
    token.mint(beneficiary, tokens);
    balancesSoftCap[beneficiary] = balancesSoftCap[beneficiary].add(weiAmount);

    uint256 dateEndRefund = now + 14 * 1 days;
    paymentCounter[beneficiary] = paymentCounter[beneficiary] + 1;
    payments[beneficiary][paymentCounter[beneficiary]] = BuyInfo(weiAmount, tokens, dateEndRefund); 
    
    if (backAmount > 0){
      msg.sender.transfer(backAmount);  
    }
    emit TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
  }

 
  function refund() public{
    require(address(this).balance < softcap && now > endICO);
    require(balancesSoftCap[msg.sender] > 0);
    uint value = balancesSoftCap[msg.sender];
    balancesSoftCap[msg.sender] = 0;
    msg.sender.transfer(value);
  }
  
  function revoke(uint _id) public{
    require(now <= payments[msg.sender][_id].dateEndRefund);
    require(payments[msg.sender][_id].summEth > 0);
    require(payments[msg.sender][_id].summToken > 0);
    uint value = payments[msg.sender][_id].summEth;
    uint valueToken = payments[msg.sender][_id].summToken;
    balancesSoftCap[msg.sender] = balancesSoftCap[msg.sender].sub(value);
    payments[msg.sender][_id].summEth = 0;
    payments[msg.sender][_id].summToken = 0;
    msg.sender.transfer(value);
    token.burn(msg.sender, valueToken);
   }  
  
  function transferToMultisig() public onlyOwner {
    require(address(this).balance >= softcap && now > endICO14);  
      wallet.transfer(address(this).balance);
  }  
}