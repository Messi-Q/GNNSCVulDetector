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

  uint256 constant TOTAL = 387500000000000000000000000;

  constructor() public {
    balances[msg.sender] = TOTAL;
    totalSupply_ = TOTAL;
    emit Transfer(address(0), msg.sender, TOTAL);
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

    if (left > 0) {
      _beneficiary.transfer(left);
    }
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
  function isInWhitelist(address addr) public view returns (bool);
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
  mapping(address => uint256) public investments;

  function claimRefund() public {
    require(isRefundable());
    require(investments[msg.sender] > 0);

    uint investment = investments[msg.sender];
    investments[msg.sender] = 0;

    msg.sender.transfer(investment);
    emit Refund(msg.sender, investment);
  }

  function isRefundable() public view returns (bool);

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens
  ) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount, _tokens);
    investments[_beneficiary] = investments[_beneficiary].add(_weiAmount);
  }
}

contract WgdSale is WhitelistDaonomicCrowdsale, RefundableDaonomicCrowdsale {
  using SafeERC20 for WgdToken;

  event Buyback(address indexed addr, uint256 tokens, uint256 value);

  WgdToken public token;

  uint256 constant public FOR_SALE = 300000000000000000000000000;
  uint256 constant public MINIMAL_WEI = 500000000000000000;
  uint256 constant public END = 1541592000;

   
  uint256 constant STAGE1 = 20000000000000000000000000;
  uint256 constant STAGE2 = 60000000000000000000000000;
  uint256 constant STAGE3 = 140000000000000000000000000;
  uint256 constant STAGE4 = 300000000000000000000000000;

   
  uint256 constant RATE1 = 28000;
  uint256 constant RATE2 = 24000;
  uint256 constant RATE3 = 22000;
  uint256 constant RATE4 = 20000;

   
  uint256 constant BONUS_STAGE1 = 100000000000000000000000;
  uint256 constant BONUS_STAGE2 = 500000000000000000000000;
  uint256 constant BONUS_STAGE3 = 1000000000000000000000000;
  uint256 constant BONUS_STAGE4 = 5000000000000000000000000;

   
  uint256 constant BONUS1 = 1000000000000000000000;
  uint256 constant BONUS2 = 25000000000000000000000;
  uint256 constant BONUS3 = 100000000000000000000000;
  uint256 constant BONUS4 = 750000000000000000000000;

  uint256 public sold;

  constructor(WgdToken _token, Whitelist[] _whitelists)
  WhitelistDaonomicCrowdsale(_whitelists) public {
    token = _token;
    emit RateAdd(address(0));
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  ) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(_weiAmount >= MINIMAL_WEI);
  }

   
  function getRate(address _token) public view returns (uint256) {
    if (_token == address(0)) {
      (,, uint256 rate) = getStage(sold);
      return rate.mul(10 ** 18);
    } else {
      return 0;
    }
  }

   
  function buyback() public {
    (uint8 stage,,) = getStage(sold);
    require(stage > 0, "buyback doesn't work on stage 0");

    uint256 approved = token.allowance(msg.sender, this);
    uint256 inCirculation = token.totalSupply().sub(token.balanceOf(this));
    uint256 value = approved.mul(address(this).balance).div(inCirculation);

    token.burnFrom(msg.sender, approved);
    msg.sender.transfer(value);
    emit Buyback(msg.sender, approved, value);
  }

  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  ) internal {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

  function _getBonus(uint256 _tokens) internal view returns (uint256) {
    return getRealAmountBonus(FOR_SALE, sold, _tokens);
  }

  function getRealAmountBonus(uint256 _forSale, uint256 _sold, uint256 _tokens) public pure returns (uint256) {
    uint256 bonus = getAmountBonus(_tokens);
    uint256 left = _forSale.sub(_sold).sub(_tokens);
    if (left > bonus) {
      return bonus;
    } else {
      return left;
    }
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
    (uint8 stage, uint256 limit, uint256 rate) = getStage(_sold);
    if (stage == 4) {
      return (0, _weiAmount);
    }
    if (stage == 0 && now > END) {
      revert("Sale is refundable, unable to buy");
    }
    tokens = _weiAmount.mul(rate);
    left = 0;
    (uint8 newStage,,) = getStage(_sold.add(tokens));
    if (newStage != stage) {
      tokens = limit.sub(_sold);
       
      uint256 weiSpent = (tokens.add(rate).sub(1)).div(rate);
      left = _weiAmount.sub(weiSpent);
    }
  }

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens
  ) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount, _tokens);

    sold = sold.add(_tokens);
  }

  function isRefundable() public view returns (bool) {
    (uint8 stage,,) = getStage(sold);
    return now > END && stage == 0;
  }

  function getStage(uint256 _sold) public pure returns (uint8 stage, uint256 limit, uint256 rate) {
    if (_sold < STAGE1) {
      return (0, STAGE1, RATE1);
    } else if (_sold < STAGE2) {
      return (1, STAGE2, RATE2);
    } else if (_sold < STAGE3) {
      return (2, STAGE3, RATE3);
    } else if (_sold < STAGE4) {
      return (3, STAGE4, RATE4);
    } else {
      return (4, 0, 0);
    }
  }

  function getAmountBonus(uint256 _tokens) public pure returns (uint256) {
    if (_tokens < BONUS_STAGE1) {
      return 0;
    } else if (_tokens < BONUS_STAGE2) {
      return BONUS1;
    } else if (_tokens < BONUS_STAGE3) {
      return BONUS2;
    } else if (_tokens < BONUS_STAGE4) {
      return BONUS3;
    } else {
      return BONUS4;
    }
  }
}