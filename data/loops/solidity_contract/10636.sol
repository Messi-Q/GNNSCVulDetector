pragma solidity ^0.4.23;

 
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

 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
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

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
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

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
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

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

 
contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
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

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

contract ClosableCrowdsale is Ownable {

    bool public isClosed = false;

    event Closed();

    modifier onlyOpenCrowdsale() {
        require(!isClosed);
        _;
    }

     
    function closeCrowdsale() onlyOwner onlyOpenCrowdsale public {
        close();
        emit Closed();

        isClosed = true;
    }

     
    function close() internal {
    }

}

contract MaxContributionCrowdsale {

    function getMaxContributionAmount() public view returns (uint256) {
         
        return 15 ether;
    }

}

contract BasicCrowdsale is MintedCrowdsale, CappedCrowdsale, ClosableCrowdsale {
    uint256 public startingTime;

    address public maxContributionAmountContract;

    uint256 constant MIN_CONTRIBUTION_AMOUNT = 1 finney;

    uint256 constant PRE_SALE_CAP = 19747 ether;
    uint256 constant PRE_SALE_RATE = 304;

    uint256 constant BONUS_1_AMOUNT = 39889 ether;
    uint256 constant BONUS_2_AMOUNT = 60031 ether;
    uint256 constant BONUS_3_AMOUNT = 80173 ether;
    uint256 constant BONUS_4_AMOUNT = 92021 ether;
    uint256 constant BONUS_5_AMOUNT = 103079 ether;

    uint256 constant BONUS_1_CAP = PRE_SALE_CAP + BONUS_1_AMOUNT;
    uint256 constant BONUS_1_RATE = 276;

    uint256 constant BONUS_2_CAP = BONUS_1_CAP + BONUS_2_AMOUNT;
    uint256 constant BONUS_2_RATE = 266;

    uint256 constant BONUS_3_CAP = BONUS_2_CAP + BONUS_3_AMOUNT;
    uint256 constant BONUS_3_RATE = 261;

    uint256 constant BONUS_4_CAP = BONUS_3_CAP + BONUS_4_AMOUNT;
    uint256 constant BONUS_4_RATE = 258;

    uint256 constant BONUS_5_CAP = BONUS_4_CAP + BONUS_5_AMOUNT;
    uint256 constant REGULAR_RATE = 253;

    event LogBountyTokenMinted(address minter, address beneficiary, uint256 amount);

    constructor(uint256 _rate, address _wallet, address _token, uint256 _cap, address _maxContributionAmountContract)
    Crowdsale(_rate, _wallet, ERC20(_token))
    CappedCrowdsale(_cap) public {
        startingTime = now;
        maxContributionAmountContract = _maxContributionAmountContract;
    }

    function setMaxContributionCrowdsaleAddress(address _maxContributionAmountContractAddress) public onlyOwner {
        maxContributionAmountContract = _maxContributionAmountContractAddress;
    }

    function getMaxContributionAmount() public view returns(uint256) {
        return MaxContributionCrowdsale(maxContributionAmountContract).getMaxContributionAmount();
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) onlyOpenCrowdsale internal {
        require(msg.value >= MIN_CONTRIBUTION_AMOUNT);
        require(msg.value <= getMaxContributionAmount());
        super._preValidatePurchase(beneficiary, weiAmount);
    }

    function getRate() public constant returns (uint256) {
        require(now >= startingTime);

         
        if (weiRaised < PRE_SALE_CAP) {
            return PRE_SALE_RATE;
        }

         
        if (weiRaised < BONUS_1_CAP) {
            return BONUS_1_RATE;
        }

         
        if (weiRaised < BONUS_2_CAP) {
            return BONUS_2_RATE;
        }

         
        if (weiRaised < BONUS_3_CAP) {
            return BONUS_3_RATE;
        }

         
        if (weiRaised < BONUS_4_CAP) {
            return BONUS_4_RATE;
        }

         
        return rate;
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 _rate = getRate();
        return _weiAmount.mul(_rate);
    }

    function createBountyToken(address beneficiary, uint256 amount) public onlyOwner onlyOpenCrowdsale returns (bool) {
        MintableToken(token).mint(beneficiary, amount);
        LogBountyTokenMinted(msg.sender, beneficiary, amount);
        return true;
    }

    function close() internal {
        MintableToken(token).transferOwnership(owner);
        super.close();
    }

}

contract WhitelistedBasicCrowdsale is BasicCrowdsale, WhitelistedCrowdsale {


    constructor(uint256 _rate, address _wallet, address _token, uint256 _cap, address _maxContributionAmountContract)
    BasicCrowdsale(_rate, _wallet, ERC20(_token), _cap, _maxContributionAmountContract)
    WhitelistedCrowdsale()
    public {
    }
}