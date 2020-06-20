pragma solidity ^0.4.18;

 

 
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
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 

contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

contract MMMbCoin is CappedToken, BurnableToken {

  string public constant name = "MMMbCoin Utils";
  string public constant symbol = "MMB";
  uint256 public constant decimals = 18;

  function MMMbCoin(uint256 _cap) public CappedToken(_cap) {
  }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}

 

 


 



contract MMMbCoinCrowdsale is Crowdsale, Ownable {
  enum ManualState {
    WORKING, READY, NONE
  }

  uint256 public decimals;
  uint256 public emission;

   
  mapping(uint8 => uint256) discountTokens;
  mapping(address => uint256) pendingOrders;

  uint256 public totalSupply;
  address public vault;
  address public preSaleVault;
  ManualState public manualState = ManualState.NONE;
  bool public disabled = true;

  function MMMbCoinCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _tokenContractAddress, address _vault, address _preSaleVault) public
    Crowdsale(_startTime, _endTime, _rate, _wallet)
  {
    require(_vault != address(0));

    vault = _vault;
    preSaleVault = _preSaleVault;

    token = MMMbCoin(_tokenContractAddress);
    decimals = MMMbCoin(token).decimals();

    totalSupply = token.balanceOf(vault);

    defineDiscountBorderLines();
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    if (disabled) {
      pendingOrders[msg.sender] = pendingOrders[msg.sender].add(msg.value);
      forwardFunds();
      return;
    }

    uint256 weiAmount = msg.value;
    uint256 sold = totalSold();

    uint256 tokens;

    if (sold < _discount(25)) {
      tokens = _calculateTokens(weiAmount, 25, sold);
    }
    else if (sold >= _discount(25) && sold < _discount(20)) {
      tokens = _calculateTokens(weiAmount, 20, sold);
    }
    else if (sold >= _discount(20) && sold < _discount(15)) {
      tokens = _calculateTokens(weiAmount, 15, sold);
    }
    else if (sold >= _discount(15) && sold < _discount(10)) {
      tokens = _calculateTokens(weiAmount, 10, sold);
    }
    else if (sold >= _discount(10) && sold < _discount(5)) {
      tokens = _calculateTokens(weiAmount, 5, sold);
    }
    else {
      tokens = weiAmount.mul(rate);
    }

     
    require(sold.add(tokens) <= totalSupply);

    weiRaised = weiRaised.add(weiAmount);
    token.transferFrom(vault, beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function totalSold() public view returns(uint256) {
    return totalSupply.sub(token.balanceOf(vault));
  }

   
  function transferTokens(address _to, uint256 _amount) public onlyOwner {
    require(!hasEnded());
    require(_to != address(0));
    require(_amount != 0);
    require(token.balanceOf(vault) >= _amount);

    token.transferFrom(vault, _to, _amount);
  }

  function transferPreSaleTokens(address _to, uint256 tokens) public onlyOwner {
    require(_to != address(0));
    require(tokens != 0);
    require(tokens < token.balanceOf(preSaleVault));

    token.transferFrom(preSaleVault, _to, tokens);
  }


  function transferOwnership(address _newOwner) public onlyOwner {
    token.transferOwnership(_newOwner);
  }

   
  function defineDiscountBorderLines() internal onlyOwner {
    discountTokens[25] = 57 * (100000 ether);
    discountTokens[20] = 171 * (100000 ether);
    discountTokens[15] = 342 * (100000 ether);
    discountTokens[10] = 570 * (100000 ether);
    discountTokens[5] = 855 * (100000 ether);
  }

   
  function validPurchase() internal view returns(bool) {
    uint256 weiValue = msg.value;

    bool defaultCase = super.validPurchase();
    bool capCase = token.balanceOf(vault) > 0;
    bool extraCase = weiValue != 0 && capCase && manualState == ManualState.WORKING;
    return defaultCase && capCase || extraCase;
  }

   
  function hasEnded() public view returns (bool) {
    if (manualState == ManualState.WORKING) {
      return false;
    }
    else if (manualState == ManualState.READY) {
      return true;
    }
    bool icoLimitReached = token.balanceOf(vault) == 0;
    return super.hasEnded() || icoLimitReached;
  }

   
  function finishCrowdsale() public onlyOwner {
    manualState = ManualState.READY;
  }


   
  function startCrowdsale() public onlyOwner {
    manualState = ManualState.WORKING;
  }

   
  function dropManualState() public onlyOwner {
    manualState = ManualState.NONE;
  }

   
  function disableAutoSeller() public onlyOwner {
    disabled = true;
  }

   
  function enableAutoSeller() public onlyOwner {
    disabled = false;
  }

   
  function hasAccountPendingOrders(address _account) public view returns(bool) {
    return pendingOrders[_account] > 0;
  }

   
  function getAccountPendingValue(address _account) public view returns(uint256) {
    return pendingOrders[_account];
  }

  function _discount(uint8 _percent) internal view returns (uint256) {
    return discountTokens[_percent];
  }

  function _calculateTokens(uint256 _value, uint8 _off, uint256 _sold) internal view returns (uint256) {
    uint256 withoutDiscounts = _value.mul(rate);
    uint256 byDiscount = withoutDiscounts.mul(100).div(100 - _off);
    if (_sold.add(byDiscount) > _discount(_off)) {
      uint256 couldBeSold = _discount(_off).sub(_sold);
      uint256 weiByDiscount = couldBeSold.div(rate).div(100).mul(100 - _off);
      uint256 weiLefts = _value.sub(weiByDiscount);
      uint256 withoutDiscountLeft = weiLefts.mul(rate);
      uint256 byNextDiscount = withoutDiscountLeft.mul(100).div(100 - _off + 5);
      return couldBeSold.add(byNextDiscount);
    }
    return byDiscount;
  }
}