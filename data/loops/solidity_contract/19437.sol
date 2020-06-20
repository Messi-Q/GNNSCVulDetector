pragma solidity ^0.4.21;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


 
contract Crowdsale {
  using SafeMath for uint256;

   
  StandardToken public token;

   
  uint256 public rate;

   
  uint public presaleRate;

   
  uint256 public weiRaised;

   
  address public owner;

   
  mapping (address => uint) public regularTokensSold;

   
  mapping (address => uint) public presaleTokensSold;

   
  address[] public investors;

   
  bool public inSale = true;

   
  bool public inPresale = true;

   
  mapping (address => uint) public presaleAllocations;

   
  uint256 public totalPresaleTokensSold = 0;

   
  uint256 public totalRegularTokensSold = 0;

   
  uint256 constant public PRESALETOKENMAXSALES = 15000000000000000000000000;

   
  uint256 public regularTokenMaxSales = 16000000000000000000000000;

   
  uint256 constant public MINIMUMINVESTMENTPRESALE = 5000000000000000000;

   
  uint256 constant public MINIMUMINVESTMENTSALE = 1000000000000000000;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier onlyDuringPresale() {
    require(inPresale);
    _;
  }

  modifier onlyWhenSalesEnabled() {
    require(inSale);
    _;
  }

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 rate);

   
  function Crowdsale(
    address _owner, 
    uint256 _rate, 
    uint256 _presaleRate, 
    uint256 _ownerInitialTokens
  ) public payable {
    require(_rate > 0);
    require(_presaleRate > 0);
    require(_owner != address(0));

    rate = _rate;
    presaleRate = _presaleRate;
    owner = _owner;

    investors.push(owner);
    regularTokensSold[owner] = _ownerInitialTokens;
  }

   
   
   

  function () external payable {
    buyTokens();
  }

   
  function setToken(StandardToken _token) public onlyOwner {
    token = _token;
  }

   
  function buyPresaleTokens() onlyDuringPresale onlyWhenSalesEnabled public payable {
    address _beneficiary = msg.sender;
    uint256 weiAmount = msg.value;

    _preValidatePurchase(_beneficiary);
    require(weiAmount >= MINIMUMINVESTMENTPRESALE);

    uint256 presaleAllocation = presaleAllocations[_beneficiary];

    uint256 presaleTokens = _min256(weiAmount.mul(presaleRate), presaleAllocation);

    _recordPresalePurchase(_beneficiary, presaleTokens);

     
    presaleAllocations[_beneficiary] = presaleAllocations[_beneficiary].sub(presaleTokens);

    uint256 weiCharged = presaleTokens.div(presaleRate);

     
    uint256 change = weiAmount.sub(weiCharged);
    _beneficiary.transfer(change);

     
    weiRaised = weiRaised.add(weiAmount.sub(change));

    emit TokenPurchase(msg.sender, _beneficiary, weiCharged, presaleTokens, presaleRate);

     
    _forwardFunds(weiCharged);
  }

   
  function buyTokens() onlyWhenSalesEnabled public payable {
    address _beneficiary = msg.sender;
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary);

    require(weiAmount >= MINIMUMINVESTMENTSALE);

    uint256 tokens = weiAmount.mul(rate);

     
    totalRegularTokensSold = totalRegularTokensSold.add(tokens);
    require(totalRegularTokensSold <= regularTokenMaxSales);

     
    weiRaised = weiRaised.add(weiAmount);

    investors.push(_beneficiary);

     
    regularTokensSold[_beneficiary] = regularTokensSold[_beneficiary].add(tokens);

    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens, rate);

     
    _forwardFunds(weiAmount);
  }

   
  function recordPresalePurchase(address _beneficiary, uint256 _presaleTokens) public onlyOwner {
    weiRaised = weiRaised.add(_presaleTokens.div(presaleRate));
    return _recordPresalePurchase(_beneficiary, _presaleTokens);
  }

  function enableSale() onlyOwner public {
    inSale = true;
  }

  function disableSale() onlyOwner public {
    inSale = false;
  }

  function endPresale() onlyOwner public {
    inPresale = false;

     
    uint256 remainingPresaleTokens = PRESALETOKENMAXSALES.sub(totalPresaleTokensSold);
    regularTokenMaxSales = regularTokenMaxSales.add(remainingPresaleTokens);
  }

   
  function transferTokens() public onlyOwner {
    for (uint256 i = 0; i < investors.length; i = i.add(1)) {
      address investor = investors[i];

      uint256 tokens = regularTokensSold[investor];
      uint256 presaleTokens = presaleTokensSold[investor];
      
      regularTokensSold[investor] = 0;
      presaleTokensSold[investor] = 0;

      if (tokens > 0) {
        _deliverTokens(token, investor, tokens);
      }

      if (presaleTokens > 0) {
        _deliverTokens(token, investor, presaleTokens);
      }
    }
  }

   
  function transferTokensWithOffsetAndLimit(uint256 offset, uint256 limit) public onlyOwner {
    for (uint256 i = offset; i <  _min256(investors.length,offset+limit); i = i.add(1)) {
      address investor = investors[i];

      uint256 tokens = regularTokensSold[investor];
      uint256 presaleTokens = presaleTokensSold[investor];

      regularTokensSold[investor] = 0;
      presaleTokensSold[investor] = 0;

      if (tokens > 0) {
        _deliverTokens(token, investor, tokens);
      }

      if (presaleTokens > 0) {
        _deliverTokens(token, investor, presaleTokens);
      }
    }
  }


   
  function refund(address investor) onlyOwner public {
    require(investor != owner);

    uint256 regularTokens = regularTokensSold[investor];
    totalRegularTokensSold = totalRegularTokensSold.sub(regularTokens);
    weiRaised = weiRaised.sub(regularTokens.div(rate));

    uint256 presaleTokens = presaleTokensSold[investor];
    totalPresaleTokensSold = totalPresaleTokensSold.sub(presaleTokens);
    weiRaised = weiRaised.sub(presaleTokens.div(presaleRate));

    regularTokensSold[investor] = 0;
    presaleTokensSold[investor] = 0;

     
  }

   
  function getInvestorAtIndex(uint256 _index) public view returns(address) {
    return investors[_index];
  }

   
  function getInvestorsLength() public view returns(uint256) {
    return investors.length;
  }

   
  function getNumRegularTokensBought(address _address) public view returns(uint256) {
    return regularTokensSold[_address];
  }

   
  function getNumPresaleTokensBought(address _address) public view returns(uint256) {
    return presaleTokensSold[_address];
  }

   
  function getPresaleAllocation(address investor) view public returns(uint256) {
    return presaleAllocations[investor];
  }

   
  function setPresaleAllocation(address investor, uint allocation) onlyOwner public {
    presaleAllocations[investor] = allocation;
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary) internal pure {
    require(_beneficiary != address(0));
  }

   
  function _deliverTokens(StandardToken _token, address _beneficiary, uint256 _tokenAmount) internal {
    _token.mint(_beneficiary, _tokenAmount);
  }

   
  function _forwardFunds(uint256 amount) internal {
    owner.transfer(amount);
  }

  function _min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

   
  function _recordPresalePurchase(address _beneficiary, uint256 _presaleTokens) internal {
     
    totalPresaleTokensSold = totalPresaleTokensSold.add(_presaleTokens);
    require(totalPresaleTokensSold <= PRESALETOKENMAXSALES);

    investors.push(_beneficiary);

     
    presaleTokensSold[_beneficiary] = presaleTokensSold[_beneficiary].add(_presaleTokens);
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_ = 45467000000000000000000000;

   
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

   
  string constant public name = "Quant";
   
  string constant public symbol = "QNT";
   
  uint8 constant public decimals = 18;
   
  uint256 constant public DECIMAL_ZEROS = 1000000000000000000;

  mapping (address => mapping (address => uint256)) internal allowed;

  address public crowdsale;

  modifier onlyCrowdsale() {
    require(msg.sender == crowdsale);
    _;
  }

  function StandardToken(address _crowdsale) public {
    require(_crowdsale != address(0));
    crowdsale = _crowdsale;
  }

  function mint(address _address, uint256 _value) public onlyCrowdsale {
    balances[_address] = balances[_address].add(_value);
    emit Transfer(0, _address, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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