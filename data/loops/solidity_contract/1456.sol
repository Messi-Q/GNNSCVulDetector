pragma solidity ^0.4.24;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 
contract SplitPayment {
  using SafeMath for uint256;

  uint256 public totalShares = 0;
  uint256 public totalReleased = 0;

  mapping(address => uint256) public shares;
  mapping(address => uint256) public released;
  address[] public payees;

   
  constructor(address[] _payees, uint256[] _shares) public payable {
    require(_payees.length == _shares.length);

    for (uint256 i = 0; i < _payees.length; i++) {
      addPayee(_payees[i], _shares[i]);
    }
  }

   
  function () public payable {}

   
  function claim() public {
    address payee = msg.sender;

    require(shares[payee] > 0);

    uint256 totalReceived = address(this).balance.add(totalReleased);
    uint256 payment = totalReceived.mul(
      shares[payee]).div(
        totalShares).sub(
          released[payee]
    );

    require(payment != 0);
    require(address(this).balance >= payment);

    released[payee] = released[payee].add(payment);
    totalReleased = totalReleased.add(payment);

    payee.transfer(payment);
  }

   
  function addPayee(address _payee, uint256 _shares) internal {
    require(_payee != address(0));
    require(_shares > 0);
    require(shares[_payee] == 0);

    payees.push(_payee);
    shares[_payee] = _shares;
    totalShares = totalShares.add(_shares);
  }
}

 

contract PFMToken is StandardToken, DetailedERC20, SplitPayment {
  using SafeMath for uint256;

   
  event Purchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  string constant TOKEN_NAME = "Prayer For Money";
  string constant TOKEN_SYMBOL = "PFM";
  uint8 constant TOKEN_DECIMALS = 18;
  uint256 constant EXCHANGE_RATE = 10000;
  uint256 constant HARD_CAP = 20000000 * (uint256(10)**TOKEN_DECIMALS);
  uint256 constant MIN_PURCHASE = 1000 * (uint256(10)**(TOKEN_DECIMALS - 2));

  uint256 public exchangeRate;           
  uint256 public hardCap;                
  uint256 public minPurchase;            
  uint256 public crowdsaleOpeningTime;   
  uint256 public crowdsaleClosingTime;   
  uint256 public fundRaised;             

  constructor(
    address[] _founders,
    uint256[] _founderShares,
    uint256 _crowdsaleOpeningTime, 
    uint256 _crowdsaleClosingTime
  )
    DetailedERC20(TOKEN_NAME, TOKEN_SYMBOL, TOKEN_DECIMALS)
    SplitPayment(_founders, _founderShares)
    public 
  {
    require(_crowdsaleOpeningTime <= _crowdsaleClosingTime);

    exchangeRate = EXCHANGE_RATE;
    hardCap = HARD_CAP;
    minPurchase = MIN_PURCHASE;
    crowdsaleOpeningTime = _crowdsaleOpeningTime;
    crowdsaleClosingTime = _crowdsaleClosingTime;

    for (uint i = 0; i < _founders.length; i++) {
      _mint(_founders[i], _founderShares[i]);
    }
  }

   
   
   

  function () public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    uint256 tokenAmount = _getTokenAmount(weiAmount);

    _validatePurchase(_beneficiary, weiAmount, tokenAmount);
    _processPurchase(_beneficiary, weiAmount, tokenAmount);

    emit Purchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokenAmount
    );
  }

   
   
   

   
  function _validatePurchase(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokenAmount
  )
    internal view
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(_tokenAmount >= minPurchase);
    require(totalSupply_ + _tokenAmount <= hardCap);
    require(block.timestamp >= crowdsaleOpeningTime);
    require(block.timestamp <= crowdsaleClosingTime);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokenAmount
  )
    internal
  {
    _mint(_beneficiary, _tokenAmount);
    fundRaised = fundRaised.add(_weiAmount);
  }

   
  function _mint(
    address _beneficiary, 
    uint256 _tokenAmount
  )
    internal
  {
    totalSupply_ = totalSupply_.add(_tokenAmount);
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);

    emit Transfer(address(0), _beneficiary, _tokenAmount);
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(exchangeRate);
  }
}