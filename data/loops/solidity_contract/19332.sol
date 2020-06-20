pragma solidity 0.4.21;


 
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

interface TokenInterface {
     function totalSupply() external constant returns (uint);
     function balanceOf(address tokenOwner) external constant returns (uint balance);
     function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
     function transfer(address to, uint tokens) external returns (bool success);
     function approve(address spender, uint tokens) external returns (bool success);
     function transferFrom(address from, address to, uint tokens) external returns (bool success);
     function burn(uint256 _value) external; 
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     event Burn(address indexed burner, uint256 value);
}

 contract PVCCrowdsale is Ownable{
  using SafeMath for uint256;
 
   
  TokenInterface public token;

   
  uint256 public startTime;
  uint256 public endTime;


   
  uint256 public ratePerWei = 1000;

   
  uint256 public weiRaised;

  uint256 public TOKENS_SOLD;
  
  uint256 maxTokensToSale;
  uint256 TokensForTeamVesting;
  uint256 TokensForAdvisorVesting;
  uint256 bonusInPreSalePhase1;
  uint256 bonusInPreSalePhase2;
  uint256 bonusInPublicSalePhase1;
  uint256 bonusInPublicSalePhase2;
  uint256 bonusInPublicSalePhase3;
  
  bool isCrowdsalePaused = false;
  
  uint256 totalDurationInDays = 75 days;
  mapping(address=>bool) isAddressWhiteListed;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function PVCCrowdsale(uint256 _startTime, address _wallet, address _tokenAddress) public 
  {
    
    require(_wallet != 0x0);
     
    require(_startTime >=now);
    startTime = _startTime;  
    
     
     
    endTime = startTime + totalDurationInDays;
    require(endTime >= startTime);
   
    owner = _wallet;
    
    maxTokensToSale = 32500000 * 10 ** 18;
    
    bonusInPreSalePhase1 = 30;
    bonusInPreSalePhase2 = 25;
    bonusInPublicSalePhase1 = 20;
    bonusInPreSalePhase2 = 10;
    bonusInPublicSalePhase3 = 5;
    
    TokensForTeamVesting = 7000000 * 10 ** 18;
    TokensForAdvisorVesting = 3000000 * 10 ** 18;
    token = TokenInterface(_tokenAddress);
  }
  
  
    
   function () public  payable {
     buyTokens(msg.sender);
    }
    
  function determineBonus(uint tokens) internal view returns (uint256 bonus) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        
         
        if (timeElapsedInDays <8)
        {
            bonus = tokens.mul(bonusInPreSalePhase1); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
         
        else if (timeElapsedInDays >=8 && timeElapsedInDays <16)
        {
            bonus = tokens.mul(bonusInPreSalePhase2); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
         
        else if (timeElapsedInDays >=16 && timeElapsedInDays <46)
        {
            bonus = tokens.mul(bonusInPublicSalePhase1); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
          
        else if (timeElapsedInDays >=46 && timeElapsedInDays <57)
        {
            bonus = tokens.mul(bonusInPublicSalePhase2); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
         
        else if (timeElapsedInDays >=57 && timeElapsedInDays <63)
        {
            bonus = tokens.mul(bonusInPublicSalePhase3); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
        }
         
        else 
        {
            bonus = 0;
        }
    }
   
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(isCrowdsalePaused == false);
    require(isAddressWhiteListed[beneficiary] == true);
    require(validPurchase());
    
    require(TOKENS_SOLD<maxTokensToSale);
   
    uint256 weiAmount = msg.value;
    
     
    uint256 tokens = weiAmount.mul(ratePerWei);
    uint256 bonus = determineBonus(tokens);
    tokens = tokens.add(bonus);
    
     
    weiRaised = weiRaised.add(weiAmount);
    
    token.transfer(beneficiary,tokens);
    emit TokenPurchase(owner, beneficiary, weiAmount, tokens);
    TOKENS_SOLD = TOKENS_SOLD.add(tokens);
    forwardFunds();
  }

   
  function forwardFunds() internal {
    owner.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
  
    
    function changeEndDate(uint256 endTimeUnixTimestamp) public onlyOwner{
        endTime = endTimeUnixTimestamp;
    }
    
     
    
    function changeStartDate(uint256 startTimeUnixTimestamp) public onlyOwner{
        startTime = startTimeUnixTimestamp;
    }
    
     
    function setPriceRate(uint256 newPrice) public onlyOwner {
        ratePerWei = newPrice;
    }
    
      
     
    function pauseCrowdsale() public onlyOwner {
        isCrowdsalePaused = true;
    }

      
    function resumeCrowdsale() public onlyOwner {
        isCrowdsalePaused = false;
    }
    
      
    function addAddressToWhitelist(address _whitelist) public onlyOwner
    {
        isAddressWhiteListed[_whitelist]= true;
    }
      
    function removeAddressToWhitelist(address _whitelist) public onlyOwner
    {
        isAddressWhiteListed[_whitelist]= false;
    }
       
     function takeTokensBack() public onlyOwner
     {
         uint remainingTokensInTheContract = token.balanceOf(address(this));
         token.transfer(owner,remainingTokensInTheContract);
     }
     
       
     function sendUnsoldTokensToTreasury(address treasury) public onlyOwner
     {
         require(hasEnded());
         uint remainingTokensInTheContract = token.balanceOf(address(this));
         token.transfer(treasury,remainingTokensInTheContract);
     }
}