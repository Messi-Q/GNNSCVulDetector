pragma solidity ^0.4.24;

 

 
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

 

 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
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

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

 
contract Whitelist is Ownable, RBAC {
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyWhitelisted() {
    checkRole(msg.sender, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address addr)
    onlyOwner
    public
  {
    addRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressAdded(addr);
  }

   
  function whitelist(address addr)
    public
    view
    returns (bool)
  {
    return hasRole(addr, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      addAddressToWhitelist(addrs[i]);
    }
  }

   
  function removeAddressFromWhitelist(address addr)
    onlyOwner
    public
  {
    removeRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressRemoved(addr);
  }

   
  function removeAddressesFromWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      removeAddressFromWhitelist(addrs[i]);
    }
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

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

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

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract PixieToken is StandardToken, Whitelist, HasNoEther {

  string public constant name = "Pixie Token";

  string public constant symbol = "PXE";

  uint8 public constant decimals = 18;

  uint256 public constant initialSupply = 100000000000 * (10 ** uint256(decimals));  

  bool public transfersEnabled = false;

  address public bridge;

  event BridgeChange(address to);

  event TransfersEnabledChange(bool to);

   
  constructor() public Whitelist() {
    totalSupply_ = initialSupply;
    balances[msg.sender] = initialSupply;
    emit Transfer(0x0, msg.sender, initialSupply);

     
    bridge = msg.sender;

     
    addAddressToWhitelist(msg.sender);
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(
      transfersEnabled || whitelist(msg.sender) || _to == bridge,
      "Unable to transfers locked or address not whitelisted or not sending to the bridge"
    );

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(
      transfersEnabled || whitelist(msg.sender) || _to == bridge,
      "Unable to transfers locked or address not whitelisted or not sending to the bridge"
    );

    return super.transferFrom(_from, _to, _value);
  }

   
  function changeBridge(address _new) external onlyOwner {
    require(_new != address(0), "Invalid address");
    bridge = _new;
    emit BridgeChange(bridge);
  }

   
  function setTransfersEnabled(bool _transfersEnabled) external onlyOwner {
    transfersEnabled = _transfersEnabled;
    emit TransfersEnabledChange(transfersEnabled);
  }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

   
  constructor(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

   
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

   
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
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

 

contract PixieCrowdsale is Crowdsale, Pausable {

  event Finalized();

  event MinimumContributionUpdated(uint256 _minimumContribution);

  event OwnerTransfer(
    address indexed owner,
    address indexed caller,
    address indexed beneficiary,
    uint256 amount
  );

  mapping(address => bool) public whitelist;

  mapping(address => bool) public managementWhitelist;

  mapping(address => uint256) public contributions;

  bool public isFinalized = false;

   
  uint256 public openingTime = 1530608400;

   
  uint256 public privateSaleCloseTime = 1533113999;

   
  uint256 public preSaleCloseTime = 1538384399;

   
  uint256 public closingTime = 1540979999;

   
  uint256 public rate = 396039;

   
  uint256 public privateSaleRate = 485148;

   
  uint256 public preSaleRate = 445544;

  uint256 public softCap = 2650 ether;

  uint256 public hardCap = 101000 ether;

  uint256 public minimumContribution = 1 ether;

   
  RefundVault public vault;

   
  modifier onlyManagement() {
    require(msg.sender == owner || managementWhitelist[msg.sender], "Must be owner or in management whitelist");
    _;
  }

   
  constructor(address _wallet, PixieToken _token) public Crowdsale(rate, _wallet, _token) {
    vault = new RefundVault(wallet);
  }

   
  function softCapReached() public view returns (bool) {
    return weiRaised >= softCap;
  }

   
  function finalization() internal {
    if (softCapReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }
  }

   
  function _forwardFunds() internal {
     
    if (isFinalized) {
      wallet.transfer(msg.value);
    }
     
    else {
      vault.deposit.value(msg.value)(msg.sender);
    }
  }

   
  function finalize() onlyOwner public {
    require(!isFinalized, "Crowdsale already finalised");

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function addToWhitelist(address _beneficiary) external onlyManagement {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyManagement {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyManagement {
    whitelist[_beneficiary] = false;
  }

   
  function addToManagementWhitelist(address _manager) external onlyManagement {
    managementWhitelist[_manager] = true;
  }

   
  function removeFromManagementWhitelist(address _manager) external onlyManagement {
    managementWhitelist[_manager] = false;
  }

   
  function updateOpeningTime(uint256 _openingTime) external onlyManagement {
    require(_openingTime > 0, "A opening time must be specified");
    openingTime = _openingTime;
  }

   
  function updatePrivateSaleCloseTime(uint256 _privateSaleCloseTime) external onlyManagement {
    require(_privateSaleCloseTime > openingTime, "A private sale time must after the opening time");
    privateSaleCloseTime = _privateSaleCloseTime;
  }

   
  function updatePreSaleCloseTime(uint256 _preSaleCloseTime) external onlyManagement {
    require(_preSaleCloseTime > privateSaleCloseTime, "A pre sale time must be after the private sale close time");
    preSaleCloseTime = _preSaleCloseTime;
  }

   
  function updateClosingTime(uint256 _closingTime) external onlyManagement {
    require(_closingTime > preSaleCloseTime, "A closing time must be after the pre-sale close time");
    closingTime = _closingTime;
  }

   
  function updateMinimumContribution(uint256 _minimumContribution) external onlyManagement {
    require(_minimumContribution > 0, "Minimum contribution must be great than zero");
    minimumContribution = _minimumContribution;
    emit MinimumContributionUpdated(_minimumContribution);
  }

   
  function getDateRanges() external view returns (
    uint256 _openingTime,
    uint256 _privateSaleCloseTime,
    uint256 _preSaleCloseTime,
    uint256 _closingTime
  ) {
    return (
    openingTime,
    privateSaleCloseTime,
    preSaleCloseTime,
    closingTime
    );
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
  }

   
  function hardCapReached() public view returns (bool) {
    return weiRaised >= hardCap;
  }

   
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    if (now < privateSaleCloseTime) {
      return _weiAmount.mul(privateSaleRate);
    }

    if (now < preSaleCloseTime) {
      return _weiAmount.mul(preSaleRate);
    }

    return _weiAmount.mul(rate);
  }

   
  function isCrowdsaleOpen() public view returns (bool) {
    return now >= openingTime && now <= closingTime;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);

    require(isCrowdsaleOpen(), "Crowdsale not open");

    require(weiRaised.add(_weiAmount) <= hardCap, "Exceeds maximum cap");

    require(_weiAmount >= minimumContribution, "Beneficiary minimum amount not reached");

    require(whitelist[_beneficiary], "Beneficiary not whitelisted");

    require(whitelist[msg.sender], "Sender not whitelisted");

    require(!paused, "Contract paused");
  }

   
  function transfer(address _beneficiary, uint256 _tokenAmount) external onlyOwner {
    _deliverTokens(_beneficiary, _tokenAmount);
    emit OwnerTransfer(msg.sender, address(this), _beneficiary, _tokenAmount);
  }
}