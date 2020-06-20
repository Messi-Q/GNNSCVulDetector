pragma solidity ^0.4.21;


 
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


 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}


 
contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
   function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

  event Approval(address indexed owner,address indexed spender,uint256 value);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token,address from,address to,uint256 value) internal{
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}


contract PurchaseAdmin is Ownable{
    
  address public purchaseAdmin;
  
  bool public purchaseEnable = true;
  
  bool public grantEnable = true;
  
   
  uint256 public startAt;

   
  uint256 public stopAt;

   
  uint256 public grantAt;
  
  event PurchaseEnable(address indexed from, bool enable);
  
  event GrantEnable(address indexed from, bool enable);

  function PurchaseAdmin() public{
    purchaseAdmin = msg.sender;
  }

  function setPurchaseAdmin(address _purchaseAdmin) onlyOwner public {
    purchaseAdmin = _purchaseAdmin;
  }

  modifier onlyPurchaseAdmin() {
    require(msg.sender == purchaseAdmin);
    _;
  }
  
  function setEnablePurchase(bool enable ) onlyPurchaseAdmin public {
    purchaseEnable = enable;
    emit PurchaseEnable(msg.sender,enable);
  }
  
  modifier checkPurchaseEnable() {
    require(purchaseEnable);
     require(block.timestamp >= startAt && block.timestamp <= stopAt); 
    _;
  }

  function setGrantEnable(bool enable ) onlyOwner public {
    grantEnable = enable;
    emit GrantEnable(msg.sender,enable);
  }

   modifier checkGrantEnable() {
    require(grantEnable);
    require(block.timestamp >= grantAt);
    _;
  }
}


 
contract MyPurchaseContract is Ownable,PurchaseAdmin{

  using SafeMath for uint256;

  using SafeERC20 for ERC20;

  ERC20 public token;

   
  uint256 public totalAllocatedPurchase;

   
  uint256 public remainingPurchaseAmount;

   
  uint256 public buyPrice =  (10 ** uint256(18)) / (500* (10 ** uint256(6)));
  
   
  uint256 public maxPurchase = 100000;

   
  uint256 public maxPurchaseOnce = 50000;

   
  uint256 public minPurchaseOnce = 1000;

   
  uint256 grantCount = 0;

  struct PurchaseData{
     
    uint256 amount;
    
     
    bool grantDone;
  }

   
  mapping (address => PurchaseData) public purchasedDatas;

   
  address[]  public purchasedWallets;

  event Purchase(address indexed from, uint256 value);

  event Grant(address indexed to, uint256 value);

  function MyPurchaseContract(address _token) public {
    token = ERC20(_token);
    totalAllocatedPurchase = token.totalSupply().mul(30).div(100); 
    remainingPurchaseAmount = totalAllocatedPurchase;
    startAt = block.timestamp; 
    stopAt = block.timestamp + 60; 
    grantAt = block.timestamp + 120; 
  }

   
  function buyTokens()  payable checkPurchaseEnable public returns(uint256){
      
    require(msg.value > 0);

    require(remainingPurchaseAmount > 0); 

    require(purchasedDatas[msg.sender].amount < maxPurchase); 
    
    uint256 hopeAmount = msg.value.div(buyPrice); 

     
    if (purchasedDatas[msg.sender].amount == 0 && hopeAmount < minPurchaseOnce) {
      msg.sender.transfer(msg.value); 
      return 0;
    }

    uint256 currentAmount = hopeAmount;

     
    if (hopeAmount >= maxPurchaseOnce) {
       currentAmount = maxPurchaseOnce;
    } 

     
    if (currentAmount >= remainingPurchaseAmount) {
       currentAmount = remainingPurchaseAmount;
    } 

     
    if (purchasedDatas[msg.sender].amount == 0){
       purchasedWallets.push(msg.sender);
    }

    purchasedDatas[msg.sender].amount = purchasedDatas[msg.sender].amount.add(currentAmount);
    
    remainingPurchaseAmount = remainingPurchaseAmount.sub(currentAmount);
    
    emit Purchase(msg.sender,currentAmount);  

    if (hopeAmount > currentAmount){
       
      uint256 out = hopeAmount.sub(currentAmount);
       
      uint256 retwei = out.mul(buyPrice);
       
      msg.sender.transfer(retwei);
    }

    return currentAmount;
  }


   
  function grantTokens(address _purchaser) onlyPurchaseAdmin checkGrantEnable public returns(bool){
      
    require(_purchaser  != address(0));
    
    require(purchasedDatas[_purchaser].grantDone);
    
    uint256 amount = purchasedDatas[_purchaser].amount;
    
    token.safeTransfer(_purchaser,amount);
    
    purchasedDatas[_purchaser].grantDone = true;
    
    grantCount = grantCount.add(1);

    emit Grant(_purchaser,amount);
    
    return true;
  }


  function claimETH() onlyPurchaseAdmin public returns(bool){

    require(block.timestamp > grantAt);

    require(grantCount == purchasedWallets.length);
    
    msg.sender.transfer(address(this).balance);
    
    return true;
  }
}