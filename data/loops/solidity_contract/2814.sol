 
 
 
 
 
 
 
 
 


pragma solidity ^0.4.24;

 
 
 
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



 
 
 

contract EthertoteToken {
    function thisContractAddress() public pure returns (address) {}
    function balanceOf(address) public pure returns (uint256) {}
    function transfer(address, uint) public {}
}


 
 
 

contract TokenSale {
  using SafeMath for uint256;
  
  EthertoteToken public token;

  address public admin;
  address public thisContractAddress;

   
  address public tokenContractAddress = 0x42be9831FFF77972c1D0E1eC0aA9bdb3CaA04D47;
  
   
   
  address public tokenBurnAddress = 0xadCa18DC9489C5FE5BdDf1A8a8C2623B66029198;
  
   
   
  address public ethRaisedAddress = 0x9F73D808807c71Af185FEA0c1cE205002c74123C;
  
  uint public preIcoPhaseCountdown;        
  uint public icoPhaseCountdown;           
  uint public postIcoPhaseCountdown;       
  
   
  bool public tokenSaleIsPaused;
  
   
  uint public tokenSalePausedTime;
  
   
  uint public tokenSaleResumedTime;
  
   
   
  uint public tokenSalePausedDuration;
  
   
  uint256 public weiRaised;
  
   
  uint public maxEthRaised = 9000;
  
   
   
   
  uint public maxWeiRaised = maxEthRaised.mul(1000000000000000000);

   
   
  uint public openingTime = 1535385600;
  uint public closingTime = openingTime.add(7 days);
  
   
   
  uint public rate = 1000000000000000;
  
   
  uint public minSpend = 100000000000000000;     
  uint public maxSpend = 100000000000000000000;  

  
   
  modifier onlyAdmin { 
        require(msg.sender == admin
        ); 
        _; 
  }
  
   
  event Deployed(string, uint);
  event SalePaused(string, uint);
  event SaleResumed(string, uint);
  event TokensBurned(string, uint);
  
  
  
  
  
  
 
  constructor() public {
    
    admin = msg.sender;
    thisContractAddress = address(this);

    token = EthertoteToken(tokenContractAddress);
    

    require(ethRaisedAddress != address(0));
    require(tokenContractAddress != address(0));
    require(tokenBurnAddress != address(0));

    preIcoPhaseCountdown = openingTime;
    icoPhaseCountdown = closingTime;
    
     
     
    postIcoPhaseCountdown = closingTime.add(14 days);
    
    emit Deployed("Ethertote Token Sale contract deployed", now);
  }
  
  
  
   
  function tokenSaleTokenBalance() public view returns(uint) {
      return token.balanceOf(thisContractAddress);
  }
  
   
  function getAnyAddressTokenBalance(address _address) public view returns(uint) {
      return token.balanceOf(_address);
  }
  
   
  function tokenSaleHasFinished() public view returns (bool) {
    return now > closingTime;
  }
  
   
   
  function burnUnsoldTokens() public {
      require(tokenSaleIsPaused == false);
      require(tokenSaleHasFinished() == true);
      token.transfer(tokenBurnAddress, tokenSaleTokenBalance());
      emit TokensBurned("tokens sent to TokenBurn contract", now);
  }



   
  function pauseTokenSale() onlyAdmin public {
       
      require(tokenSaleHasFinished() == false);
      
       
      require(tokenSaleIsPaused == false);
      
       
      tokenSaleIsPaused = true;
      tokenSalePausedTime = now;
      emit SalePaused("token sale has been paused", now);
  }
  
     
  function resumeTokenSale() onlyAdmin public {
      
       
      require(tokenSaleIsPaused == true);
      
      tokenSaleResumedTime = now;
      
       
       
       
      
       
       
       
      
      tokenSalePausedDuration = tokenSaleResumedTime.sub(tokenSalePausedTime);
      
       
      
      closingTime = closingTime.add(tokenSalePausedDuration);
      
       
      postIcoPhaseCountdown = closingTime.add(14 days);
       
      tokenSaleIsPaused = false;
      emit SaleResumed("token sale has now resumed", now);
  }
  

 
 
 
 
 
 
 
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );



 
 
 


 
 
 
 
 
   
  function () external payable {
    buyTokens(msg.sender);
  }


 
 
 
 
  function buyTokens(address buyer) public payable {
    
     
    require(openingTime <= block.timestamp);
    require(block.timestamp < closingTime);
    
     
    require(msg.value >= minSpend);
    
     
     
    require(msg.value <= maxSpend);
    
     
    require(tokenSaleTokenBalance() > 0);
    
     
    require(tokenSaleIsPaused == false);
    
     
    uint256 weiAmount = msg.value;
    preValidatePurchase(buyer, weiAmount);

     
    uint256 tokens = getTokenAmount(weiAmount);
    
     
     
    require(tokens <= tokenSaleTokenBalance());

     
    weiRaised = weiRaised.add(weiAmount);

    processPurchase(buyer, tokens);
    emit TokenPurchase(
      msg.sender,
      buyer,
      weiAmount,
      tokens
    );

    updatePurchasingState(buyer, weiAmount);

    forwardFunds();
    postValidatePurchase(buyer, weiAmount);
  }

   
   
   

 
 
 
  function preValidatePurchase(
    address buyer,
    uint256 weiAmount
  )
    internal pure
  {
    require(buyer != address(0));
    require(weiAmount != 0);
  }

 
 
 
  function postValidatePurchase(
    address,
    uint256
  )
    internal pure
  {
     
  }

 
 
 
  function deliverTokens(
    address buyer,
    uint256 tokenAmount
  )
    internal
  {
    token.transfer(buyer, tokenAmount);
  }

 
 
 
 
  function processPurchase(
    address buyer,
    uint256 tokenAmount
  )
    internal
  {
    deliverTokens(buyer, tokenAmount);
  }

 
 
 
 
  function updatePurchasingState(
    address,
    uint256
  )
    internal pure
  {
     
  }

 
 
 
 
 
  function getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.div(rate);
  }

 
 
 
 
  function forwardFunds() internal {
    ethRaisedAddress.transfer(msg.value);
  }
  

 

    function maximumRaised() public view returns(uint) {
        return maxWeiRaised;
    }
    
    function amountRaised() public view returns(uint) {
        return weiRaised;
    }
  
    function timeComplete() public view returns(uint) {
        return closingTime;
    }
    
     
    function delayOpeningTime(uint256 _openingTime) onlyAdmin public {  
    openingTime = _openingTime;
    closingTime = openingTime.add(7 days);
    preIcoPhaseCountdown = openingTime;
    icoPhaseCountdown = closingTime;
    postIcoPhaseCountdown = closingTime.add(14 days);
    }
    
  
}