pragma solidity 0.4.24;


 
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

 contract KRCICOContract is Ownable{
  using SafeMath for uint256;
 
   
  TokenInterface public token;

   
  uint256 public startTime;
  uint256 public endTime;


   
  uint256 public ratePerWei; 

   
  uint256 public weiRaised;

  uint256 public TOKENS_SOLD;
  
  uint256 maxTokensToSale;
  
  uint256 bonusInPhase1;
  uint256 bonusInPhase2;
  uint256 bonusInPhase3;
  
  uint256 minimumContribution;
  uint256 maximumContribution;
  
  bool isCrowdsalePaused = false;
  
  uint256 totalDurationInDays = 87 days;
  
  uint256 LongTermFoundationBudgetAccumulated;
  uint256 LegalContingencyFundsAccumulated;
  uint256 MarketingAndCommunityOutreachAccumulated;
  uint256 CashReserveFundAccumulated;
  uint256 OperationalExpensesAccumulated;
  uint256 SoftwareProductDevelopmentAccumulated;
  uint256 FoundersTeamAndAdvisorsAccumulated;
  
  uint256 LongTermFoundationBudgetPercentage;
  uint256 LegalContingencyFundsPercentage;
  uint256 MarketingAndCommunityOutreachPercentage;
  uint256 CashReserveFundPercentage;
  uint256 OperationalExpensesPercentage;
  uint256 SoftwareProductDevelopmentPercentage;
  uint256 FoundersTeamAndAdvisorsPercentage;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(uint256 _startTime, address _wallet, address _tokenAddress) public 
  {
    require(_startTime >=now);
    require(_wallet != 0x0);

    startTime = _startTime;  
    endTime = startTime + totalDurationInDays;
    require(endTime >= startTime);
   
    owner = _wallet;
    
    maxTokensToSale = 157500000e18;
    bonusInPhase1 = 20;
    bonusInPhase2 = 15;
    bonusInPhase3 = 10;
    minimumContribution = 5e17;
    maximumContribution = 150e18;
    ratePerWei = 40e18;
    token = TokenInterface(_tokenAddress);
    
    LongTermFoundationBudgetAccumulated = 0;
    LegalContingencyFundsAccumulated = 0;
    MarketingAndCommunityOutreachAccumulated = 0;
    CashReserveFundAccumulated = 0;
    OperationalExpensesAccumulated = 0;
    SoftwareProductDevelopmentAccumulated = 0;
    FoundersTeamAndAdvisorsAccumulated = 0;
  
    LongTermFoundationBudgetPercentage = 15;
    LegalContingencyFundsPercentage = 10;
    MarketingAndCommunityOutreachPercentage = 10;
    CashReserveFundPercentage = 20;
    OperationalExpensesPercentage = 10;
    SoftwareProductDevelopmentPercentage = 15;
    FoundersTeamAndAdvisorsPercentage = 20;
  }
  
  
    
   function () public  payable {
    buyTokens(msg.sender);
    }
    
    function calculateTokens(uint value) internal view returns (uint256 tokens) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        uint256 bonus = 0;
         
        if (timeElapsedInDays <15)
        {
            tokens = value.mul(ratePerWei);
            bonus = tokens.mul(bonusInPhase1); 
            bonus = bonus.div(100);
            tokens = tokens.add(bonus);
            require (TOKENS_SOLD.add(tokens) <= maxTokensToSale);
        }
         
        else if (timeElapsedInDays >=15 && timeElapsedInDays <30)
        {
            tokens = value.mul(ratePerWei);
            bonus = tokens.mul(bonusInPhase2); 
            bonus = bonus.div(100);
            tokens = tokens.add(bonus);
            require (TOKENS_SOLD.add(tokens) <= maxTokensToSale);
        }
         
        else if (timeElapsedInDays >=30 && timeElapsedInDays <45)
        {
            tokens = value.mul(ratePerWei);
            bonus = tokens.mul(bonusInPhase3); 
            bonus = bonus.div(100);
            tokens = tokens.add(bonus);
            require (TOKENS_SOLD.add(tokens) <= maxTokensToSale);
        }
        else 
        {
            bonus = 0;
        }
    }

   
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(isCrowdsalePaused == false);
    require(validPurchase());

    
    require(TOKENS_SOLD<maxTokensToSale);
   
    uint256 weiAmount = msg.value.div(10**16);
    
    uint256 tokens = calculateTokens(weiAmount);
    require(TOKENS_SOLD.add(tokens)<=maxTokensToSale);
     
    weiRaised = weiRaised.add(msg.value);
    
    token.transfer(beneficiary,tokens);
    emit TokenPurchase(owner, beneficiary, msg.value, tokens);
    TOKENS_SOLD = TOKENS_SOLD.add(tokens);
    distributeFunds();
  }
  
  function distributeFunds() internal {
      uint received = msg.value;
      
      LongTermFoundationBudgetAccumulated = LongTermFoundationBudgetAccumulated
                                            .add(received.mul(LongTermFoundationBudgetPercentage)
                                            .div(100));
      
      LegalContingencyFundsAccumulated = LegalContingencyFundsAccumulated
                                         .add(received.mul(LegalContingencyFundsPercentage)
                                         .div(100));
      
      MarketingAndCommunityOutreachAccumulated = MarketingAndCommunityOutreachAccumulated
                                                 .add(received.mul(MarketingAndCommunityOutreachPercentage)
                                                 .div(100));
      
      CashReserveFundAccumulated = CashReserveFundAccumulated
                                   .add(received.mul(CashReserveFundPercentage)
                                   .div(100));
      
      OperationalExpensesAccumulated = OperationalExpensesAccumulated
                                       .add(received.mul(OperationalExpensesPercentage)
                                       .div(100));
      
      SoftwareProductDevelopmentAccumulated = SoftwareProductDevelopmentAccumulated
                                              .add(received.mul(SoftwareProductDevelopmentPercentage)
                                              .div(100));
      
      FoundersTeamAndAdvisorsAccumulated = FoundersTeamAndAdvisorsAccumulated
                                            .add(received.mul(FoundersTeamAndAdvisorsPercentage)
                                            .div(100));
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    bool withinContributionLimit = msg.value >= minimumContribution && msg.value <= maximumContribution;
    return withinPeriod && nonZeroPurchase && withinContributionLimit;
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
    
      
     
    function pauseCrowdsale() public onlyOwner {
        isCrowdsalePaused = true;
    }

      
    function resumeCrowdsale() public onlyOwner {
        isCrowdsalePaused = false;
    }
     
     function takeTokensBack() public onlyOwner
     {
         uint remainingTokensInTheContract = token.balanceOf(address(this));
         token.transfer(owner,remainingTokensInTheContract);
     }
     
      
    function changeMinimumContribution(uint256 minContribution) public onlyOwner {
        minimumContribution = minContribution;
    }
    
      
    function changeMaximumContribution(uint256 maxContribution) public onlyOwner {
        maximumContribution = maxContribution;
    }
    
       
    function withdrawLongTermFoundationBudget() public onlyOwner {
        require(LongTermFoundationBudgetAccumulated > 0);
        owner.transfer(LongTermFoundationBudgetAccumulated);
        LongTermFoundationBudgetAccumulated = 0;
    }
    
      
     
    function withdrawLegalContingencyFunds() public onlyOwner {
        require(LegalContingencyFundsAccumulated > 0);
        owner.transfer(LegalContingencyFundsAccumulated);
        LegalContingencyFundsAccumulated = 0;
    }
    
      
    function withdrawMarketingAndCommunityOutreach() public onlyOwner {
        require (MarketingAndCommunityOutreachAccumulated > 0);
        owner.transfer(MarketingAndCommunityOutreachAccumulated);
        MarketingAndCommunityOutreachAccumulated = 0;
    }
    
      
    function withdrawCashReserveFund() public onlyOwner {
        require(CashReserveFundAccumulated > 0);
        owner.transfer(CashReserveFundAccumulated);
        CashReserveFundAccumulated = 0;
    }
    
      
    function withdrawOperationalExpenses() public onlyOwner {
        require(OperationalExpensesAccumulated > 0);
        owner.transfer(OperationalExpensesAccumulated);
        OperationalExpensesAccumulated = 0;
    }
    
      
    function withdrawSoftwareProductDevelopment() public onlyOwner {
        require (SoftwareProductDevelopmentAccumulated > 0);
        owner.transfer(SoftwareProductDevelopmentAccumulated);
        SoftwareProductDevelopmentAccumulated = 0;
    }
    
      
    function withdrawFoundersTeamAndAdvisors() public onlyOwner {
        require (FoundersTeamAndAdvisorsAccumulated > 0);
        owner.transfer(FoundersTeamAndAdvisorsAccumulated);
        FoundersTeamAndAdvisorsAccumulated = 0;
    }
    
      
    function withdrawAllFunds() public onlyOwner {
        require (address(this).balance > 0);
        owner.transfer(address(this).balance);
    }
}