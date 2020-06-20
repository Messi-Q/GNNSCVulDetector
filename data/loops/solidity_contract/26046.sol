pragma solidity ^0.4.16;

 
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

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract SimpleCoinToken is MintableToken {
    
  string public constant name = "AntiqMall";
   
  string public constant symbol = "AMT";
    
  uint32 public constant decimals = 18;
    
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;

   
  SimpleCoinToken public token;

   
  address public wallet;

   
  uint256 public weiRaised;
  
  uint256 public tokensCount;
  
  uint256 public bountyTokensCount;
  
  enum State {
    early_pre_ico,  
    pre_ico,
    ico_w1,
    ico_w2,
    ico_w3,
    ico_w4,
    ico,
    paused,
    finished
  }
  
  State public currentState;
  
  uint256 constant MIN_WEI_VALUE = 1 * 1e16;
  
  uint256 constant PRE_ICO_SALE_VALUE = 10;
  uint256 constant EARLY_PRE_ICO_SALE_VALUE_1 = 4;
  uint256 constant EARLY_PRE_ICO_SALE_VALUE_2 = 8;
  uint256 constant EARLY_PRE_ICO_SALE_VALUE_3 = 15;
  
  uint256 constant EARLY_PRE_ICO_SALE_BONUS_0 = 50;
  uint256 constant EARLY_PRE_ICO_SALE_BONUS_1 = 65;
  uint256 constant EARLY_PRE_ICO_SALE_BONUS_2 = 75;
  uint256 constant EARLY_PRE_ICO_SALE_BONUS_3 = 85;
  uint256 constant EARLY_PRE_ICO_SALE_BONUS_4 = 100;
  
  uint256 constant PRE_ICO_SALE_BONUS = 100;
  uint256 constant PRE_ICO_BONUS = 50;
  uint256 constant ICO_BONUS_W1 = 30;
  uint256 constant ICO_BONUS_W2 = 20;
  uint256 constant ICO_BONUS_W3 = 10;
  uint256 constant ICO_BONUS_W4 =  0;
  uint256 constant ICO_DEFAULT_BONUS = 0;
  uint256 constant PRICE = 1000;
  uint256 constant ICO_TOKENS_LIMIT = 7.5 * 1e6 * 1e18;
  uint256 constant PRE_ICO_TOKENS_LIMIT = 0.6 * 1e6 * 1e18;
  
  uint256 constant RESERVED_TOKENS_PERCENT = 20;


   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  modifier saleIsOn() {
    require(currentState <= State.ico);
    _;
  }

  function Crowdsale() {
    token = createTokenContract();
    currentState = State.paused;
    wallet = msg.sender;
    tokensCount = 0;
    bountyTokensCount = 0;
  }

   
   
  function createTokenContract() internal returns (SimpleCoinToken) {
    return new SimpleCoinToken();
  }

  function setIcoState(State _newState) public onlyOwner {
    currentState = _newState;
  }
  
  function mintBountyTokens(address _wallet) public onlyOwner payable {
    uint256 tokens = tokensCount.sub(bountyTokensCount);
    tokens = tokens.mul(25).div(100);
    tokens = tokens.sub(bountyTokensCount);
    
    require(tokens >= 1);
      
     
    tokensCount = tokensCount.add(tokens);
    bountyTokensCount = bountyTokensCount.add(tokens);

    token.mint(_wallet, tokens);
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public saleIsOn payable {
    require(beneficiary != address(0));
    require(msg.value != 0);
    require(msg.value >= MIN_WEI_VALUE);
    
    uint256 limit = getLimit();
    
    uint256 weiAmount = msg.value;
    
     
    uint256 tokens = weiAmount.mul(PRICE);
    uint256 bonusTokens = getBonusTokens(tokens, weiAmount);
    
    tokens = tokens.add(bonusTokens);
    
    require(limit >= tokensCount.add(tokens).sub(bountyTokensCount));

     
    weiRaised = weiRaised.add(weiAmount);
    tokensCount = tokensCount.add(tokens);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }
  
  function getBonusTokens(uint256 _tokens, uint256 _weiAmount) private returns(uint256 _bonusTokens) {
    uint256 bonusTokens = ICO_DEFAULT_BONUS;
    if(currentState == State.pre_ico) {
      bonusTokens = _tokens.div(100).mul(PRE_ICO_BONUS);
      
      if(_weiAmount >= PRE_ICO_SALE_VALUE.mul(1e18)) {
        bonusTokens = _tokens.div(100).mul(PRE_ICO_SALE_BONUS);
      }
    }
    if(currentState == State.ico_w1) {
      bonusTokens = _tokens.div(100).mul(ICO_BONUS_W1);
    }
    if(currentState == State.ico_w2) {
      bonusTokens = _tokens.div(100).mul(ICO_BONUS_W2);
    }
    if(currentState == State.ico_w3) {
      bonusTokens = _tokens.div(100).mul(ICO_BONUS_W3);
    }
    if(currentState == State.ico_w4) {
      bonusTokens = _tokens.div(100).mul(ICO_BONUS_W4);
    }
    
    if(currentState == State.early_pre_ico) {
        
        bonusTokens = _tokens.div(100).mul(EARLY_PRE_ICO_SALE_BONUS_0);
        
        if(_weiAmount >= 0.5*1e18 && _weiAmount < EARLY_PRE_ICO_SALE_VALUE_1.mul(1e18)) {
            bonusTokens = _tokens.div(100).mul(EARLY_PRE_ICO_SALE_BONUS_1);
        }
        if(_weiAmount >= EARLY_PRE_ICO_SALE_VALUE_1.mul(1e18) && _weiAmount < EARLY_PRE_ICO_SALE_VALUE_2.mul(1e18)) {
            bonusTokens = _tokens.div(100).mul(EARLY_PRE_ICO_SALE_BONUS_2);
        }
        if(_weiAmount >= EARLY_PRE_ICO_SALE_VALUE_2.mul(1e18) && _weiAmount < EARLY_PRE_ICO_SALE_VALUE_3.mul(1e18)) {
            bonusTokens = _tokens.div(100).mul(EARLY_PRE_ICO_SALE_BONUS_3);
        }
        if(_weiAmount >= EARLY_PRE_ICO_SALE_VALUE_3.mul(1e18)) {
            bonusTokens = _tokens.div(100).mul(EARLY_PRE_ICO_SALE_BONUS_4);
        }
    }
    
    return bonusTokens;
  }
  
  function getLimit() private returns(uint256 _limit) {
    if(currentState <= State.pre_ico) {
      return PRE_ICO_TOKENS_LIMIT;
    }
    
    return ICO_TOKENS_LIMIT.sub(ICO_TOKENS_LIMIT.mul(RESERVED_TOKENS_PERCENT).div(100));
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

}