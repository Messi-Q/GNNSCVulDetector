pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 
contract MigrationAgent {
  function migrateFrom(address _from, uint256 _value);
}

contract ERC20 {
    function totalSupply() constant returns (uint256);
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value);
    function transferFrom(address from, address to, uint256 value);
    function approve(address spender, uint256 value);
    function allowance(address owner, address spender) constant returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PitEur is Ownable, ERC20 {
  using SafeMath for uint256;

  uint8 private _decimals = 18;
  uint256 private decimalMultiplier = 10**(uint256(_decimals));

  string private _name = "PIT-EUR";
  string private _symbol = "PIT-EUR";
  uint256 private _totalSupply = 100000000 * decimalMultiplier;

  bool public tradable = true;

   
  address public multisig;

   
  function name() constant returns (string) {
    return _name;
  }

   
  function symbol() constant returns (string) {
    return _symbol;
  }

   
  function decimals() constant returns (uint8) {
    return _decimals;
  }

   
  function totalSupply() constant returns (uint256) {
    return _totalSupply;
  }

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;
  mapping(address => uint256) releaseTimes;
  address public migrationAgent;
  uint256 public totalMigrated;

  event Migrate(address indexed _from, address indexed _to, uint256 _value);

   
   
   
  function PitEur(address _multisig) {
    require(_multisig != 0x0);
    multisig = _multisig;
    balances[multisig] = _totalSupply;
  }

  modifier canTrade() {
    require(tradable);
    _;
  }

   
   
  function transfer(address to, uint256 value) canTrade {
    require(!isLocked(msg.sender));
    require (balances[msg.sender] >= value && value > 0);
    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);
    Transfer(msg.sender, to, value);
  }

   
  function balanceOf(address who) constant returns (uint256) {
    return balances[who];
  }

  
  function transferFrom(address from, address to, uint256 value) canTrade {
    require(to != 0x0);
    require(!isLocked(from));
    uint256 _allowance = allowed[from][msg.sender];
    require(value > 0 && _allowance >= value);
    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    allowed[from][msg.sender] = _allowance.sub(value);
    Transfer(from, to, value);
  }

   
  function approve(address spender, uint256 value) canTrade {
    require((value >= 0) && (allowed[msg.sender][spender] >= 0));
    allowed[msg.sender][spender] = value;
    Approval(msg.sender, spender, value);
  }

   
   
   
   
  function allowance(address owner, address spender) constant returns (uint256) {
    return allowed[owner][spender];
  }

   
  function setTradable(bool _newTradableState) onlyOwner public {
    tradable = _newTradableState;
  }

   
  function timeLock(address spender, uint256 date) public onlyOwner returns (bool) {
    releaseTimes[spender] = date;
    return true;
  }

   
  function isLocked(address _spender) public view returns (bool) {
    if (releaseTimes[_spender] == 0 || releaseTimes[_spender] <= block.timestamp) {
      return false;
    }
    return true;
  }

   
  function setMigrationAgent(address _agent) external onlyOwner {
    require(migrationAgent == 0x0 && totalMigrated == 0);
    migrationAgent = _agent;
  }

   
  function migrate(uint256 value) external {
    require(migrationAgent != 0x0);
    require(value >= 0);
    require(value <= balances[msg.sender]);

    balances[msg.sender] -= value;
    _totalSupply = _totalSupply.sub(value);
    totalMigrated = totalMigrated.add(value);
    MigrationAgent(migrationAgent).migrateFrom(msg.sender, value);
    Migrate(msg.sender, migrationAgent, value);
  }
}