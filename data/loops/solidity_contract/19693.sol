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
 
contract BasicToken is ERC20Basic, Ownable {

  using SafeMath for uint256;
  mapping(address => uint256) balances;
   
  mapping(address => uint8) permissionsList;

  function SetPermissionsList(address _address, uint8 _sign) public onlyOwner{
    permissionsList[_address] = _sign;
  }
  function GetPermissionsList(address _address) public constant onlyOwner returns(uint8){
    return permissionsList[_address];
  }
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(permissionsList[msg.sender] == 0);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
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
    require(permissionsList[_from] == 0);
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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


 
contract MintableToken is StandardToken {
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
    MintFinished();
    return true;
  }
}

contract BurnableByOwner is BasicToken {

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
  address public addressBounty;


  uint public summTeam = 15000000000 * 1 ether;
  uint public summCashwolf = 10000000000 * 1 ether;
  uint public summFutureInvest = 10000000000 * 1 ether;
  uint public summBounty = 1000000000 * 1 ether;


  function Wolf() public {
	addressTeam = 0xb5AB520F01DeE8a42A2bfaEa8075398414774778;
	addressCashwolf = 0x3366e9946DD375d1966c8E09f889Bc18C5E1579A;
	addressFutureInvest = 0x7134121392eE0b6DC9382BBd8E392B4054CdCcEf;
  addressBounty = 0x902A95ad8a292f5e355fCb8EcB761175D30b6fC6;

     
    balances[addressTeam] = balances[addressTeam].add(summTeam);
    balances[addressCashwolf] = balances[addressCashwolf].add(summCashwolf);
	  balances[addressFutureInvest] = balances[addressFutureInvest].add(summFutureInvest);
    balances[addressBounty] = balances[addressBounty].add(summBounty);

    totalSupply = summTeam.add(summCashwolf).add(summFutureInvest).add(summBounty);
  }
  function getTotalSupply() public constant returns(uint256){
      return totalSupply;
  }
}


 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
   
  uint256 public softcap;
   
   
  uint256 public activeBalance;
   
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
     
    softcap = 5000 * 1 ether;
     
    minNumbPerSubscr = 10000000000000000;  
    maxNumbPerSubscr = 300 * 1 ether;
     
     
    startICO = 1523455200; 
    period = 60;
     
    endICO = startICO + period * 1 days;
    endICO14 = endICO + 14 * 1 days;
     
    hardCap = 65000000000 * 1 ether;
     
    rate = 500000;
     
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
    token.SetPermissionsList(beneficiary, 1);
    if (backAmount > 0){
      msg.sender.transfer(backAmount);
    }
    emit TokenProcurement(msg.sender, beneficiary, weiAmount, tokens);
  }

  function SetPermissionsList(address _address, uint8 _sign) public onlyOwner{
      uint8 sign;
      sign = token.GetPermissionsList(_address);
      token.SetPermissionsList(_address, _sign);
      if (_sign == 0){
          if (sign != _sign){
            activeBalance =  activeBalance.add(balancesSoftCap[_address]);
          }

      }
      if (_sign == 1){
          if (sign != _sign){
            activeBalance =  activeBalance.sub(balancesSoftCap[_address]);
          }
      }
  }
  function GetPermissionsList(address _address) public constant onlyOwner returns(uint8){
    return token.GetPermissionsList(_address);
  }
  function refund() public{
    require(activeBalance < softcap && now > endICO);
    require(balancesSoftCap[msg.sender] > 0);
    uint value = balancesSoftCap[msg.sender];
    balancesSoftCap[msg.sender] = 0;
    msg.sender.transfer(value);
  }

  function refundUnconfirmed() public{
    require(now > endICO);
    require(balancesSoftCap[msg.sender] > 0);
    require(token.GetPermissionsList(msg.sender) == 1);
    uint value = balancesSoftCap[msg.sender];
    balancesSoftCap[msg.sender] = 0;
    msg.sender.transfer(value);
    token.burn(msg.sender, token.balanceOf(msg.sender));
    totalICO = totalICO.sub(token.balanceOf(msg.sender));
  }

  function revoke(uint _id) public{
    uint8 sign;
    require(now <= payments[msg.sender][_id].dateEndRefund);
    require(balancesSoftCap[msg.sender] > 0);
    require(payments[msg.sender][_id].summEth > 0);
    require(payments[msg.sender][_id].summToken > 0);
    uint value = payments[msg.sender][_id].summEth;
    uint valueToken = payments[msg.sender][_id].summToken;
    balancesSoftCap[msg.sender] = balancesSoftCap[msg.sender].sub(value);
    sign = token.GetPermissionsList(msg.sender);
    if (sign == 0){
      activeBalance =  activeBalance.sub(value);
    }
    payments[msg.sender][_id].summEth = 0;
    payments[msg.sender][_id].summToken = 0;
    msg.sender.transfer(value);
    token.burn(msg.sender, valueToken);
    totalICO = totalICO.sub(valueToken);
  }

  function transferToMultisig() public onlyOwner {
    require(activeBalance >= softcap && now > endICO14);
      wallet.transfer(activeBalance);
      activeBalance = 0;
  }
}