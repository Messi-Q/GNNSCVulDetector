pragma solidity ^0.4.11;

 

 

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}





 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
 
contract BasicFrozenToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  
     
  mapping(address => uint256) unfrozeTimestamp;

     
   
  function isUnfrozen(address sender) public constant returns (bool) {
     
    if(now > 1530921600)
      return true;
    else
     return unfrozeTimestamp[sender] < now;
  }


   
  function frozenTimeOf(address _owner) public constant returns (uint256 balance) {
    return unfrozeTimestamp[_owner];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
     
    require(isUnfrozen(msg.sender));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }



   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}



 


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




 

 
contract StandardToken is ERC20, BasicFrozenToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    
     
    require(isUnfrozen(_from));

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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


 

contract QuasacoinToken is StandardToken, Ownable {
    
  string public name = "Quasacoin";
  string public symbol = "QUA";
  uint public decimals = 18;
  
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(_to != address(0));
    require(_amount > 0);

    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    uint frozenTime = 0; 
     
    if(now < 1530921600) {
       
      if(now < 1515974400)
        frozenTime = 1522368000;

       
      else if(now < 1518652800)
        frozenTime = 1527638400;

       
      else if(now < 1522022400)
        frozenTime = 1530316800;

       
      else if(now < 1523750400)
        frozenTime = 1530403200;

       
      else if(now < 1526342400)
        frozenTime = 1530921600;

       
      else if(now < 1529020800)
        frozenTime = 1530316800;
      else 
       
        frozenTime = 1530921600;
      unfrozeTimestamp[_to] = frozenTime;
    }

    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 
contract QuasacoinTokenCrowdsale {
  using SafeMath for uint256;

   
  QuasacoinToken public token;

   
  uint256 public startPreICOTime;
   
  uint256 public startICOTime;
  uint256 public endTime;

   
  address public wallet;

   
  address public tokenOwner;

   
  uint256 public ratePreICO;
  uint256 public rateICO;

   
  uint256 public weiRaisedPreICO;
  uint256 public weiRaisedICO;

  uint256 public capPreICO;
  uint256 public capICO;

  mapping(address => bool) internal allowedMinters;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function QuasacoinTokenCrowdsale() {
    token = QuasacoinToken(0x4dAeb4a06F70f4b1A5C329115731fE4b89C0B227);
    tokenOwner = 0x373ae730d8c4250b3d022a65ef998b8b7ab1aa53;
    wallet = 0x373ae730d8c4250b3d022a65ef998b8b7ab1aa53;

     
    startPreICOTime = 1515974400;
     
    startICOTime = 1518652800;
     
    endTime = 1522022400;
    
     
    ratePreICO = 6000;

     
    rateICO = 3000;

    capPreICO = 5000 ether;
    capICO = 50000 ether;
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens;
    if(now < startICOTime) {  
      weiRaisedPreICO = weiRaisedPreICO.add(weiAmount);
      tokens = weiAmount * ratePreICO;
    } 
    else {
      weiRaisedICO = weiRaisedICO.add(weiAmount);
      tokens = weiAmount * rateICO;
    }

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
   
    if(now >= startPreICOTime && now < startICOTime) {
      return weiRaisedPreICO.add(msg.value) <= capPreICO;
    } else if(now >= startICOTime && now < endTime) {
      return weiRaisedICO.add(msg.value) <= capICO;
    } else
    return false;
  }

   
  function hasEnded() public constant returns (bool) {
    if(now < startPreICOTime)
      return false;
    else if(now >= startPreICOTime && now < startICOTime) {
      return weiRaisedPreICO >= capPreICO;
    } else if(now >= startICOTime && now < endTime) {
      return weiRaisedICO >= capICO;
    } else
      return true;
  }

  function returnTokenOwnership() public {
    require(msg.sender == tokenOwner);
    token.transferOwnership(tokenOwner);
  }

  function addMinter(address addr) {
    require(msg.sender == tokenOwner);
    allowedMinters[addr] = true;
  }
  function removeMinter(address addr) {
    require(msg.sender == tokenOwner);
    allowedMinters[addr] = false;
  }

  function mintProxy(address _to, uint256 _amount) public {
    require(allowedMinters[msg.sender]);
    require(now >= startPreICOTime && now < endTime);
    
    uint256 weiAmount;

    if(now < startICOTime) {
      weiAmount = _amount.div(ratePreICO);
      require(weiRaisedPreICO.add(weiAmount) <= capPreICO);
      weiRaisedPreICO = weiRaisedPreICO.add(weiAmount);
    } 
    else {
      weiAmount = _amount.div(rateICO);
      require(weiRaisedICO.add(weiAmount) <= capICO);
      weiRaisedICO = weiRaisedICO.add(weiAmount);
    }

    token.mint(_to, _amount);
    TokenPurchase(msg.sender, _to, weiAmount, _amount);
  }
}