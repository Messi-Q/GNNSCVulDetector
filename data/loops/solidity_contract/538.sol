pragma solidity ^0.4.24;

 

interface MintableERC20 {

    function mint(address _to, uint256 _value) public;
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


   
  constructor() public {
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

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

 
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    onlyOwner
    public
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    onlyOwner
    public
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

 

 
contract Pausable is Ownable {
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

contract FanCrowdsale is Pausable {
  using SafeMath for uint256;
  using AddressUtils for address;

   
  uint256 constant COIN = 1 ether;

   
  MintableERC20 public mintableToken;

   
  address public wallet;

  Whitelist public whitelist;

   
   
  struct Stage {
    uint tokenAllocated;
    uint rate;
  }

  uint8 public currentStage;
  mapping (uint8 => Stage) public stages;
  uint8 public totalStages;  

   
   
  uint256 public totalTokensSold;
  uint256 public totalWeiRaised;

   
   
  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && !hasClosed());
    _;
  }

   
   
  uint256 public totalTokensForSale;  

   
   
  bool public isFinalized = false;


   
   
   
  constructor(
    address _token,
    uint256 _startTime,
    uint256 _endTime,
    address _wallet,
    uint256 _cap) public
  {
    require(_wallet != address(0), "need a good wallet to store fund");
    require(_token != address(0), "token is not deployed?");
     
    require(_endTime > _startTime, "endTime must be greater than startTime");

     
     
    mintableToken  = MintableERC20(_token);
    wallet = _wallet;

    openingTime = _startTime;
    closingTime = _endTime;

    totalTokensForSale  = _cap;

    _initStages();
    _setCrowdsaleStage(0);

     
    require(stages[totalStages - 1].tokenAllocated == totalTokensForSale);
    
  }
   

   
  function () external payable {
    purchase(msg.sender);
  }

  function purchase(address _buyer) public payable whenNotPaused onlyWhileOpen {
    contribute(_buyer, msg.value);
  }
  
   
   

   
  function contribute(address _buyer, uint256 _weiAmount) internal {
    require(_buyer != address(0));
    require(!_buyer.isContract());
    require(whitelist.whitelist(_buyer));

    if (_weiAmount == 0) {
      return;
    }

     
    require(totalTokensSold < totalTokensForSale);

    uint currentRate = stages[currentStage].rate;
    uint256 tokensToMint = _weiAmount.mul(currentRate);

     
    uint256 saleableTokens;
    uint256 acceptedWei;
    if (currentStage == (totalStages - 1) && totalTokensSold.add(tokensToMint) > totalTokensForSale) {
      saleableTokens = totalTokensForSale - totalTokensSold;
      acceptedWei = saleableTokens.div(currentRate);

      _buyTokensInCurrentStage(_buyer, acceptedWei, saleableTokens);

       
      uint256 weiToRefund = _weiAmount.sub(acceptedWei);
      _buyer.transfer(weiToRefund);
      emit EthRefunded(_buyer, weiToRefund);
    } else if (totalTokensSold.add(tokensToMint) < stages[currentStage].tokenAllocated) {
      _buyTokensInCurrentStage(_buyer, _weiAmount, tokensToMint);
    } else {
       
      saleableTokens = stages[currentStage].tokenAllocated.sub(totalTokensSold);
      acceptedWei = saleableTokens.div(currentRate);

       
      _buyTokensInCurrentStage(_buyer, acceptedWei, saleableTokens);

       
      if (totalTokensSold >= stages[currentStage].tokenAllocated && currentStage + 1 < totalStages) {
        _setCrowdsaleStage(currentStage + 1);
      }

       
      if ( _weiAmount.sub(acceptedWei) > 0)
      {
        contribute(_buyer, _weiAmount.sub(acceptedWei));
      }
    }
  }

  function changeWhitelist(address _newWhitelist) public onlyOwner {
    require(_newWhitelist != address(0));
    emit WhitelistTransferred(whitelist, _newWhitelist);
    whitelist = Whitelist(_newWhitelist);
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime || totalTokensSold >= totalTokensForSale;
  }

   
  function extendClosingTime(uint256 _extendToTime) public onlyOwner onlyWhileOpen {
    closingTime = _extendToTime;
  }

   

   
   

  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasClosed());

    emit Finalized();

    isFinalized = true;
  }


   
   
   

   
   
   
  function _setCrowdsaleStage(uint8 _stageId) internal {
    require(_stageId >= 0 && _stageId < totalStages);

    currentStage = _stageId;

    emit StageUp(_stageId);
  }

  function _initStages() internal {
     
    stages[0] = Stage(25000000 * COIN, 12500);
    stages[1] = Stage(stages[0].tokenAllocated + 46000000 * COIN, 11500);
    stages[2] = Stage(stages[1].tokenAllocated + 88000000 * COIN, 11000);
    stages[3] = Stage(stages[2].tokenAllocated + 105000000 * COIN, 10500);
    stages[4] = Stage(stages[3].tokenAllocated + 160000000 * COIN, 10000);

     
     
     
     
     
     
     

    totalStages = 5;
  }

   
  function _buyTokensInCurrentStage(address _buyer, uint _weiAmount, uint _tokenAmount) internal {
    totalWeiRaised = totalWeiRaised.add(_weiAmount);
    totalTokensSold = totalTokensSold.add(_tokenAmount);

     
    mintableToken.mint(_buyer, _tokenAmount);
    wallet.transfer(_weiAmount);

    emit TokenPurchase(_buyer, _weiAmount, _tokenAmount);
  }


 
 
 

     
     
     
     
  function claimTokens(address _token) onlyOwner public {
      if (_token == 0x0) {
          owner.transfer(address(this).balance);
          return;
      }

      ERC20 token = ERC20(_token);
      uint balance = token.balanceOf(this);
      token.transfer(owner, balance);

      emit ClaimedTokens(_token, owner, balance);
  }

 
 
 
  event StageUp(uint8 stageId);

  event EthRefunded(address indexed buyer, uint256 value);

  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

  event WhitelistTransferred(address indexed previousWhitelist, address indexed newWhitelist);

  event ClaimedTokens(address indexed _token, address indexed _to, uint _amount);

  event Finalized();

   
  event DLog(uint num, string msg);
}