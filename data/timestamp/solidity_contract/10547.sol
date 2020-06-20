pragma solidity ^0.4.23;

 
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



 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
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

 
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
     
    canMint
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}



contract ATTRToken is CappedToken, DetailedERC20 {

  using SafeMath for uint256;

  uint256 public constant TOTAL_SUPPLY       = uint256(1000000000);
  uint256 public constant TOTAL_SUPPLY_ACES  = uint256(1000000000000000000000000000);
  uint256 public constant CROWDSALE_MAX_ACES = uint256(500000000000000000000000000);

  address public crowdsaleContract;
  uint256 public crowdsaleMinted = uint256(0);

  uint256 public releaseTime = uint256(1536278399);  
  bool    public fundingLowcapReached = false;
  bool    public isReleased = false;

  mapping (address => bool) public agents;

  mapping (address => bool) public transferWhitelist;

  constructor() public 
    CappedToken(TOTAL_SUPPLY_ACES) 
    DetailedERC20("Attrace", "ATTR", uint8(18)) {
    transferWhitelist[msg.sender] = true;
    agents[msg.sender] = true;
  }
  
   
   
   
  modifier isInitialized() {
    require(crowdsaleContract != address(0));
    require(releaseTime > 0);
    _;
  }

   
   
   
  function setAgent(address _address, bool _status) public onlyOwner {
    require(_address != address(0));
    agents[_address] = _status;
  }

  modifier onlyAgents() {
    require(agents[msg.sender] == true);
    _;
  }

  function setCrowdsaleContract(address _crowdsaleContract) public onlyAgents {
    require(_crowdsaleContract != address(0));
    crowdsaleContract = _crowdsaleContract;
  }

  function setTransferWhitelist(address _address, bool _canTransfer) public onlyAgents {
    require(_address != address(0));
    transferWhitelist[_address] = _canTransfer;
  }

  function setReleaseTime(uint256 _time) public onlyAgents {
    require(_time > block.timestamp);
    require(isReleased == false);
    releaseTime = _time;
  }

  function setFundingLowcapReached(uint256 _verification) public onlyAgents {
    require(_verification == uint256(20234983249), "wrong verification code");
    fundingLowcapReached = true;
  }

  function markReleased() public {
    if (isReleased == false && _now() > releaseTime) {
      isReleased = true;
    }
  }

   
   
   
  modifier hasMintPermission() {
    require(msg.sender == crowdsaleContract || agents[msg.sender] == true);
    _;
  }

  function mint(address _to, uint256 _aces) public canMint hasMintPermission returns (bool) {
    if (msg.sender == crowdsaleContract) {
      require(crowdsaleMinted.add(_aces) <= CROWDSALE_MAX_ACES);
      crowdsaleMinted = crowdsaleMinted.add(_aces);
    }
    return super.mint(_to, _aces);
  }

   
   
   
  modifier canTransfer(address _from) {
    if (transferWhitelist[_from] == false) {
      require(block.timestamp >= releaseTime);
      require(fundingLowcapReached == true);
    }
    _;
  }

  function transfer(address _to, uint256 _aces) 
    public
    isInitialized
    canTransfer(msg.sender) 
    tokensAreUnlocked(msg.sender, _aces)
    returns (bool) {
      markReleased();
      return super.transfer(_to, _aces);
    }

  function transferFrom(address _from, address _to, uint256 _aces) 
    public
    isInitialized
    canTransfer(_from) 
    tokensAreUnlocked(_from, _aces)
    returns (bool) {
      markReleased();
      return super.transferFrom(_from, _to, _aces);
    }

   
   
   
  struct VestingRule {
    uint256 aces;
    uint256 unlockTime;
    bool    processed;
  }

   
  mapping (address => uint256) public lockedAces;

  modifier tokensAreUnlocked(address _from, uint256 _aces) {
    if (lockedAces[_from] > uint256(0)) {
      require(balanceOf(_from).sub(lockedAces[_from]) >= _aces);
    }
    _;
  }

   
  mapping (address => VestingRule[]) public vestingRules;

  function processVestingRules(address _address) public onlyAgents {
    _processVestingRules(_address);
  }

  function processMyVestingRules() public {
    _processVestingRules(msg.sender);
  }

  function addVestingRule(address _address, uint256 _aces, uint256 _unlockTime) public {
    require(_aces > 0);
    require(_address != address(0));
    require(_unlockTime > _now());
    if (_now() < releaseTime) {
      require(msg.sender == owner);
    } else {
      require(msg.sender == crowdsaleContract || msg.sender == owner);
      require(_now() < releaseTime.add(uint256(2592000)));
    }
    vestingRules[_address].push(VestingRule({ 
      aces: _aces,
      unlockTime: _unlockTime,
      processed: false
    }));
    lockedAces[_address] = lockedAces[_address].add(_aces);
  }

   
   
  function _processVestingRules(address _address) internal {
    for (uint256 i = uint256(0); i < vestingRules[_address].length; i++) {
      if (vestingRules[_address][i].processed == false && vestingRules[_address][i].unlockTime < _now()) {
        lockedAces[_address] = lockedAces[_address].sub(vestingRules[_address][i].aces);
        vestingRules[_address][i].processed = true;
      }
    }
  }

   
   
   
  function _now() internal view returns (uint256) {
    return block.timestamp;
  }
}