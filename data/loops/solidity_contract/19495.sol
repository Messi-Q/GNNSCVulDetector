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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
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

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
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

 
contract MintableToken is StandardToken, Ownable {
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

 
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

contract EMACToken is CappedToken, BurnableToken {

    string public constant name = "eMarketChain";
    string public constant symbol = "EMAC";
    uint8 public constant decimals = 18;

    function EMACToken(uint256 _cap) CappedToken(_cap) public {
    }
    
    function burn(uint256 _value) public {
        super.burn(_value);
    }
}


 
contract EMACCrowdsale is Ownable {
  using SafeMath for uint256;

   
  EMACToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;
  
   
  address public teamWallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;
  
   
  uint256 public constant INIT_TOKENS = 454 * (10 ** 6) * (10 ** 18);
  
   
  uint256 public TEAM_TOKENS = INIT_TOKENS.mul(20).div(100);
  
   
  uint256 public constant HARD_CAP = 32000 * (10**18);
  
   
  uint256 public constant PRE_SALE_CAP = 18000 * (10**18);
  
   
  uint256 public constant PRE_SALE_BONUS_PERCENTAGE = 120;
  uint256 public constant MAIN_SALE_BONUS_PERCENTAGE_PHASE1 = 115;
  uint256 public constant MAIN_SALE_BONUS_PERCENTAGE_PHASE2 = 110;
  uint256 public constant MAIN_SALE_BONUS_PERCENTAGE_PHASE3 = 105;
  uint256 public constant MAIN_SALE_BONUS_PERCENTAGE_PHASE4 = 100;
  
   
  event EMACTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function EMACCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _teamWallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_teamWallet != address(0));

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    token = new EMACToken(INIT_TOKENS);
    teamWallet = _teamWallet;
    
    token.mint(_teamWallet, TEAM_TOKENS);
    depositTokens();
  }
  
  function depositTokens() public payable {
    EMACTokenPurchase(msg.sender, teamWallet, msg.value, TEAM_TOKENS);
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    EMACTokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }
  
  function finalize() onlyOwner public {
    require(hasEnded());

    uint256 unsoldTokens = INIT_TOKENS - token.totalSupply();

     
    require(unsoldTokens > 0);
    token.burn(unsoldTokens);
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    uint256 tokenExchangeRate = MAIN_SALE_BONUS_PERCENTAGE_PHASE4;
    uint256 convertToWei = (10**18);

    if (now <= (startTime + 14 days) && weiRaised <= PRE_SALE_CAP) {
      tokenExchangeRate = PRE_SALE_BONUS_PERCENTAGE;
    }
    else if (now <= endTime && weiRaised <= HARD_CAP) {
      if (weiRaised < 10000 * convertToWei) {
        tokenExchangeRate = MAIN_SALE_BONUS_PERCENTAGE_PHASE1;
      }
      else if (weiRaised >= 10000 * convertToWei && weiRaised < 20000 * convertToWei) {
        tokenExchangeRate = MAIN_SALE_BONUS_PERCENTAGE_PHASE2;
      }
      else if (weiRaised >= 20000 * convertToWei && weiRaised < 30000 * convertToWei) {
        tokenExchangeRate = MAIN_SALE_BONUS_PERCENTAGE_PHASE3;
      }
    }

    uint256 bonusRate = rate.mul(tokenExchangeRate);
    return weiAmount.mul(bonusRate).div(100);
  }

   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    bool notReachedHardCap = weiRaised <= HARD_CAP;
    return withinPeriod && nonZeroPurchase && notReachedHardCap;
  }
}