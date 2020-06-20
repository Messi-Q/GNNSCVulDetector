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


contract BVA is Ownable, MintableToken {
  using SafeMath for uint256;    
  string public constant name = "BlockchainValley";
  string public constant symbol = "BVA";
  uint32 public constant decimals = 18;
  address public addressFounders;
  uint256 public summFounders;
  function BVA() public {
    addressFounders = 0x6e69307fe1fc55B2fffF680C5080774D117f1154;  
    summFounders = 35340000 * (10 ** uint256(decimals));  
    mint(addressFounders, summFounders);      
  }      
      
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;
  BVA public token;
   
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
   
  uint256 public maxRefererTokens;
  uint256 public allRefererTokens;
 
  event TokenProcurement(address indexed contributor, address indexed beneficiary, uint256 value, uint256 amount);
  
  function Crowdsale() public {
    token = createTokenContract();
     
    sumHardCapPreICO = 14700000 * 1 ether;
    sumHardCapICO = 4960000 * 1 ether;
     
    maxRefererTokens = 2500000 * 1 ether;
     
    minInvestmentPreICO = 3 * 1 ether;
    minInvestmentICO = 100000000000000000;  
    maxInvestmentICO = 5 * 1 ether;
     
    ratePreICO = 1500;
    rateICO = 1000;    
     
    wallet = 0x00a134aE23247c091Dd4A4dC1786358f26714ea3;
  }

  function setRatePreICO(uint256 _ratePreICO) public onlyOwner  {
    ratePreICO = _ratePreICO;
  } 
  
  function setRateICO(uint256 _rateICO) public onlyOwner  {
    rateICO = _rateICO;
  }  
  
  function setStartPreICO(uint256 _startPreICO) public onlyOwner  {
     
    startPreICO = _startPreICO;
  }   

  function setEndPreICO(uint256 _endPreICO) public onlyOwner  {
     
     
    endPreICO = _endPreICO;
  }

  function setStartICO(uint256 _startICO) public onlyOwner  {
     
     
    startICO = _startICO;
  }

  function setEndICO(uint256 _endICO) public onlyOwner  {
     
    endICO = _endICO;
  }
  
   
  function () external payable {
    procureTokens(msg.sender);
  }
  
  function createTokenContract() internal returns (BVA) {
    return new BVA();
  }
  
  function adjustHardCap(uint256 _value) internal {
     
    if (now >= startPreICO && now < endPreICO){
      sumPreICO = sumPreICO.add(_value);
    }  
     
    if (now >= startICO && now < endICO){
      sumICO = sumICO.add(_value);
    }       
  }  

  function checkHardCap(uint256 _value) view public {
     
    if (now >= startPreICO && now < endPreICO){
      require(_value.add(sumPreICO) <= sumHardCapPreICO);
    }  
     
    if (now >= startICO && now < endICO){
      require(_value.add(sumICO) <= sumHardCapICO);
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
  
  function bytesToAddress(bytes source) internal pure returns(address) {
    uint result;
    uint mul = 1;
    for(uint i = 20; i > 0; i--) {
      result += uint8(source[i-1])*mul;
      mul = mul*256;
    }
    return address(result);
  }
  
  function procureTokens(address _beneficiary) public payable {
    uint256 tokens;
    uint256 weiAmount = msg.value;
    address _this = this;
    uint256 rate;
    address referer;
    uint256 refererTokens;
    require(now >= startPreICO);
    require(now <= endICO);
    require(_beneficiary != address(0));
    checkMinMaxInvestment(weiAmount);
    rate = getRate();
    tokens = weiAmount.mul(rate);
     
	if(msg.data.length == 20) {
      referer = bytesToAddress(bytes(msg.data));
      require(referer != msg.sender);
	   
      refererTokens = tokens.mul(5).div(100);
    }
    checkHardCap(tokens.add(refererTokens));
    adjustHardCap(tokens.add(refererTokens));
    wallet.transfer(_this.balance);
	if (refererTokens != 0 && allRefererTokens.add(refererTokens) <= maxRefererTokens){
	  allRefererTokens = allRefererTokens.add(refererTokens);
      token.mint(referer, refererTokens);	  
	}    
    token.mint(_beneficiary, tokens);
    emit TokenProcurement(msg.sender, _beneficiary, weiAmount, tokens);
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
}