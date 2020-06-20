pragma solidity ^0.4.21;

 

 
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

 

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

 
contract KYCWhitelist is Claimable {

   mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  function validateWhitelisted(address _beneficiary) internal view {
    require(whitelist[_beneficiary]);
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }
  
   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

  
}

 

 
contract Pausable is Claimable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

 
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

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract PrivatePreSale is Claimable, KYCWhitelist, Pausable {
  using SafeMath for uint256;

  
   
  address public constant FUNDS_WALLET = 0xDc17D222Bc3f28ecE7FCef42EDe0037C739cf28f;
   
  address public constant TOKEN_WALLET = 0x1EF91464240BB6E0FdE7a73E0a6f3843D3E07601;
   
  address public constant TOKEN_ADDRESS = 0x14121EEe7995FFDF47ED23cfFD0B5da49cbD6EB3;
   
  ERC20 public constant TOKEN = ERC20(TOKEN_ADDRESS);
   
  uint256 public constant TOKENS_PER_ETH = 4970;
   
  uint256 public constant MAX_TOKENS = 20000000 * (10**18);
   
  uint256 public constant MIN_TOKEN_INVEST = 4970 * (10**18);
   
  uint256 public START_DATE = 1529323200;

   
   
   

   
  uint256 public weiRaised;
   
  uint256 public tokensIssued;
   
  bool public closed;

   
   
   

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


   
   
   


  function PrivatePreSale() public {
    require(TOKENS_PER_ETH > 0);
    require(FUNDS_WALLET != address(0));
    require(TOKEN_WALLET != address(0));
    require(TOKEN_ADDRESS != address(0));
    require(MAX_TOKENS > 0);
    require(MIN_TOKEN_INVEST >= 0);
  }

   
   
   

   
  function capReached() public view returns (bool) {
    return tokensIssued >= MAX_TOKENS;
  }

   
  function closeSale() public onlyOwner {
    require(!closed);
    closed = true;
  }

   
  function getTokenAmount(uint256 _weiAmount) public pure returns (uint256) {
     
    return _weiAmount.mul(TOKENS_PER_ETH);
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
   
   

    
  function buyTokens(address _beneficiary) internal whenNotPaused {
    
    uint256 weiAmount = msg.value;

     
    uint256 tokenAmount = getTokenAmount(weiAmount);

     
    preValidateChecks(_beneficiary, weiAmount, tokenAmount);
    
     
    tokensIssued = tokensIssued.add(tokenAmount);
    weiRaised = weiRaised.add(weiAmount);

     
    TOKEN.transferFrom(TOKEN_WALLET, _beneficiary, tokenAmount);

     
    FUNDS_WALLET.transfer(msg.value);

     
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokenAmount);
  }

   
  function preValidateChecks(address _beneficiary, uint256 _weiAmount, uint256 _tokenAmount) internal view {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(now >= START_DATE);
    require(!closed);

     
    validateWhitelisted(_beneficiary);

     
    require(_tokenAmount >= MIN_TOKEN_INVEST);

     
    require(tokensIssued.add(_tokenAmount) <= MAX_TOKENS);
  }
}