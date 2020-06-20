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

 
contract TokenlessCrowdsale {
  using SafeMath for uint256;

   
  address public wallet;

   
  uint256 public weiRaised;

   
  event SaleContribution(address indexed purchaser, address indexed beneficiary, uint256 value);

   
  constructor (address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchaseInWei(_beneficiary, weiAmount);
    emit SaleContribution(
      msg.sender,
      _beneficiary,
      weiAmount
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _processPurchaseInWei(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
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


 
contract WhitelistedAICrowdsale is TokenlessCrowdsale, Ownable {
  using SafeMath for uint256;

  mapping(address => bool) public accredited;

   
  mapping(address => uint256) public contributions;
  mapping(address => uint256) public caps;

  
  function isWhitelisted(address _beneficiary) public view returns (bool) {
    if (caps[_beneficiary] != 0) {
      return true;
    }
    return false;
  }

   
  function addToWhitelist(address _beneficiary, uint256 _cap, bool _accredited) external onlyOwner {
    caps[_beneficiary] = _cap;
    accredited[_beneficiary] = _accredited;
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    caps[_beneficiary] = 0;
    accredited[_beneficiary] = false;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(contributions[_beneficiary].add(_weiAmount) <= caps[_beneficiary]);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
  }

}


 
contract FiatCappedCrowdsale is TokenlessCrowdsale, Ownable {
  using SafeMath for uint256;

   
   
   

  uint256 public millCap;  
  uint256 public millRaised;  

   
  uint256 public minMillPurchase;

   
  uint256 public millWeiRate;

   
  uint256 public millLeconteRate;

   
   
  uint256 constant minMillWeiRate = (10 ** 18) / (5000 * (10 ** 3));  
  uint256 constant maxMillWeiRate = (10 ** 18) / (100 * (10 ** 3));  

   
  uint256 constant minMillLeconteRate = (10 ** 18) / 1000;  
  uint256 constant maxMillLeconteRate = (10 ** 18) / 10;  

   
  modifier isSaneETHRate(uint256 _millWeiRate) {
    require(_millWeiRate >= minMillWeiRate);
    require(_millWeiRate <= maxMillWeiRate);
    _;
  }

   
  modifier isSaneSPXRate(uint256 _millLeconteRate) {
    require(_millLeconteRate >= minMillLeconteRate);
    require(_millLeconteRate <= maxMillLeconteRate);
    _;
  }

   
  constructor (
    uint256 _millCap,
    uint256 _minMillPurchase,
    uint256 _millLeconteRate,
    uint256 _millWeiRate
  ) public isSaneSPXRate(_millLeconteRate) isSaneETHRate(_millWeiRate) {
    require(_millCap > 0);
    require(_minMillPurchase > 0);

    millCap = _millCap;
    minMillPurchase = _minMillPurchase;
    millLeconteRate = _millLeconteRate;
    millWeiRate = _millWeiRate;
  }

   
  function capReached() public view returns (bool) {
    return millRaised >= millCap;
  }

   
  function setWeiRate(uint256 _millWeiRate) external onlyOwner isSaneETHRate(_millWeiRate) {
    millWeiRate = _millWeiRate;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);

     
    uint256 _millAmount = _toMill(_weiAmount);
    require(_millAmount >= minMillPurchase);

     
    uint256 _millRaised = millRaised.add(_millAmount);
    require(_millRaised <= millCap);
    millRaised = _millRaised;
  }

   
  function _toMill(uint256 _weiAmount) internal returns (uint256) {
    return _weiAmount.div(millWeiRate);
  }

   
  function _toLeconte(uint256 _weiAmount) internal returns (uint256) {
    return _toMill(_weiAmount).mul(millLeconteRate);
  }
}

 
contract PausableCrowdsale is TokenlessCrowdsale, Ownable {
   
  bool public open = true;

  modifier saleIsOpen() {
    require(open);
    _;
  }

  function unpauseSale() external onlyOwner {
    require(!open);
    open = true;
  }

  function pauseSale() external onlyOwner saleIsOpen {
    open = false;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal saleIsOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
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

 
contract BasicERC223Receiver {
  function tokenFallback(address _from, uint256 _value, bytes _data) public pure;
}


 
contract RestrictedToken is BasicToken, Ownable {
  string public name;
  string public symbol;
  uint8 public decimals;

   
  address public issuer;

   
   
  uint256 public vestingPeriod;

   
  mapping(address => bool) public authorizedRecipients;

   
  mapping(address => bool) public erc223Recipients;

   
  mapping(address => uint256) public lastIssuedTime;

  event Issue(address indexed to, uint256 value);

   
  modifier onlyIssuer() {
    require(msg.sender == issuer);
    _;
  }

   
  modifier isAuthorizedRecipient(address _recipient) {
    require(authorizedRecipients[_recipient]);
    _;
  }

  constructor (
    uint256 _supply,
    string _name,
    string _symbol,
    uint8 _decimals,
    uint256 _vestingPeriod,
    address _owner,  
    address _issuer  
  ) public {
    require(_supply != 0);
    require(_owner != address(0));
    require(_issuer != address(0));

    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    vestingPeriod = _vestingPeriod;
    owner = _owner;
    issuer = _issuer;
    totalSupply_ = _supply;
    balances[_issuer] = _supply;
    emit Transfer(address(0), _issuer, _supply);
  }

   
  function authorize(address _recipient, bool _isERC223) public onlyOwner {
    require(_recipient != address(0));
    authorizedRecipients[_recipient] = true;
    erc223Recipients[_recipient] = _isERC223;
  }

  function deauthorize(address _recipient) public onlyOwner isAuthorizedRecipient(_recipient) {
    authorizedRecipients[_recipient] = false;
    erc223Recipients[_recipient] = false;
  }

   
  function transfer(address _to, uint256 _value) public isAuthorizedRecipient(_to) returns (bool) {
    if (erc223Recipients[_to]) {
      BasicERC223Receiver receiver = BasicERC223Receiver(_to);
      bytes memory empty;
      receiver.tokenFallback(msg.sender, _value, empty);
    }
    return super.transfer(_to, _value);
  }

   
  function issue(address _to, uint256 _value) public onlyIssuer returns (bool) {
    lastIssuedTime[_to] = block.timestamp;

    emit Issue(_to, _value);
    return super.transfer(_to, _value);
  }
}

 
contract PrivatePreSale is TokenlessCrowdsale, WhitelistedAICrowdsale, FiatCappedCrowdsale, PausableCrowdsale {
  using SafeMath for uint256;

   
  RestrictedToken public tokenR0;  
  RestrictedToken public tokenR6;  

  uint8 constant bonusPct = 15;

  constructor (address _wallet, uint256 _millWeiRate) TokenlessCrowdsale(_wallet)
    FiatCappedCrowdsale(
      5000000 * (10 ** 3),  
      500 * (10 ** 3),  
      (10 ** 18) / 50,  
      _millWeiRate
    )
  public {
    tokenR0 = new RestrictedToken(
      2 * 100000000 * (10 ** 18),  
      'Sparrow Token (Restricted)',  
      'SPX-R0',  
      18,  
      0,  
      msg.sender,  
      this  
    );

     
    tokenR6 = new RestrictedToken(
      2 * 115000000 * (10 ** 18),  
      'Sparrow Token (Restricted with 6-month vesting)',  
      'SPX-R6',  
      18,  
      6 * 30 * 86400,  
      msg.sender,  
      this  
    );
  }

   
   
  function _processPurchaseInWei(address _beneficiary, uint256 _weiAmount) internal {
    super._processPurchaseInWei(_beneficiary, _weiAmount);

    uint256 tokens = _toLeconte(_weiAmount);
    uint256 bonus = tokens.mul(bonusPct).div(100);

     
    if (accredited[_beneficiary]) {
      tokenR0.issue(_beneficiary, tokens);
      tokenR6.issue(_beneficiary, bonus);
    } else {
      tokenR6.issue(_beneficiary, tokens.add(bonus));
    }
  }
}