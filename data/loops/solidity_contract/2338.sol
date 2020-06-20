pragma solidity ^0.4.24;

 

 
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

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
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

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
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

 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

contract WgdToken is StandardBurnableToken {
  string public constant name = "webGold";
  string public constant symbol = "WGD";
  uint8 public constant decimals = 18;

  constructor(uint _total) public {
    balances[msg.sender] = _total;
    totalSupply_ = _total;
    emit Transfer(address(0), msg.sender, _total);
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

 
contract DaonomicCrowdsale {
  using SafeMath for uint256;

   
  uint256 public weiRaised;

   
  event Purchase(address indexed buyer, address token, uint256 value, uint256 sold, uint256 bonus, bytes txId);
   
  event RateAdd(address token);
   
  event RateRemove(address token);

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    (uint256 tokens, uint256 left) = _getTokenAmount(weiAmount);
    uint256 weiEarned = weiAmount.sub(left);
    uint256 bonus = _getBonus(tokens);
    uint256 withBonus = tokens.add(bonus);
    if (left > 0) {
      _beneficiary.send(left);
    }

     
    weiRaised = weiRaised.add(weiEarned);

    _processPurchase(_beneficiary, withBonus);
    emit Purchase(
      _beneficiary,
      address(0),
        weiEarned,
      tokens,
      bonus,
      ""
    );

    _updatePurchasingState(_beneficiary, weiEarned, withBonus);
    _postValidatePurchase(_beneficiary, weiEarned);
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
  ) internal;

   
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
    uint256 _weiAmount,
    uint256 _tokens
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256, uint256);

  function _getBonus(uint256 _tokens) internal view returns (uint256);
}

contract Whitelist {
  function isInWhitelist(address addr) view public returns (bool);
}

contract WhitelistDaonomicCrowdsale is Ownable, DaonomicCrowdsale {
  Whitelist[] public whitelists;

  constructor (Whitelist[] _whitelists) public {
    whitelists = _whitelists;
  }

  function setWhitelists(Whitelist[] _whitelists) onlyOwner public {
    whitelists = _whitelists;
  }

  function getWhitelists() view public returns (Whitelist[]) {
    return whitelists;
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  ) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(canBuy(_beneficiary), "investor is not verified by Whitelists");
  }

  function canBuy(address _beneficiary) constant public returns (bool) {
    for (uint i = 0; i < whitelists.length; i++) {
      if (whitelists[i].isInWhitelist(_beneficiary)) {
        return true;
      }
    }
    return false;
  }
}

contract RefundableDaonomicCrowdsale is DaonomicCrowdsale {
  event Refund(address _address, uint256 investment);
  mapping(address => uint256) investments;

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens
  ) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount, _tokens);
    investments[_beneficiary] = investments[_beneficiary].add(_weiAmount);
  }

  function claimRefund() public {
    require(isRefundable());
    require(investments[msg.sender] > 0);

    uint investment = investments[msg.sender];
    investments[msg.sender] = 0;

    msg.sender.send(investment);
    emit Refund(msg.sender, investment);
  }

  function isRefundable() view public returns (bool);
}

contract WgdSale is WhitelistDaonomicCrowdsale, RefundableDaonomicCrowdsale {
  using SafeERC20 for WgdToken;

  event Buyback(address indexed addr, uint256 tokens, uint256 value);

  WgdToken public token;

  uint256 public forSale;
  uint256 public sold;
  uint256 public minimalWei;
  uint256 public end;
  uint256[] public stages;
  uint256[] public rates;
  uint256[] public bonusStages;
  uint256[] public bonuses;

  constructor(WgdToken _token, uint256 _end, uint256 _minimalWei, uint256[] _stages, uint256[] _rates, uint256[] _bonusStages, uint256[] _bonuses, Whitelist[] _whitelists)
  WhitelistDaonomicCrowdsale(_whitelists) public {
    require(_stages.length == _rates.length);
    require(_bonusStages.length == _bonuses.length);

    token = _token;
    end = _end;
    minimalWei = _minimalWei;
    stages = _stages;
    rates = _rates;
    bonusStages = _bonusStages;
    bonuses = _bonuses;
    forSale = stages[stages.length - 1];

    emit RateAdd(address(0));
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  ) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(_weiAmount >= minimalWei);
  }

   
  function getRate(address _token) view public returns (uint256) {
    if (_token == address(0)) {
      uint8 stage = getStage(sold);
      if (stage == stages.length) {
        return 0;
      }
      return rates[stage] * 10 ** 18;
    } else {
      return 0;
    }
  }

   
  function buyback() public {
    require(getStage(sold) > 0, "buyback doesn't work on stage 0");

    uint256 approved = token.allowance(msg.sender, this);
    uint256 inCirculation = token.totalSupply().sub(token.balanceOf(this));
    uint256 value = approved.mul(this.balance).div(inCirculation);

    token.burnFrom(msg.sender, approved);
    msg.sender.send(value);
    emit Buyback(msg.sender, approved, value);
  }

  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  ) internal {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

  function _getBonus(uint256 _tokens) internal view returns (uint256) {
    return getRealAmountBonus(forSale, sold, _tokens);
  }

  function getRealAmountBonus(uint256 _forSale, uint256 _sold, uint256 _tokens) public view returns (uint256) {
    uint256 bonus = getAmountBonus(_tokens);
    uint256 left = _forSale.sub(_sold).sub(_tokens);
    if (left > bonus) {
      return bonus;
    } else {
      return left;
    }
  }

  function getAmountBonus(uint256 _tokens) public view returns (uint256) {
    uint256 currentBonus = 0;
    for (uint8 i = 0; i < bonuses.length; i++) {
      if (_tokens < bonusStages[i]) {
        return currentBonus;
      }
      currentBonus = bonuses[i];
    }
    return currentBonus;
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256, uint256) {
    return getTokenAmount(sold, _weiAmount);
  }

  function getTokenAmount(uint256 _sold, uint256 _weiAmount) public view returns (uint256 tokens, uint256 left) {
    left = _weiAmount;
    while (left > 0) {
      (uint256 currentTokens, uint256 currentLeft) = getTokensForStage(_sold.add(tokens), left);
      if (left == currentLeft) {
        return (tokens, left);
      }
      left = currentLeft;
      tokens = tokens.add(currentTokens);
    }
  }

   
  function getTokensForStage(uint256 _sold, uint256 _weiAmount) public view returns (uint256 tokens, uint256 left) {
    uint8 stage = getStage(_sold);
    if (stage == stages.length) {
      return (0, _weiAmount);
    }
    if (stage == 0 && now > end) {
      revert("Sale is refundable, unable to buy");
    }
    uint256 rate = rates[stage];

    tokens = _weiAmount.mul(rate);
    left = 0;
    uint8 newStage = getStage(_sold.add(tokens));
    if (newStage != stage) {
      tokens = stages[stage].sub(_sold);
      uint256 weiSpent = (tokens.add(rate).sub(1)).div(rate);
      left = _weiAmount.sub(weiSpent);
    }
  }

  function getStage(uint256 _sold) public view returns (uint8) {
    for (uint8 i = 0; i < stages.length; i++) {
      if (_sold < stages[i]) {
        return i;
      }
    }
    return uint8(stages.length);
  }

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens
  ) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount, _tokens);

    sold = sold.add(_tokens);
  }

  function isRefundable() view public returns (bool) {
    return now > end && getStage(sold) == 0;
  }
}