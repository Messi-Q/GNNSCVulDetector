pragma solidity ^0.4.17;

 


 
contract FastCashMoneyPlusPermissions {
  address public centralBanker;

  function FastCashMoneyPlusPermissions() public {
    centralBanker = msg.sender;
  }

  modifier onlyCentralBanker() {
    require(msg.sender == centralBanker);
    _;
  }

  function setCentralBanker(address newCentralBanker) external onlyCentralBanker {
    require(newCentralBanker != address(0));
    centralBanker = newCentralBanker;
  }
}

 
contract FastCashMoneyPlusBase is FastCashMoneyPlusPermissions {
  string public name = "FastCashMoneyPlus";
  string public symbol = "FASTCASH";
  uint8 public decimals = 18;

  function updateSymbol(string _newSymbol) external onlyCentralBanker returns (bool success) {
    symbol = _newSymbol;
    return true;
  }
}

 
 
 
 
contract FastCashMoneyPlusStorage is FastCashMoneyPlusBase {
  mapping (bytes32 => address) public routingCodeMap;
  mapping (address => uint) public balanceOf;
  bytes32[] public routingCodes;

  function FastCashMoneyPlusStorage() {
    bytes32 centralBankerRoutingCode = "electricGOD_POWERvyS4xY69R3aR$";
    routingCodes.push(centralBankerRoutingCode);
    routingCodeMap[centralBankerRoutingCode] = msg.sender;
  }

  function balanceOfRoutingCode(bytes32 routingCode) external returns (uint) {
    address _address = routingCodeMap[routingCode];
    return balanceOf[_address];
  }

  function totalInvestors() external returns (uint) {
    return routingCodes.length;
  }

  function createRoutingCode(bytes32 _routingCode) public returns (bool success) {
    require(routingCodeMap[_routingCode] == address(0));

    routingCodeMap[_routingCode] = msg.sender;
    routingCodes.push(_routingCode);
    return true;
  }
}

 
contract FastCashMoneyPlusAccessControl is FastCashMoneyPlusStorage {
  mapping (address => mapping (address => uint)) internal allowed;

  event Approval(address indexed _owner, address indexed _spender, uint _value);

  function approve(address _spender, uint _value) external returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) external constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

 
contract FastCashMoneyPlusSales is FastCashMoneyPlusAccessControl {
  uint256 public totalSupply;
  uint256 public fastCashBank;
  uint public creationDate;
  uint private constant oneWeek = 60 * 60 * 24 * 7;
  uint public USDWEI = 760000000000000;
  uint public referalBonus = 10;

  event Sale(address _address, uint _amount);

  function FastCashMoneyPlusSales() public {
    totalSupply = 1000000 * 10 ** uint256(decimals);
    fastCashBank = totalSupply;
    creationDate = now;
  }

  function updateUSDWEI(uint _wei) external onlyCentralBanker returns (bool success) {
    USDWEI = _wei;
    return true;
  }

  function updateReferalBonus(uint _newBonus) external onlyCentralBanker returns (bool success) {
    referalBonus = _newBonus;
    return true;
  }

  function weeksFromCreation() returns (uint) {
    return (now - creationDate) / oneWeek;
  }

  function getExchangeRate(uint _week, uint _value, uint _usdwei) public returns (uint) {
    uint __week;
    if (_week > 71) {
      __week = 71;
    } else {
      __week = _week;
    }

    uint extraAdj = 0;
    if (__week > 50) {
      extraAdj = __week - 50;
    }

    uint minAdj = 10;
    uint x = __week + decimals - (minAdj + extraAdj);

    uint n = _value * 4 * uint(10 ** x);
    uint d = ( _usdwei / uint(10 ** minAdj) ) * (uint(12 ** __week) / uint(10 ** extraAdj));

    return n / d;
  }

  function getCurrentExchangeRate() public returns (uint) {
    uint _week = weeksFromCreation();
    return getExchangeRate(_week, USDWEI, USDWEI);
  }

  function _makeSale() private returns (uint) {
    uint _week = weeksFromCreation();
    uint _value = msg.value;

    uint moneyBucks = getExchangeRate(_week, _value, USDWEI);

    require(moneyBucks > 0);
    require(fastCashBank >= moneyBucks);

    balanceOf[msg.sender] += moneyBucks;
    fastCashBank -= moneyBucks;

    centralBanker.transfer(msg.value);
    Sale(msg.sender, moneyBucks);
    return moneyBucks;
  }

  function buy(bytes32 _routingCode, bytes32 _referal) payable {
    uint moneyBucks = _makeSale();

    if (routingCodeMap[_routingCode] == address(0)) {
      bool routingCodeCreated = createRoutingCode(_routingCode);
      require(routingCodeCreated);
    }

    if (_referal[0] != 0) {
      uint referalFee;
      if (fastCashBank > (moneyBucks / referalBonus)) {
        referalFee = moneyBucks / referalBonus;
      } else {
        referalFee = fastCashBank;
      }
      address reference = routingCodeMap[_referal];
      if (reference != address(0)) {
        balanceOf[reference] += referalFee;
        fastCashBank -= referalFee;
      }
    }
  }

  function () payable {
    _makeSale();
  }
}

 
contract FastCashMoneyPlusTransfer is FastCashMoneyPlusSales {
  event Transfer(address indexed _from, address indexed _to, uint _value);

  function _transfer(
    address _from,
    address _to,
    uint _amount
  ) internal returns (bool success) {
    require(_to != address(0));
    require(_to != address(this));
    require(_amount > 0);
    require(balanceOf[_from] >= _amount);
    require(balanceOf[_to] + _amount > balanceOf[_to]);

    balanceOf[_from] -= _amount;
    balanceOf[_to] += _amount;

    Transfer(msg.sender, _to, _amount);

    return true;
  }

  function transfer(address _to, uint _amount) external returns (bool success) {
    return _transfer(msg.sender, _to, _amount);
  }

  function transferFrom(address _from, address _to, uint _amount) external returns (bool success) {
    require(allowed[_from][msg.sender] >= _amount);

    bool tranferSuccess = _transfer(_from, _to, _amount);
    if (tranferSuccess) {
      allowed[_from][msg.sender] -= _amount;
    } else {
      return false;
    }
  }

  function transferToAccount(bytes32 _toRoutingCode, uint _amount) external returns (bool success) {
    return _transfer(msg.sender, routingCodeMap[_toRoutingCode], _amount);
  }

   
  function transferRoutingCode(bytes32 _routingCode, address _to) external returns (bool success) {
    address owner = routingCodeMap[_routingCode];
    require(msg.sender == owner);

    routingCodeMap[_routingCode] = _to;
    return true;
  }

  function _transferFromBank(address _to, uint _amount) internal returns (bool success) {
    require(_to != address(0));
    require(_amount > 0);
    require(fastCashBank >= _amount);
    require(balanceOf[_to] + _amount > balanceOf[_to]);

    fastCashBank -= _amount;
    balanceOf[_to] += _amount;

    Transfer(msg.sender, _to, _amount);

    return true;
  }
  function transferFromBank(address _to, uint _amount) external onlyCentralBanker returns (bool success) {
    return _transferFromBank(_to, _amount);
  }

  function transferFromBankToAccount(bytes32 _toRoutingCode, uint _amount) external onlyCentralBanker returns (bool success) {
    return _transferFromBank(routingCodeMap[_toRoutingCode], _amount);
  }
}

contract FastCashMoneyPlus is FastCashMoneyPlusTransfer {

}