pragma solidity ^0.4.11;

 
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) tokenBalances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBalances[msg.sender]>=_value);
    tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return tokenBalances[_owner];
  }

}

contract DRIVRNetworkToken is BasicToken,Ownable {

   using SafeMath for uint256;
   
   string public constant name = "DRIVR Network";
   string public constant symbol = "DVR";
   uint256 public constant decimals = 18;

   uint256 public constant INITIAL_SUPPLY = 750000000;
   
    function DRIVRNetworkToken(address wallet) public {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY * 10 ** 18;
        tokenBalances[wallet] = totalSupply;    
    }

    function mint(address wallet, address buyer, uint256 tokenAmount) public onlyOwner {
      require(tokenBalances[wallet] >= tokenAmount);                
      tokenBalances[buyer] = tokenBalances[buyer].add(tokenAmount);                   
      tokenBalances[wallet] = tokenBalances[wallet].sub(tokenAmount);                         
      Transfer(wallet, buyer, tokenAmount); 
      totalSupply = totalSupply.sub(tokenAmount);
    }
    function showMyTokenBalance(address addr) public view returns (uint tokenBalance) {
        tokenBalance = tokenBalances[addr];
    }
}
contract DrivrCrowdsale {
  using SafeMath for uint256;
 
   
  DRIVRNetworkToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
   
  address public wallet;

   
  uint256 public ratePerWei = 20000;

   
  uint256 public weiRaised;
  uint256 public duration = 75 days;  
  uint256 TOKENS_SOLD;
  uint256 maxTokensToSaleInPrivateInvestmentPhase = 172500000 * 10 ** 18;
  uint256 maxTokensToSaleInPreICOPhase = 392500000 * 10 ** 18;
  uint256 maxTokensToSaleInICOPhase = 655000000 * 10 ** 18;
  uint256 maxTokensToSale = 655000000 * 10 ** 18;
  
  
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event Debug(string message);

  function DrivrCrowdsale(uint256 _startTime, address _wallet) public 
  {
    require(_startTime >= now);
    startTime = _startTime;   
    endTime = startTime + duration;
    
    require(endTime >= startTime);
    require(_wallet != 0x0);

    wallet = _wallet;
    token = createTokenContract(wallet);
  }
  
   
  function createTokenContract(address wall) internal returns (DRIVRNetworkToken) {
    return new DRIVRNetworkToken(wall);
  }

   
  function () public payable {
    buyTokens(msg.sender);
  }

    function determineBonus(uint tokens) internal view returns (uint256 bonus) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        if (timeElapsedInDays <15)
        {
            if (TOKENS_SOLD < maxTokensToSaleInPrivateInvestmentPhase)
            {
                 
                bonus = tokens.mul(15);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD + tokens + bonus <= maxTokensToSaleInPrivateInvestmentPhase);
            }
            else if (TOKENS_SOLD >= maxTokensToSaleInPrivateInvestmentPhase && TOKENS_SOLD < maxTokensToSaleInPreICOPhase)
            {
                bonus = tokens.mul(10);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD + tokens + bonus <= maxTokensToSaleInPreICOPhase);
            }
            else if (TOKENS_SOLD >= maxTokensToSaleInPreICOPhase && TOKENS_SOLD < maxTokensToSaleInICOPhase)
            {
                bonus = tokens.mul(5);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD + tokens + bonus <= maxTokensToSaleInICOPhase);
            }
            else 
            {
                bonus = 0;
            }
        }
        else if (timeElapsedInDays >= 15 && timeElapsedInDays<43)
        {
            if (TOKENS_SOLD < maxTokensToSaleInPreICOPhase)
            {
                bonus = tokens.mul(10);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD + tokens + bonus <= maxTokensToSaleInPreICOPhase);
            }
            else if (TOKENS_SOLD >= maxTokensToSaleInPreICOPhase && TOKENS_SOLD < maxTokensToSaleInICOPhase)
            {
                bonus = tokens.mul(5);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD + tokens + bonus <= maxTokensToSaleInICOPhase);
            }
            else 
            {
                bonus = 0;
            }
        }
        else if (timeElapsedInDays >= 43 && timeElapsedInDays<=75)
        {
            if (TOKENS_SOLD < maxTokensToSaleInICOPhase)
            {
                bonus = tokens.mul(5);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD + tokens + bonus <= maxTokensToSaleInICOPhase);
            }
            else 
            {
                bonus = 0;
            }
        }
        else 
        {
            bonus = 0;
        }
    }
   
   
  
  function buyTokens(address beneficiary) public payable {
    
    require(beneficiary != 0x0 && validPurchase() && TOKENS_SOLD<maxTokensToSale);
    require(msg.value >= 1 * 10 ** 17);
    uint256 weiAmount = msg.value;
    
     
    
    uint256 tokens = weiAmount.mul(ratePerWei);
    uint256 bonus = determineBonus(tokens);
    tokens = tokens.add(bonus);
    require(TOKENS_SOLD+tokens<=maxTokensToSale);
    
     
    weiRaised = weiRaised.add(weiAmount);
    token.mint(wallet, beneficiary, tokens); 
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    TOKENS_SOLD = TOKENS_SOLD.add(tokens);
    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
  
    function setPriceRate(uint256 newPrice) public returns (bool) {
        require (msg.sender == wallet);
        ratePerWei = newPrice;
    }
}