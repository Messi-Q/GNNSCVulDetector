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

 

 
contract CryptualProjectToken is StandardToken, Ownable {
  using SafeMath for uint256;

   
  string public constant name = "Cryptual Project Token";  
  string public constant symbol = "CPT";  
  uint8 public constant decimals = 0;  

   
  uint256 public constant INITIAL_SUPPLY = 283000000;
  address public wallet;

   
  uint256 public constant PRESALE_OPENING_TIME = 1533726000;  
  uint256 public constant PRESALE_CLOSING_TIME = 1534291200;  
  uint256 public constant PRESALE_RATE = 150000;
  uint256 public constant PRESALE_WEI_CAP = 500 ether;
  uint256 public constant PRESALE_WEI_GOAL = 50 ether;

   
  uint256 public constant CROWDSALE_OPENING_TIME = 1534935600;  
  uint256 public constant CROWDSALE_CLOSING_TIME = 1540166400;  
  uint256 public constant CROWDSALE_WEI_CAP = 5000 ether;

   
  uint256 public constant COMBINED_WEI_GOAL = 750 ether;

   
  uint256[] public crowdsaleWeiAvailableLevels = [1000 ether, 1500 ether, 2000 ether];
  uint256[] public crowdsaleRates = [135000, 120000, 100000];
  uint256[] public crowdsaleMinElapsedTimeLevels = [0, 12 * 3600, 18 * 3600, 21 * 3600, 22 * 3600];
  uint256[] public crowdsaleUserCaps = [1 ether, 2 ether, 4 ether, 8 ether, CROWDSALE_WEI_CAP];
  mapping(address => uint256) public crowdsaleContributions;

   
  uint256 public presaleWeiRaised;
  uint256 public crowdsaleWeiRaised;

   
  constructor(
    address _wallet
  ) public {
    require(_wallet != address(0));
    wallet = _wallet;

    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    require(_beneficiary != address(0));
    require(weiAmount != 0);
    bool isPresale = block.timestamp >= PRESALE_OPENING_TIME && block.timestamp <= PRESALE_CLOSING_TIME && presaleWeiRaised.add(weiAmount) <= PRESALE_WEI_CAP;
    bool isCrowdsale = block.timestamp >= CROWDSALE_OPENING_TIME && block.timestamp <= CROWDSALE_CLOSING_TIME && presaleGoalReached() && crowdsaleWeiRaised.add(weiAmount) <= CROWDSALE_WEI_CAP;
    uint256 tokens;

    if (isCrowdsale) {
      require(crowdsaleContributions[_beneficiary].add(weiAmount) <= getCrowdsaleUserCap());
      
       
      tokens = _getCrowdsaleTokenAmount(weiAmount);
      require(tokens != 0);

       
      crowdsaleWeiRaised = crowdsaleWeiRaised.add(weiAmount);
    } else if (isPresale) {
      require(whitelist[_beneficiary]);
      
       
      tokens = weiAmount.mul(PRESALE_RATE).div(1 ether);
      require(tokens != 0);

       
      presaleWeiRaised = presaleWeiRaised.add(weiAmount);
    } else {
      revert();
    }

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    if (isCrowdsale) {
      crowdsaleContributions[_beneficiary] = crowdsaleContributions[_beneficiary].add(weiAmount);
      crowdsaleDeposited[_beneficiary] = crowdsaleDeposited[_beneficiary].add(msg.value);
    } else if (isPresale) {
      presaleDeposited[_beneficiary] = presaleDeposited[_beneficiary].add(msg.value);
    }
  }

   
  function getCrowdsaleUserCap() public view returns (uint256) {
    require(block.timestamp >= CROWDSALE_OPENING_TIME && block.timestamp <= CROWDSALE_CLOSING_TIME);
     
    uint256 elapsedTime = block.timestamp.sub(CROWDSALE_OPENING_TIME);
    uint256 currentMinElapsedTime = 0;
    uint256 currentCap = 0;

    for (uint i = 0; i < crowdsaleUserCaps.length; i++) {
      if (elapsedTime < crowdsaleMinElapsedTimeLevels[i]) continue;
      if (crowdsaleMinElapsedTimeLevels[i] < currentMinElapsedTime) continue;
      currentCap = crowdsaleUserCaps[i];
    }

    return currentCap;
  }

   
  function _getCrowdsaleTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 uncountedWeiRaised = crowdsaleWeiRaised;
    uint256 uncountedWeiAmount = _weiAmount;
    uint256 tokenAmount = 0;

    for (uint i = 0; i < crowdsaleWeiAvailableLevels.length; i++) {
      uint256 weiAvailable = crowdsaleWeiAvailableLevels[i];
      uint256 rate = crowdsaleRates[i];
      
      if (uncountedWeiRaised < weiAvailable) {
        if (uncountedWeiRaised > 0) {
          weiAvailable = weiAvailable.sub(uncountedWeiRaised);
          uncountedWeiRaised = 0;
        }

        if (uncountedWeiAmount <= weiAvailable) {
          tokenAmount = tokenAmount.add(uncountedWeiAmount.mul(rate));
          break;
        } else {
          uncountedWeiAmount = uncountedWeiAmount.sub(weiAvailable);
          tokenAmount = tokenAmount.add(weiAvailable.mul(rate));
        }
      } else {
        uncountedWeiRaised = uncountedWeiRaised.sub(weiAvailable);
      }
    }

    return tokenAmount.div(1 ether);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    totalSupply_ = totalSupply_.add(_tokenAmount);
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
    emit Transfer(0x0, _beneficiary, _tokenAmount);
  }
  
   
  mapping(address => bool) public whitelist;

   
  function addToPresaleWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToPresaleWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromPresaleWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

   
  bool public isPresaleFinalized = false;
  bool public isCrowdsaleFinalized = false;
  mapping (address => uint256) public presaleDeposited;
  mapping (address => uint256) public crowdsaleDeposited;

   
  event PresaleFinalized();
  event CrowdsaleFinalized();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

   
  function finalizePresale() external {
    require(!isPresaleFinalized);
    require(block.timestamp > PRESALE_CLOSING_TIME);

    if (presaleGoalReached()) {
      wallet.transfer(address(this).balance > presaleWeiRaised ? presaleWeiRaised : address(this).balance);
    } else {
      emit RefundsEnabled();
    }

    emit PresaleFinalized();
    isPresaleFinalized = true;
  }

   
  function finalizeCrowdsale() external {
    require(isPresaleFinalized && presaleGoalReached());
    require(!isCrowdsaleFinalized);
    require(block.timestamp > CROWDSALE_CLOSING_TIME);

    if (combinedGoalReached()) {
      wallet.transfer(address(this).balance);
    } else {
      emit RefundsEnabled();
    }

    emit CrowdsaleFinalized();
    isCrowdsaleFinalized = true;
  }

   
  function claimRefund() external {
    uint256 depositedValue = 0;

    if (isCrowdsaleFinalized && !combinedGoalReached()) {
      require(crowdsaleDeposited[msg.sender] > 0);
      depositedValue = crowdsaleDeposited[msg.sender];
      crowdsaleDeposited[msg.sender] = 0;
    } else if (isPresaleFinalized && !presaleGoalReached()) {
      require(presaleDeposited[msg.sender] > 0);
      depositedValue = presaleDeposited[msg.sender];
      presaleDeposited[msg.sender] = 0;
    }

    require(depositedValue > 0);
    msg.sender.transfer(depositedValue);
    emit Refunded(msg.sender, depositedValue);
  }

   
  function presaleGoalReached() public view returns (bool) {
    return presaleWeiRaised >= PRESALE_WEI_GOAL;
  }

   
  function combinedGoalReached() public view returns (bool) {
    return presaleWeiRaised.add(crowdsaleWeiRaised) >= COMBINED_WEI_GOAL;
  }

}