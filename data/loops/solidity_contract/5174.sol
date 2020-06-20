pragma solidity ^0.4.23;
 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;
  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
    totalSupply_ = totalSupply_.add(_amount);
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


contract Bevium is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "Bevium";
  string public constant symbol = "BVI";
  uint32 public constant decimals = 18;
  address public addressFounders;
  uint256 public summFounders;
  function Bevium() public {
    addressFounders = 0x6e69307fe1fc55B2fffF680C5080774D117f1154;  
    summFounders = 26400000 * (10 ** uint256(decimals));  
    mint(addressFounders, summFounders);      
  }      
      
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  Bevium public token;
   
  uint256 public startPreICO;
  uint256 public endPreICO;  
  uint256 public startICO;
  uint256 public endICO;
   
  uint256 public sumHardCapPreICO;
  uint256 public sumHardCapICO;
  uint256 public sumPreICO;
  uint256 public sumICO;
   
  uint256 public minInvestmentPreICO;
  uint256 public minInvestmentICO;
  uint256 public maxInvestmentICO;
   
  uint256 public ratePreICO; 
  uint256 public rateICO;
   
  address public wallet;
  
 
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  
  function Crowdsale() public {
    token = createTokenContract();
     
    startPreICO = 1535587200;   
    endPreICO = 1543536000;   
    startICO = 1543536000;   
    endICO = 1577664000;   
     
    sumHardCapPreICO = 22000000 * 1 ether;
    sumHardCapICO = 6600000 * 1 ether;
     
    minInvestmentPreICO = 10 * 1 ether;
    minInvestmentICO = 100000000000000000;  
    maxInvestmentICO = 5 * 1 ether;
     
    ratePreICO = 1500;
    rateICO = 1000;    
     
    wallet = 0x86a639e5587117Fc95517D13168F767226DA6107;
  }

  function setRatePreICO(uint _ratePreICO) public onlyOwner  {
    ratePreICO = _ratePreICO;
  } 
  
  function setRateICO(uint _rateICO) public onlyOwner  {
    rateICO = _rateICO;
  }  
  
  function setStartPreICO(uint _startPreICO) public onlyOwner  {
     
    startPreICO = _startPreICO;
  }   

  function setEndPreICO(uint _endPreICO) public onlyOwner  {
     
     
    endPreICO = _endPreICO;
  }

  function setStartICO(uint _startICO) public onlyOwner  {
     
     
    startICO = _startICO;
  }

  function setEndICO(uint _endICO) public onlyOwner  {
     
    endICO = _endICO;
  }
  
   
  function () external payable {
    procureTokens(msg.sender);
  }
  
  function createTokenContract() internal returns (Bevium) {
    return new Bevium();
  }

  function checkHardCap(uint256 _value) view public {
     
    if (now >= startPreICO && now < endPreICO){
      require(_value.add(sumPreICO) <= sumHardCapPreICO);
    }  
     
    if (now >= startICO && now < endICO){
      require(_value.add(sumICO) <= sumHardCapICO);
    }       
  } 
  
  function adjustHardCap(uint256 _value) public {
     
    if (now >= startPreICO && now < endPreICO){
      sumPreICO = sumPreICO.add(_value);
    }  
     
    if (now >= startICO && now < endICO){
      sumICO = sumICO.add(_value);
    }       
  }   
  
  function checkMinMaxInvestment(uint256 _value) view public {
     
    if (now >= startPreICO && now < endPreICO){
      require(_value >= minInvestmentPreICO);
    }  
     
    if (now >= startICO && now < endICO){
      require(_value >= minInvestmentICO);
      require(_value <= maxInvestmentICO);
    }       
  }   
  
  function getRate() public view returns (uint256) {
    uint256 rate;
     
    if (now >= startPreICO && now < endPreICO){
      rate = ratePreICO;
    }  
     
    if (now >= startICO && now < endICO){
      rate = rateICO;
    }      
    return rate;
  }  
  
  function procureTokens(address _beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    address _this = this;
    uint256 rate;
    require(now >= startPreICO);
    require(now <= endICO);
    require(_beneficiary != address(0));
    checkMinMaxInvestment(weiAmount);
    rate = getRate();
    tokens = weiAmount.mul(rate);
    checkHardCap(tokens);
    adjustHardCap(tokens);
    wallet.transfer(_this.balance);
    token.mint(_beneficiary, tokens);
    emit TokenProcurement(msg.sender, _beneficiary, weiAmount, tokens);
  }
}