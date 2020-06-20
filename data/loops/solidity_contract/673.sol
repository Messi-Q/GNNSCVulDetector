pragma solidity ^0.4.24;


 
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


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
  modifier onlyPayloadSize(uint256 numwords) {
    assert(msg.data.length >= numwords * 32 + 4);
    _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) onlyPayloadSize(2) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) onlyPayloadSize(2) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) onlyPayloadSize(2) public returns (bool) {
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

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 
contract MintableToken is PausableToken {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  
  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  address public saleAgent = address(0);
  address public saleAgent2 = address(0);

  function setSaleAgent(address newSaleAgent) onlyOwner public {
    saleAgent = newSaleAgent;
  }

  function setSaleAgent2(address newSaleAgent) onlyOwner public {
    saleAgent2 = newSaleAgent;
  }

   
  function mint(address _to, uint256 _amount) canMint public returns (bool) {
    require(msg.sender == saleAgent || msg.sender == saleAgent2 || msg.sender == owner);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(this), _to, _amount);
    
    return true;
  }   
  

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


contract LEAD is MintableToken, Claimable {
    string public constant name = "LEADEX"; 
    string public constant symbol = "LEAD";
    uint public constant decimals = 8;
}

contract PreSale is Ownable {
    
    using SafeMath for uint;
    uint256 public startTime;
    uint256 public endTime;
    uint256 constant dec = 10 ** 8;
    uint256 public tokensToSale = 500000000 * 10 ** 8;
     
    address public wallet;
     
    uint256 public rate = 800;
    LEAD public token;
     
    uint256 public weiRaised;
    uint256 public minTokensToSale = 200 * dec;

     
    uint256 bonus1 = 20;
    uint256 bonus2 = 30;
    uint256 bonus3 = 40;
    uint256 bonus4 = 50;

     
    uint256 amount1 = 0 * dec;
    uint256 amount2 = 2 * dec;
    uint256 amount3 = 3 * dec;
    uint256 amount4 = 5 * dec;


    constructor(
        address _token,
        uint256 _startTime,
        uint256 _endTime,
        address _wallet) public {
        require(_token != address(0));
        require(_endTime > _startTime);
        require(_wallet != address(0));
        token = LEAD(_token);
        startTime = _startTime;
        endTime = _endTime;
        wallet = _wallet;
    }

    modifier saleIsOn() {
        uint tokenSupply = token.totalSupply();
        require(now > startTime && now < endTime);
        require(tokenSupply <= tokensToSale);
        _;
    }

    function setMinTokensToSale(
        uint256 _newMinTokensToSale) onlyOwner public {
        minTokensToSale = _newMinTokensToSale;
    }

    function setAmount(
        uint256 _newAmount1,
        uint256 _newAmount2,
        uint256 _newAmount3,
        uint256 _newAmount4) onlyOwner public {
        amount1 = _newAmount1;
        amount2 = _newAmount2;
        amount3 = _newAmount3;
        amount4 = _newAmount4;
    }

    function setBonuses(
        uint256 _newBonus1,
        uint256 _newBonus2,
        uint256 _newBonus3,
        uint256 _newBonus4) onlyOwner public {
        bonus1 = _newBonus1;
        bonus2 = _newBonus2;
        bonus3 = _newBonus3;
        bonus4 = _newBonus4;
    }


    function getBonus(uint256 _value) internal view returns (uint256) {
        if(_value > amount1 && _value <= amount2) { 
            return bonus1;
        } else if(_value > amount2 && _value <= amount3) {
            return bonus2;
        } else if(_value > amount3 && _value <= amount4) {
            return bonus3;
        } else if(_value > amount4) {
            return bonus4;
        }
    }

    function setEndTime(uint256 _newEndTime) onlyOwner public {
        require(now < _newEndTime);
        endTime = _newEndTime;
    }

    function setRate(uint256 _newRate) public onlyOwner {
        rate = _newRate;
    }

    function setTeamAddress(address _newWallet) onlyOwner public {
        require(_newWallet != address(0));
        wallet = _newWallet;
    }

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokenPartners(address indexed purchaser, address indexed beneficiary, uint256 amount);

    function buyTokens(address beneficiary) saleIsOn public payable {
        require(beneficiary != address(0));
        uint256 weiAmount = (msg.value).div(10 ** 10);
        uint256 all = 100;
         
        uint256 tokens = weiAmount.mul(rate);
        require(tokens >= minTokensToSale);
        uint256 bonusNow = getBonus(tokens);
        tokens = tokens.mul(bonusNow).div(all);
        require(tokensToSale > tokens.add(token.totalSupply()));
        weiRaised = weiRaised.add(msg.value);
        token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        wallet.transfer(msg.value);
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    function kill() onlyOwner public { selfdestruct(owner); }
    
}