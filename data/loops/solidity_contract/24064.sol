pragma solidity ^0.4.18;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract owned {
  address public owner;

  function owned() internal {
    owner = msg.sender;
  }
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}

contract safeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    safeAssert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    safeAssert(b > 0);
    uint256 c = a / b;
    safeAssert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    safeAssert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    safeAssert(c>=a && c>=b);
    return c;
  }

  function safeAssert(bool assertion) internal pure {
    if (!assertion) revert();
  }
}

contract StandardToken is owned, safeMath {
  function balanceOf(address who) view public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract EPXCrowdsale is owned, safeMath {
   
  address        public admin                     = owner;     
  StandardToken  public tokenReward;                           

   
  uint256 private initialTokenSupply;
  uint256 private tokensRemaining;

   
  address private beneficiaryWallet;                            

   
  uint256 public amountRaisedInWei;                            
  uint256 public fundingMinCapInWei;                           

   
  string  public CurrentStatus                    = "";         
  uint256 public fundingStartBlock;                            
  uint256 public fundingEndBlock;                              
  bool    public isCrowdSaleClosed               = false;      
  bool    private areFundsReleasedToBeneficiary  = false;      
  bool    public isCrowdSaleSetup                = false;      

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Buy(address indexed _sender, uint256 _eth, uint256 _EPX);
  event Refund(address indexed _refunder, uint256 _value);
  event Burn(address _from, uint256 _value);
  mapping(address => uint256) balancesArray;
  mapping(address => uint256) usersEPXfundValue;

   
  function EPXCrowdsale() public onlyOwner {
    admin = msg.sender;
    CurrentStatus = "Crowdsale deployed to chain";
  }

   
  function initialEPXSupply() public view returns (uint256 initialEPXtokenCount) {
    return safeDiv(initialTokenSupply,10000);  
  }

   
  function remainingEPXSupply() public view returns (uint256 remainingEPXtokenCount) {
    return safeDiv(tokensRemaining,10000);  
  }

   
  function SetupCrowdsale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) public onlyOwner returns (bytes32 response) {
    if ((msg.sender == admin)
    && (!(isCrowdSaleSetup))
    && (!(beneficiaryWallet > 0))) {
       
      beneficiaryWallet                       = 0x7A29e1343c6a107ce78199F1b3a1d2952efd77bA;
      tokenReward                             = StandardToken(0x35BAA72038F127f9f8C8f9B491049f64f377914d);

       
      fundingMinCapInWei                      = 30000000000000000000;                        

       
      amountRaisedInWei                       = 0;
      initialTokenSupply                      = 200000000000;                                
      tokensRemaining                         = initialTokenSupply;
      fundingStartBlock                       = _fundingStartBlock;
      fundingEndBlock                         = _fundingEndBlock;

       
      isCrowdSaleSetup                        = true;
      isCrowdSaleClosed                       = false;
      CurrentStatus                           = "Crowdsale is setup";
      return "Crowdsale is setup";
    } else if (msg.sender != admin) {
      return "not authorised";
    } else  {
      return "campaign cannot be changed";
    }
  }

  function checkPrice() internal view returns (uint256 currentPriceValue) {
    if (block.number >= fundingStartBlock+177534) {  
      return (7600);  
    } else if (block.number >= fundingStartBlock+124274) {  
      return (8200);  
    } else if (block.number >= fundingStartBlock) {  
      return (8800);  
    }
  }

   
  function () public payable {
     
    require(!(msg.value == 0)
    && (msg.data.length == 0)
    && (block.number <= fundingEndBlock)
    && (block.number >= fundingStartBlock)
    && (tokensRemaining > 0));

     
    uint256 rewardTransferAmount    = 0;

     
    amountRaisedInWei               = safeAdd(amountRaisedInWei, msg.value);
    rewardTransferAmount            = ((safeMul(msg.value, checkPrice())) / 100000000000000);

     
    tokensRemaining                 = safeSub(tokensRemaining, rewardTransferAmount);
    tokenReward.transfer(msg.sender, rewardTransferAmount);

     
    usersEPXfundValue[msg.sender]   = safeAdd(usersEPXfundValue[msg.sender], msg.value);
    Buy(msg.sender, msg.value, rewardTransferAmount);
  }

  function beneficiaryMultiSigWithdraw(uint256 _amount) public onlyOwner {
    require(areFundsReleasedToBeneficiary && (amountRaisedInWei >= fundingMinCapInWei));
    beneficiaryWallet.transfer(_amount);
    Transfer(this, beneficiaryWallet, _amount);
  }

  function checkGoalReached() public onlyOwner {  
     
    require (isCrowdSaleSetup);
    if ((amountRaisedInWei < fundingMinCapInWei) && (block.number <= fundingEndBlock && block.number >= fundingStartBlock)) {  
      areFundsReleasedToBeneficiary = false;
      isCrowdSaleClosed = false;
      CurrentStatus = "In progress (Eth < Softcap)";
    } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number < fundingStartBlock)) {  
      areFundsReleasedToBeneficiary = false;
      isCrowdSaleClosed = false;
      CurrentStatus = "Crowdsale is setup";
    } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number > fundingEndBlock)) {  
      areFundsReleasedToBeneficiary = false;
      isCrowdSaleClosed = true;
      CurrentStatus = "Unsuccessful (Eth < Softcap)";
    } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining == 0)) {  
      areFundsReleasedToBeneficiary = true;
      isCrowdSaleClosed = true;
      CurrentStatus = "Successful (EPX >= Hardcap)!";
    } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.number > fundingEndBlock) && (tokensRemaining > 0)) {  
      areFundsReleasedToBeneficiary = true;
      isCrowdSaleClosed = true;
      CurrentStatus = "Successful (Eth >= Softcap)!";
    } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining > 0) && (block.number <= fundingEndBlock)) {  
      areFundsReleasedToBeneficiary = true;
      isCrowdSaleClosed = false;
      CurrentStatus = "In progress (Eth >= Softcap)!";
    }
  }

  function refund() public {  
     
    require ((amountRaisedInWei < fundingMinCapInWei)
    && (isCrowdSaleClosed)
    && (block.number > fundingEndBlock)
    && (usersEPXfundValue[msg.sender] > 0));

     
    uint256 ethRefund = usersEPXfundValue[msg.sender];
    balancesArray[msg.sender] = 0;
    usersEPXfundValue[msg.sender] = 0;

     
    Burn(msg.sender, usersEPXfundValue[msg.sender]);

     
    msg.sender.transfer(ethRefund);

     
    Refund(msg.sender, ethRefund);
  }
}