pragma solidity ^0.4.21;
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
library DateTime {
         
        struct MyDateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }
        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;
        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;
        uint16 constant ORIGIN_YEAR = 1970;
        function isLeapYear(uint16 year) internal pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }
        function leapYearsBefore(uint year) internal pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }
        function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }
        function parseTimestamp(uint timestamp) internal pure returns (MyDateTime dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;
                 
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);
                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);
                 
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }
                 
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }
                 
                dt.hour = 0; 
                 
                dt.minute = 0; 
                 
                dt.second = 0; 
                 
                dt.weekday = 0; 
        }
        function getYear(uint timestamp) internal pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;
                 
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);
                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }
        function getMonth(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }
        function getDay(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }
        function getHour(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }
        function getMinute(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }
        function getSecond(uint timestamp) internal pure returns (uint8) {
                return uint8(timestamp % 60);
        }
        function toTimestamp(uint16 year, uint8 month, uint8 day) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }
        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) internal pure returns (uint timestamp) {
                uint16 i;
                 
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }
                 
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;
                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }
                 
                timestamp += DAY_IN_SECONDS * (day - 1);
                 
                timestamp += HOUR_IN_SECONDS * (hour);
                 
                timestamp += MINUTE_IN_SECONDS * (minute);
                 
                timestamp += second;
                return timestamp;
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
 
contract Claimable is Ownable {
  address public pendingOwner;
   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }
   
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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
 
contract ReentrancyGuard {
   
  bool private reentrancyLock = false;
   
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }
}
 
contract StandardBurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);
     
    function burn(uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
         
         
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        return true;
    }
}
contract Operational is Claimable {
    address public operator;
    function Operational(address _operator) public {
      operator = _operator;
    }
    modifier onlyOperator() {
      require(msg.sender == operator);
      _;
    }
    function transferOperator(address newOperator) public onlyOwner {
      require(newOperator != address(0));
      operator = newOperator;
    }
}
contract Frozenable is Operational, StandardBurnableToken, ReentrancyGuard {
    using DateTime for uint256;
    struct FrozenRecord {
        uint256 value;
        uint256 unfreezeIndex;
    }
    uint256 public frozenBalance;
    mapping (uint256 => FrozenRecord) public frozenRecords;
    uint256 mulDecimals = 100000000;  
    event SystemFreeze(address indexed owner, uint256 value, uint256 unfreezeIndex);
    event Unfreeze(address indexed owner, uint256 value, uint256 unfreezeTime);
    function Frozenable(address _operator) Operational(_operator) public {}
     
    function systemFreeze(uint256 _value, uint256 _unfreezeTime) internal {
        uint256 unfreezeIndex = uint256(_unfreezeTime.parseTimestamp().year) * 10000 + uint256(_unfreezeTime.parseTimestamp().month) * 100 + uint256(_unfreezeTime.parseTimestamp().day);
        balances[owner] = balances[owner].sub(_value);
        frozenRecords[unfreezeIndex] = FrozenRecord({value: _value, unfreezeIndex: unfreezeIndex});
        frozenBalance = frozenBalance.add(_value);
        emit SystemFreeze(owner, _value, _unfreezeTime);
    }
     
     
    function unfreeze(uint256 timestamp) public returns (uint256 unfreezeAmount) {
        require(timestamp <= block.timestamp);
        uint256 unfreezeIndex = uint256(timestamp.parseTimestamp().year) * 10000 + uint256(timestamp.parseTimestamp().month) * 100 + uint256(timestamp.parseTimestamp().day);
        frozenBalance = frozenBalance.sub(frozenRecords[unfreezeIndex].value);
        balances[owner] = balances[owner].add(frozenRecords[unfreezeIndex].value);
        unfreezeAmount = frozenRecords[unfreezeIndex].value;
        emit Unfreeze(owner, unfreezeAmount, timestamp);
        frozenRecords[unfreezeIndex].value = 0;
        return unfreezeAmount;
    }
}
contract Releaseable is Frozenable {
    using SafeMath for uint;
    uint256 public createTime;
    uint256 public releaseCount = 1;
    uint256 public standardReleaseAmount = mulDecimals.mul(512000);  
    uint256 public releaseAmountPerDay = mulDecimals.mul(512000);
    uint256 public releasedSupply = 0;
    event Release(address indexed receiver, uint256 value, uint256 sysAmount, uint256 releaseTime);
    struct ReleaseRecord {
        uint256 amount;  
        uint256 releaseIndex;  
    }
    mapping (uint256 => ReleaseRecord) public releaseRecords;
    function Releaseable(
                    address _operator, uint256 _initialSupply
                ) Frozenable(_operator) public {
        createTime = 1533607200; 
        releasedSupply = _initialSupply;
        balances[owner] = _initialSupply;
        systemFreeze(mulDecimals.mul(20000000), createTime.add(180 days));
        totalSupply_ = mulDecimals.mul(216280000);
    }
    function release(uint256 timestamp, uint256 sysAmount) public onlyOperator returns(uint256 _actualRelease) {
        require(timestamp >= createTime && timestamp <= block.timestamp);
        require(!checkIsReleaseRecordExist(timestamp));
        updateReleaseAmount();
        require(sysAmount <= releaseAmountPerDay.mul(3).div(5));
        require(totalSupply_ >= releasedSupply.add(releaseAmountPerDay));
        balances[owner] = balances[owner].add(releaseAmountPerDay);
        releasedSupply = releasedSupply.add(releaseAmountPerDay);
        uint256 _releaseIndex = uint256(timestamp.parseTimestamp().year) * 10000 + uint256(timestamp.parseTimestamp().month) * 100 + uint256(timestamp.parseTimestamp().day);
        releaseRecords[_releaseIndex] = ReleaseRecord(releaseAmountPerDay, _releaseIndex);
        releaseCount = releaseCount.add(1);
        emit Release(owner, releaseAmountPerDay, sysAmount, timestamp);
        systemFreeze(sysAmount.div(5), timestamp.add(180 days));
        systemFreeze(sysAmount.mul(6).div(10), timestamp.add(200 years));
        return releaseAmountPerDay;
    }
     
     
    function checkIsReleaseRecordExist(uint256 timestamp) internal view returns(bool _exist) {
        bool exist = false;
        uint256 releaseIndex = uint256(timestamp.parseTimestamp().year) * 10000 + uint256(timestamp.parseTimestamp().month) * 100 + uint256(timestamp.parseTimestamp().day);
        if (releaseRecords[releaseIndex].releaseIndex == releaseIndex){
            exist = true;
        }
        return exist;
    }
     
     
    function updateReleaseAmount() internal {
    	if (releaseCount <= 180) {
            releaseAmountPerDay = standardReleaseAmount;
        } else if (releaseCount <= 360) {
            releaseAmountPerDay = standardReleaseAmount.div(2);
        }
        else if (releaseCount <= 540) {
            releaseAmountPerDay = standardReleaseAmount.div(4);
        }
        
    }
}
contract CoinCool is Releaseable {
    string public standard = '2018080710';
    string public name = 'CoinCoolToken';
    string public symbol = 'CCT';
    uint8 public decimals = 8;
    function CoinCool() Releaseable(0x4068D7c2e286Cb1E72Cef90B74C823E990FaB9C2, mulDecimals.mul(55000000)) public {}
}