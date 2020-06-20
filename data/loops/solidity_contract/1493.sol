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

 

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

contract OrigoToken is PausableToken {

    string public constant name = "OrigoToken";
    string public constant symbol = "Origo";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = (10 ** 9) * (10 ** uint256(decimals));

     
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

}

 

 
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

     
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

     
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true; 
        }
    }

     
    function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

     
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

     
    function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

}

 

contract OrigoTokenSale is Whitelist {
    using SafeMath for uint256;


    bool public depositOpen;
    uint256 public collectTokenPhaseStartTime;

    OrigoToken public token;
    address public wallet;
    uint256 public rate;
    uint256 public minDeposit;
    uint256 public maxDeposit;


    mapping(address => uint256) public depositAmount;

     
    event Deposit(address indexed _depositor, uint256 _amount);

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(
        uint256 _rate,
        address _wallet,
        uint256 _minDeposit,
        uint256 _maxDeposit) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_minDeposit >= 0);
        require(_maxDeposit > 0);

        rate = _rate;
        wallet = _wallet;

        minDeposit = _minDeposit;
        maxDeposit = _maxDeposit;
        depositOpen = false;
    }
    function setRate(uint256 _rate) public onlyOwner {
      require(_rate > 0);
      rate = _rate;
    }
    function setToken(ERC20 _token) public onlyOwner  {
      require(_token != address(0));
      token = OrigoToken(_token);
    }
    function setWallet(address _wallet) public onlyOwner {
      require(_wallet != address(0));
      wallet = _wallet;
    }
    function openDeposit() public onlyOwner{
      depositOpen = true;
    }
    function closeDeposit() public onlyOwner{
      depositOpen = false;
    }

    function () external payable {
        deposit();
    }

    function deposit() public payable onlyWhileDepositPhaseOpen onlyWhitelisted {
        address beneficiary = msg.sender;
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        depositAmount[beneficiary] = depositAmount[beneficiary].add(weiAmount);
        emit Deposit(beneficiary, weiAmount);
    }

    function collectTokens() public onlyAfterCollectTokenPhaseStart {
        _distributeToken(msg.sender);
    }

    function distributeTokens(address _beneficiary) public onlyOwner onlyAfterCollectTokenPhaseStart {
        _distributeToken(_beneficiary);
    }

    function settleDeposit() public onlyOwner  {
        wallet.transfer(address(this).balance);
    }

    function settleExtraToken(address _addr) public onlyOwner  {
        require(token.transfer(_addr, token.balanceOf(this)));
    }

    function setCollectTokenTime(uint256 _collectTokenPhaseStartTime) public onlyOwner  {
        collectTokenPhaseStartTime = _collectTokenPhaseStartTime;
    }

    function getDepositAmount() public view returns (uint256) {
        return depositAmount[msg.sender];
    }

     
     
     

    function _distributeToken(address _beneficiary) internal {
        require(_beneficiary != 0);
        uint256 weiAmount = depositAmount[_beneficiary];

        uint256 tokens = weiAmount.mul(rate);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(_beneficiary, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary);
    }

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
        internal view
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(
            depositAmount[_beneficiary].add(_weiAmount) >= minDeposit &&
            depositAmount[_beneficiary].add(_weiAmount) <= maxDeposit);
    }

     
    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        require(token.transfer(_beneficiary, _tokenAmount));
    }

     
    function _processPurchase(
        address _beneficiary,
        uint256 _tokenAmount
    )
        internal
    {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _updatePurchasingState(address _beneficiary) internal {
        require(depositAmount[_beneficiary] > 0);
        depositAmount[_beneficiary] = 0;
    }

    modifier onlyWhileDepositPhaseOpen {
        require(depositOpen);
        _;
    }

    modifier onlyAfterCollectTokenPhaseStart {
        require(token != address(0));
        require(collectTokenPhaseStartTime > 0);
        require(block.timestamp >= collectTokenPhaseStartTime);
        _;
    }
}