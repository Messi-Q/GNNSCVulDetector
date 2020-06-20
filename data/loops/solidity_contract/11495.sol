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
     function addPrivateSaleBuyer(address buyer,uint value) external;
     function addPreSaleBuyer(address buyer,uint value) external;
     function addPrivateSaleEndDate(uint256 endDate) external;
     function addPreSaleEndDate(uint256 endDate) external;
     function addICOEndDate(uint256 endDate) external;
     function addTeamAndAdvisoryMembers(address[] members) external;
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     event Burn(address indexed burner, uint256 value);
}

 contract FeedCrowdsale is Ownable{
  using SafeMath for uint256;
 
   
  TokenInterface public token;

   
  uint256 public startTime;
  uint256 public endTime;


   
  uint256 public ratePerWei = 11905;

   
  uint256 public weiRaised;
  
  uint256 public weiRaisedInPreICO;

  uint256 TOKENS_SOLD;

  uint256 maxTokensToSaleInPrivateSale;
  uint256 maxTokensToSaleInPreICO;
  uint256 maxTokensToSale;
  
  uint256 bonusInPrivateSale;

  bool isCrowdsalePaused = false;
  
  uint256 minimumContributionInPrivatePhase;
  uint256 minimumContributionInPreICO;
  uint256 maximumContributionInPreICO;
  uint256 maximumContributionInMainICO;
  
  uint256 totalDurationInDays = 112 days;
  uint256 decimals = 18;
  
  uint256 hardCap = 46200 ether;
  uint256 softCapForPreICO = 1680 ether;
  
  address[] tokenBuyers;
  
  mapping(address=>uint256) EthersSentByBuyers; 
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(uint256 _startTime, address _wallet, address _tokenAddress) public 
  {
    require(_startTime >=now);
    require(_wallet != 0x0);
    startTime = _startTime;  
    endTime = startTime + totalDurationInDays;
    require(endTime >= startTime);
    owner = _wallet;
    maxTokensToSaleInPrivateSale = 100000000 * 10 ** uint256(decimals);
    maxTokensToSaleInPreICO = 200000000 * 10 ** uint256(decimals);
    maxTokensToSale = 550000000 * 10 ** uint256(decimals);
    bonusInPrivateSale = 100;
    
    minimumContributionInPrivatePhase = 168 ether;
    minimumContributionInPreICO = 1.68 ether;
    maximumContributionInPreICO = 1680 ether;
    maximumContributionInMainICO = 168 ether;
    token = TokenInterface(_tokenAddress);
  }
  
  
    
   function () public  payable {
     buyTokens(msg.sender);
    }
    
    function determineBonus(uint tokens, uint amountSent, address sender) internal returns (uint256 bonus) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        
         
        if (timeElapsedInDays <30)
        {
            require(amountSent>=minimumContributionInPrivatePhase);
            bonus = tokens.mul(bonusInPrivateSale);
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPrivateSale);  
            token.addPrivateSaleBuyer(sender,tokens.add(bonus));
        }
         
        else if (timeElapsedInDays >=30 && timeElapsedInDays <51)
        {
            revert();
        }
         
        else if (timeElapsedInDays>=51 && timeElapsedInDays<72)
        {
            require(amountSent>=minimumContributionInPreICO && amountSent<=maximumContributionInPreICO);
            if (amountSent>=1.68 ether && amountSent < 17 ether)
            {
                bonus = tokens.mul(5);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreICO); 
            }
            else if (amountSent>=17 ether && amountSent < 169 ether)
            {
                bonus = tokens.mul(10);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreICO); 
            }
            else if (amountSent>=169 ether && amountSent < 841 ether)
            {
                bonus = tokens.mul(15);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreICO); 
            }
            else if (amountSent>=841 ether && amountSent < 1680 ether)
            {
                bonus = tokens.mul(20);
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreICO); 
            }
             
            if (EthersSentByBuyers[sender] == 0)
            {
                EthersSentByBuyers[sender] = amountSent;
                tokenBuyers.push(sender);
            }
            else 
            {
                EthersSentByBuyers[sender] = EthersSentByBuyers[sender].add(amountSent);
            }
            weiRaisedInPreICO = weiRaisedInPreICO.add(amountSent);
            token.addPreSaleBuyer(sender,tokens.add(bonus));
        }
         
        else if (timeElapsedInDays>=72 && timeElapsedInDays<83)
        {
            revert();
        }
         
        else if(timeElapsedInDays>=83)
        {
            require(amountSent<=maximumContributionInMainICO);
            bonus = 0;
        }
    }

   
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(isCrowdsalePaused == false);
    require(validPurchase());
    require(TOKENS_SOLD<maxTokensToSale && weiRaised<hardCap);
   
    uint256 weiAmount = msg.value;
    
     
    uint256 tokens = weiAmount.mul(ratePerWei);
    uint256 bonus = determineBonus(tokens,weiAmount,beneficiary);
    tokens = tokens.add(bonus);
    require(TOKENS_SOLD.add(tokens)<=maxTokensToSale);
    
     
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
    
     
    function setPriceRate(uint256 newPrice) public onlyOwner {
        ratePerWei = newPrice;
    }
    
      
     
    function pauseCrowdsale() public onlyOwner {
        isCrowdsalePaused = true;
    }

      
    function resumeCrowdsale() public onlyOwner {
        isCrowdsalePaused = false;
    }
    
      
      
     function remainingTokensForSale() public constant returns (uint) {
         return maxTokensToSale.sub(TOKENS_SOLD);
     }
     
     function getUnsoldTokensBack() public onlyOwner
     {
        uint contractTokenBalance = token.balanceOf(address(this));
        require(contractTokenBalance>0);
        token.transfer(owner,contractTokenBalance);
     }
     
       
     function RefundToBuyers() public payable onlyOwner {
          
         require(weiRaised<softCapForPreICO);
         require(msg.value>=weiRaisedInPreICO);
         for (uint i=0;i<tokenBuyers.length;i++)
         {
             uint etherAmount = EthersSentByBuyers[tokenBuyers[i]];
             if (etherAmount>0)
             {
                tokenBuyers[i].transfer(etherAmount);
                EthersSentByBuyers[tokenBuyers[i]] = 0;
             }
         }
     }
       
     function addTeamAndAdvisoryMembers(address[] members) public onlyOwner {
         token.addTeamAndAdvisoryMembers(members);
     }
     
      
     function getPrivateSaleEndDate() public view onlyOwner returns (uint) {
         return startTime.add(30 days);
     }
     
      
     function getPreSaleEndDate() public view onlyOwner returns (uint) {
          return startTime.add(72 days);
     }
     
      
     function getICOEndDate() public view onlyOwner returns (uint) {
          return startTime.add(112 days);
     }
     
      
      function setPrivateSaleEndDate(uint256 timestamp) public onlyOwner  {
          token.addPrivateSaleEndDate(timestamp);
      }
      
      
       function setPreSaleEndDate(uint256 timestamp) public onlyOwner {
           token.addPreSaleEndDate(timestamp);
       }
       
      
        function setICOEndDate(uint timestamp) public onlyOwner {
           token.addICOEndDate(timestamp);
       }
}