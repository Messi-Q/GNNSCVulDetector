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

 contract URUNCrowdsale is Ownable{
  using SafeMath for uint256;
 
   
  TokenInterface public token;

   
  uint256 public startTime;
  uint256 public endTime;


   
  uint256 public ratePerWei = 800;

   
  uint256 public weiRaised;

  uint256 public TOKENS_SOLD;
  uint256 public TOKENS_BOUGHT;
  
  uint256 public minimumContributionPhase1;
  uint256 public minimumContributionPhase2;
  uint256 public minimumContributionPhase3;
  uint256 public minimumContributionPhase4;
  uint256 public minimumContributionPhase5;
  uint256 public minimumContributionPhase6;
  
  uint256 public maxTokensToSaleInClosedPreSale;
  
  uint256 public bonusInPhase1;
  uint256 public bonusInPhase2;
  uint256 public bonusInPhase3;
  uint256 public bonusInPhase4;
  uint256 public bonusInPhase5;
  uint256 public bonusInPhase6;
  
  
  bool public isCrowdsalePaused = false;
  
  uint256 public totalDurationInDays = 123 days;
  
  
  struct userInformation {
      address userAddress;
      uint tokensToBeSent;
      uint ethersToBeSent;
      bool isKYCApproved;
      bool recurringBuyer;
  }
  
  event usersAwaitingTokens(address[] users);
  mapping(address=>userInformation) usersBuyingInformation;
  address[] allUsers;
  address[] u;
  userInformation info;
   
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(uint256 _startTime, address _wallet, address _tokenAddress) public 
  {
    require(_wallet != 0x0);
    require(_startTime >=now);
    startTime = _startTime;  
    endTime = startTime + totalDurationInDays;
    require(endTime >= startTime);
   
    owner = _wallet;
    
    bonusInPhase1 = 30;
    bonusInPhase2 = 20;
    bonusInPhase3 = 15;
    bonusInPhase4 = 10;
    bonusInPhase5 = 75;
    bonusInPhase6 = 5;
    
    minimumContributionPhase1 = uint(3).mul(10 ** 17);  
    minimumContributionPhase2 = uint(5).mul(10 ** 16);  
    minimumContributionPhase3 = uint(5).mul(10 ** 16);  
    minimumContributionPhase4 = uint(5).mul(10 ** 16);  
    minimumContributionPhase5 = uint(5).mul(10 ** 16);  
    minimumContributionPhase6 = uint(5).mul(10 ** 16);  
    
    token = TokenInterface(_tokenAddress);
  }
  
  
    
   function () public  payable {
     buyTokens(msg.sender);
    }
    
    function determineBonus(uint tokens, uint ethersSent) internal view returns (uint256 bonus) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        
         
        if (timeElapsedInDays <16)
        {
            require(ethersSent>=minimumContributionPhase1);
            bonus = tokens.mul(bonusInPhase1); 
            bonus = bonus.div(100);
        }
         
        else if (timeElapsedInDays >=16 && timeElapsedInDays <47)
        {
            require(ethersSent>=minimumContributionPhase2);
            bonus = tokens.mul(bonusInPhase2); 
            bonus = bonus.div(100);
        }
          
        else if (timeElapsedInDays >=47 && timeElapsedInDays <62)
        {
            require(ethersSent>=minimumContributionPhase3);
            bonus = tokens.mul(bonusInPhase3); 
            bonus = bonus.div(100);
        }
         
        else if (timeElapsedInDays >=62 && timeElapsedInDays <78)
        {
           revert();
        }
         
        else if (timeElapsedInDays >=78 && timeElapsedInDays <93)
        {
            require(ethersSent>=minimumContributionPhase4);
            bonus = tokens.mul(bonusInPhase4); 
            bonus = bonus.div(100);
        }
         
        else if (timeElapsedInDays >=93 && timeElapsedInDays <108)
        {
            require(ethersSent>=minimumContributionPhase5);
            bonus = tokens.mul(bonusInPhase5); 
            bonus = bonus.div(10);   
            bonus = bonus.div(100);
        }
          
        else if (timeElapsedInDays >=108 && timeElapsedInDays <123)
        {
            require(ethersSent>=minimumContributionPhase6);
            bonus = tokens.mul(bonusInPhase6); 
            bonus = bonus.div(100);
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
    uint256 weiAmount = msg.value;
    
     
    uint256 tokens = weiAmount.mul(ratePerWei);
    uint256 bonus = determineBonus(tokens,weiAmount);
    tokens = tokens.add(bonus);
    
     
    if (usersBuyingInformation[beneficiary].recurringBuyer == false)
    {
        info = userInformation ({ userAddress: beneficiary, tokensToBeSent:tokens, ethersToBeSent:weiAmount, isKYCApproved:false,
                                recurringBuyer:true});
        usersBuyingInformation[beneficiary] = info;
        allUsers.push(beneficiary);
    }
     
    else 
    {
        info = usersBuyingInformation[beneficiary];
        info.tokensToBeSent = info.tokensToBeSent.add(tokens);
        info.ethersToBeSent = info.ethersToBeSent.add(weiAmount);
        usersBuyingInformation[beneficiary] = info;
    }
    TOKENS_BOUGHT = TOKENS_BOUGHT.add(tokens);
    emit TokenPurchase(owner, beneficiary, weiAmount, tokens);
    
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
  
     
    function changeStartAndEndDate (uint256 startTimeUnixTimestamp, uint256 endTimeUnixTimestamp) public onlyOwner
    {
        require (startTimeUnixTimestamp!=0 && endTimeUnixTimestamp!=0);
        require(endTimeUnixTimestamp>startTimeUnixTimestamp);
        require(endTimeUnixTimestamp.sub(startTimeUnixTimestamp) >=totalDurationInDays);
        startTime = startTimeUnixTimestamp;
        endTime = endTimeUnixTimestamp;
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
    
   
       
     function takeTokensBack() public onlyOwner
     {
         uint remainingTokensInTheContract = token.balanceOf(address(this));
         token.transfer(owner,remainingTokensInTheContract);
     }
     
       
     function manualTokenTransfer(address receiver, uint value) public onlyOwner
     {
         token.transfer(receiver,value);
         TOKENS_SOLD = TOKENS_SOLD.add(value);
         TOKENS_BOUGHT = TOKENS_BOUGHT.add(value);
     }
     
       
     function approveSingleUser(address user) public onlyOwner {
        usersBuyingInformation[user].isKYCApproved = true;    
     }
     
      
     function disapproveSingleUser(address user) public onlyOwner {
         usersBuyingInformation[user].isKYCApproved = false;  
     }
     
      
     function approveMultipleUsers(address[] users) public onlyOwner {
         
         for (uint i=0;i<users.length;i++)
         {
            usersBuyingInformation[users[i]].isKYCApproved = true;    
         }
     }
     
      
     function distributeTokensToApprovedUsers() public onlyOwner {
        for(uint i=0;i<allUsers.length;i++)
        {
            if (usersBuyingInformation[allUsers[i]].isKYCApproved == true && usersBuyingInformation[allUsers[i]].tokensToBeSent>0)
            {
                address to = allUsers[i];
                uint tokens = usersBuyingInformation[to].tokensToBeSent;
                token.transfer(to,tokens);
                if (usersBuyingInformation[allUsers[i]].ethersToBeSent>0)
                    owner.transfer(usersBuyingInformation[allUsers[i]].ethersToBeSent);
                TOKENS_SOLD = TOKENS_SOLD.add(usersBuyingInformation[allUsers[i]].tokensToBeSent);
                weiRaised = weiRaised.add(usersBuyingInformation[allUsers[i]].ethersToBeSent);
                usersBuyingInformation[allUsers[i]].tokensToBeSent = 0;
                usersBuyingInformation[allUsers[i]].ethersToBeSent = 0;
            }
        }
     }
     
       
     function distributeTokensToAllUsers() public onlyOwner {
        for(uint i=0;i<allUsers.length;i++)
        {
            if (usersBuyingInformation[allUsers[i]].tokensToBeSent>0)
            {
                address to = allUsers[i];
                uint tokens = usersBuyingInformation[to].tokensToBeSent;
                token.transfer(to,tokens);
                if (usersBuyingInformation[allUsers[i]].ethersToBeSent>0)
                    owner.transfer(usersBuyingInformation[allUsers[i]].ethersToBeSent);
                TOKENS_SOLD = TOKENS_SOLD.add(usersBuyingInformation[allUsers[i]].tokensToBeSent);
                weiRaised = weiRaised.add(usersBuyingInformation[allUsers[i]].ethersToBeSent);
                usersBuyingInformation[allUsers[i]].tokensToBeSent = 0;
                usersBuyingInformation[allUsers[i]].ethersToBeSent = 0;
            }
        }
     }
     
      
     function refundSingleUser(address user) public onlyOwner {
         require(usersBuyingInformation[user].ethersToBeSent > 0 );
         user.transfer(usersBuyingInformation[user].ethersToBeSent);
         usersBuyingInformation[user].tokensToBeSent = 0;
         usersBuyingInformation[user].ethersToBeSent = 0;
     }
     
      
     function refundMultipleUsers(address[] users) public onlyOwner {
         for (uint i=0;i<users.length;i++)
         {
            require(usersBuyingInformation[users[i]].ethersToBeSent >0);
            users[i].transfer(usersBuyingInformation[users[i]].ethersToBeSent);
            usersBuyingInformation[users[i]].tokensToBeSent = 0;
            usersBuyingInformation[users[i]].ethersToBeSent = 0;
         }
     }
       
     function transferOutAllEthers() public onlyOwner {
         owner.transfer(address(this).balance);
     }
     
       
     function getUsersAwaitingForTokensTop150(bool fetch) public constant returns (address[150])  {
          address[150] memory awaiting;
         uint k = 0;
         for (uint i=0;i<allUsers.length;i++)
         {
             if (usersBuyingInformation[allUsers[i]].isKYCApproved == true && usersBuyingInformation[allUsers[i]].tokensToBeSent>0)
             {
                 awaiting[k] = allUsers[i];
                 k = k.add(1);
                 if (k==150)
                    return awaiting;
             }
         }
         return awaiting;
     }
     
       
     function getUsersAwaitingForTokens() public onlyOwner returns (address[])  {
         delete u;
         for (uint i=0;i<allUsers.length;i++)
         {
             if (usersBuyingInformation[allUsers[i]].isKYCApproved == true && usersBuyingInformation[allUsers[i]].tokensToBeSent>0)
             {
                 u.push(allUsers[i]);
             }
         }
         emit usersAwaitingTokens(u);
         return u;
     }
     
       
     function getUserInfo(address userAddress) public constant returns(uint _ethers, uint _tokens, bool _isApproved)
     {
         _ethers = usersBuyingInformation[userAddress].ethersToBeSent;
         _tokens = usersBuyingInformation[userAddress].tokensToBeSent;
         _isApproved = usersBuyingInformation[userAddress].isKYCApproved;
         return(_ethers,_tokens,_isApproved);
         
     }
     
      
      function closeUser(address userAddress) public onlyOwner 
      {
           
           
          uint ethersByTheUser =  usersBuyingInformation[userAddress].ethersToBeSent;
          usersBuyingInformation[userAddress].isKYCApproved = false;
          usersBuyingInformation[userAddress].ethersToBeSent = 0;
          usersBuyingInformation[userAddress].tokensToBeSent = 0;
          usersBuyingInformation[userAddress].recurringBuyer = true;
          owner.transfer(ethersByTheUser);
      } 
      
      
      function getUnapprovedUsersTop150(bool fetch) public constant returns (address[150]) 
      {
         address[150] memory unapprove;
         uint k = 0;
         for (uint i=0;i<allUsers.length;i++)
         {
             if (usersBuyingInformation[allUsers[i]].isKYCApproved == false)
             {
                 unapprove[k] = allUsers[i];
                 k = k.add(1);
                 if (k==150)
                    return unapprove;
             }
         }
         return unapprove;
      } 
      
        
      function getUnapprovedUsers() public onlyOwner returns (address[]) 
      {
         delete u;
         for (uint i=0;i<allUsers.length;i++)
         {
             if (usersBuyingInformation[allUsers[i]].isKYCApproved == false)
             {
                 u.push(allUsers[i]);
             }
         }
         emit usersAwaitingTokens(u);
         return u;
      } 
      
       
      function getAllUsers(bool fetch) public constant returns (address[]) 
      {
          return allUsers;
      } 
      
        
      function changeUserEthAddress(address oldEthAddress, address newEthAddress) public onlyOwner 
      {
          usersBuyingInformation[newEthAddress] = usersBuyingInformation[oldEthAddress];
          for (uint i=0;i<allUsers.length;i++)
          {
              if (allUsers[i] == oldEthAddress)
                allUsers[i] = newEthAddress;
          }
          delete usersBuyingInformation[oldEthAddress];
      }
      
        
      function addUser(address userAddr, uint tokens) public onlyOwner 
      {
             
            if (usersBuyingInformation[userAddr].recurringBuyer == false)
            {
                info = userInformation ({ userAddress: userAddr, tokensToBeSent:tokens, ethersToBeSent:0, isKYCApproved:false,
                                recurringBuyer:true});
                usersBuyingInformation[userAddr] = info;
                allUsers.push(userAddr);
            }
             
            else 
            {
                info = usersBuyingInformation[userAddr];
                info.tokensToBeSent = info.tokensToBeSent.add(tokens);
                usersBuyingInformation[userAddr] = info;
            }
            TOKENS_BOUGHT = TOKENS_BOUGHT.add(tokens);
      }
      
        
      function setTokensBought(uint tokensBought) public onlyOwner 
      {
          TOKENS_BOUGHT = tokensBought;
      }
      
        
      function getTokensBought() public constant returns(uint) 
      {
          return TOKENS_BOUGHT;
      }
      
}