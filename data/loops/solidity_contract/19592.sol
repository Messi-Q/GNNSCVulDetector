pragma solidity ^0.4.18;

contract Owner {
    address public owner;
     
    bool public stopped = false;

    function Owner() internal {
        owner = msg.sender;
    }

    modifier onlyOwner {
       require (msg.sender == owner);
       _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require (newOwner != 0x0);
        require (newOwner != owner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
    }

    function toggleContractActive() onlyOwner public {
         
        stopped = !stopped;
    }

    modifier stopInEmergency {
        require(stopped == false);
        _;
    }

    modifier onlyInEmergency {
        require(stopped == true);
        _;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract Mortal is Owner {
     
    function close() external onlyOwner {
        selfdestruct(owner);
    }
}

 
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

contract Token is Owner, Mortal {
    using SafeMath for uint256;

    string public name;  
    string public symbol;  
    uint8 public decimals;  
    uint256 public totalSupply;  

     
    struct Fund{
        uint amount;             

        uint unlockStartTime;    
        uint unlockInterval;     
        uint unlockPercent;      

        bool isValue;  
    }

     
    mapping (address => uint) public balances;
     
    mapping(address => mapping(address => uint)) approved;

     
    mapping (address => Fund) public frozenAccount;

     
    event Transfer(address indexed from, address indexed to, uint value);
    event FrozenFunds(address indexed target, uint value, uint unlockStartTime, uint unlockIntervalUnit, uint unlockInterval, uint unlockPercent);
    event Approval(address indexed accountOwner, address indexed spender, uint256 value);

     
    modifier onlyPayloadSize(uint256 size) {
        require(msg.data.length == size + 4);
        _;
    }

     
    function freezeAccount(address target, uint value, uint unlockStartTime, uint unlockIntervalUnit, uint unlockInterval, uint unlockPercent) external onlyOwner freezeOutCheck(target, 0) {
        require (value > 0);
        require (frozenAccount[target].isValue == false);
        require (balances[msg.sender] >= value);
        require (unlockStartTime > now);
        require (unlockInterval > 0);
        require (unlockPercent > 0 && unlockPercent <= 100);

        uint unlockIntervalSecond = toSecond(unlockIntervalUnit, unlockInterval);

        frozenAccount[target] = Fund(value, unlockStartTime, unlockIntervalSecond, unlockPercent, true);
        emit FrozenFunds(target, value, unlockStartTime, unlockIntervalUnit, unlockInterval, unlockPercent);
    }

     
    function transferAndFreeze(address target, uint256 value, uint unlockStartTime, uint unlockIntervalUnit, uint unlockInterval, uint unlockPercent) external onlyOwner freezeOutCheck(target, 0) {
        require (value > 0);
        require (frozenAccount[target].isValue == false);
        require (unlockStartTime > now);
        require (unlockInterval > 0);
        require (unlockPercent > 0 && unlockPercent <= 100);

        _transfer(msg.sender, target, value);

        uint unlockIntervalSecond = toSecond(unlockIntervalUnit, unlockInterval);
        frozenAccount[target] = Fund(value, unlockStartTime, unlockIntervalSecond, unlockPercent, true);
        emit FrozenFunds(target, value, unlockStartTime, unlockIntervalUnit, unlockInterval, unlockPercent);
    }

     
    function toSecond(uint unitType, uint value) internal pure returns (uint256 Seconds) {
        uint _seconds;
        if (unitType == 5){
            _seconds = value.mul(1 years);
        }else if(unitType == 4){
            _seconds = value.mul(1 days);
        }else if (unitType == 3){
            _seconds = value.mul(1 hours);
        }else if (unitType == 2){
            _seconds = value.mul(1 minutes);
        }else if (unitType == 1){
            _seconds = value;
        }else{
            revert();
        }
        return _seconds;
    }

    modifier freezeOutCheck(address sender, uint value) {
        require ( getAvailableBalance(sender) >= value);
        _;
    }

     
    function getAvailableBalance(address sender) internal returns(uint balance) {
        if (frozenAccount[sender].isValue) {
             
            if (now < frozenAccount[sender].unlockStartTime){
                return balances[sender] - frozenAccount[sender].amount;
            }else{
                 
                uint unlockPercent = ((now - frozenAccount[sender].unlockStartTime ) / frozenAccount[sender].unlockInterval + 1) * frozenAccount[sender].unlockPercent;
                if (unlockPercent > 100){
                    unlockPercent = 100;
                }

                 
                assert(frozenAccount[sender].amount <= balances[sender]);
                uint available = balances[sender] - (100 - unlockPercent) * frozenAccount[sender].amount / 100;
                if ( unlockPercent >= 100){
                     
                    frozenAccount[sender].isValue = false;
                    delete frozenAccount[sender];
                }

                return available;
            }
        }
        return balances[sender];
    }

    function balanceOf(address sender) constant external returns (uint256 balance){
        return balances[sender];
    }

     
    function transfer(address to, uint256 value) external stopInEmergency onlyPayloadSize(2 * 32) {
        _transfer(msg.sender, to, value);
    }

    function _transfer(address _from, address _to, uint _value) internal freezeOutCheck(_from, _value) {
        require(_to != 0x0);
        require(_from != _to);
        require(_value > 0);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(_from, _to, _value);
    }

     
     
    function approve(address spender, uint value) external returns (bool success) {
        approved[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

     
    function allowance(address accountOwner, address spender) constant external returns (uint remaining) {
        return approved[accountOwner][spender];
    }

     
     
     
    function transferFrom(address from, address to, uint256 value) external stopInEmergency freezeOutCheck(from, value)  returns (bool success) {
        require(value > 0);
        require(value <= approved[from][msg.sender]);
        require(value <= balances[from]);

        approved[from][msg.sender] = approved[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }
}

contract MigrationAgent {
  function migrateFrom(address from, uint256 value) public;
}

contract UpgradeableToken is Owner, Token {
  address public migrationAgent;

   
  event Upgrade(address indexed from, address indexed to, uint256 value);

   
  event UpgradeAgentSet(address agent);

   
  function migrate() public {
    require(migrationAgent != 0);
    uint value = balances[msg.sender];
    balances[msg.sender] = balances[msg.sender].sub(value);
    totalSupply = totalSupply.sub(value);
    MigrationAgent(migrationAgent).migrateFrom(msg.sender, value);
    emit Upgrade(msg.sender, migrationAgent, value);
  }

  function () public payable {
    require(migrationAgent != 0);
    require(balances[msg.sender] > 0);
    migrate();
    msg.sender.transfer(msg.value);
  }

  function setMigrationAgent(address _agent) onlyOwner external {
    migrationAgent = _agent;
    emit UpgradeAgentSet(_agent);
  }
}

contract MIToken is UpgradeableToken {

  function MIToken() public {
    name = "MI Token";
    symbol = "MI";
    decimals = 18;

    owner = msg.sender;
    uint initialSupply = 100000000;

    totalSupply = initialSupply * 10 ** uint256(decimals);
    require (totalSupply >= initialSupply);

    balances[msg.sender] = totalSupply;
    emit Transfer(0x0, msg.sender, totalSupply);
  }
  
  function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
      totalSupply = totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      
      emit Transfer(address(0), _to, _amount);
      return true;
  }
  
}