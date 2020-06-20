pragma solidity ^0.4.11;

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

 
contract Haltable is Ownable {
  bool public halted = false;

  modifier inNormalState {
    require(!halted);
    _;
  }

  modifier inEmergencyState {
    require(halted);
    _;
  }

   
  function halt() external onlyOwner inNormalState {
    halted = true;
  }

   
  function unhalt() external onlyOwner inEmergencyState {
    halted = false;
  }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract Burnable is StandardToken {
  using SafeMath for uint;

   
  event Burn(address indexed from, uint value);

  function burn(uint _value) returns (bool success) {
    require(_value > 0 && balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(msg.sender, _value);
    return true;
  }

  function burnFrom(address _from, uint _value) returns (bool success) {
    require(_from != 0x0 && _value > 0 && balances[_from] >= _value);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    totalSupply = totalSupply.sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Burn(_from, _value);
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    require(_to != 0x0);  

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    require(_to != 0x0);  

    return super.transferFrom(_from, _to, _value);
  }
}

 

contract ERC223ReceivingContract {
 
    function tokenFallback(address _from, uint _value, bytes _data);
}

 
contract AnythingAppToken is Burnable, Ownable {

  string public constant name = "AnyCoin";
  string public constant symbol = "ANY";
  uint8 public constant decimals = 18;
  uint public constant INITIAL_SUPPLY = 400000000 * 1 ether;

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {
    require(released || transferAgents[_sender]);
    _;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }


   
  function AnythingAppToken() {
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);

     
    releaseAgent = addr;
  }

  function release() onlyReleaseAgent inReleaseState(false) public {
    released = true;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    require(addr != 0x0);
    transferAgents[addr] = state;
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }


   
    function transfer(address _to, uint _value, bytes _data) canTransfer(msg.sender) returns (bool success) {
      require(_to != address(0));
      require(_value <= balances[msg.sender]);
      uint codeLength;
      assembly {
          codeLength := extcodesize(_to)
      }
      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      if(codeLength>0) {
          ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
          receiver.tokenFallback(msg.sender, _value, _data);
      }
      Transfer(msg.sender, _to, _value);
      return true;
    }

     
    function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
      require(_to != address(0));
      require(_value <= balances[msg.sender]);

      uint codeLength;
      bytes memory empty;

      assembly {
          codeLength := extcodesize(_to)
      }

      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      if(codeLength>0) {
          ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
          receiver.tokenFallback(msg.sender, _value, empty);
      }
      Transfer(msg.sender, _to, _value);
      return true;
    }

  function burn(uint _value) onlyOwner returns (bool success) {
    return super.burn(_value);
  }

  function burnFrom(address _from, uint _value) onlyOwner returns (bool success) {
    return super.burnFrom(_from, _value);
  }
}

contract InvestorWhiteList is Ownable {
  mapping (address => bool) public investorWhiteList;

  mapping (address => address) public referralList;

  function InvestorWhiteList() {

  }

  function addInvestorToWhiteList(address investor) external onlyOwner {
    require(investor != 0x0 && !investorWhiteList[investor]);
    investorWhiteList[investor] = true;
  }

  function removeInvestorFromWhiteList(address investor) external onlyOwner {
    require(investor != 0x0 && investorWhiteList[investor]);
    investorWhiteList[investor] = false;
  }

   
  function addReferralOf(address investor, address referral) external onlyOwner {
    require(investor != 0x0 && referral != 0x0 && referralList[investor] == 0x0 && investor != referral);
    referralList[investor] = referral;
  }

  function isAllowed(address investor) constant external returns (bool result) {
    return investorWhiteList[investor];
  }

  function getReferralOf(address investor) constant external returns (address result) {
    return referralList[investor];
  }
}

contract PriceReceiver {
  address public ethPriceProvider;

  modifier onlyEthPriceProvider() {
    require(msg.sender == ethPriceProvider);
    _;
  }

  function receiveEthPrice(uint ethUsdPrice) external;

  function setEthPriceProvider(address provider) external;
}

contract AnythingAppTokenPreSale is Haltable, PriceReceiver {
  using SafeMath for uint;

  string public constant name = "AnythingAppTokenPreSale";

  AnythingAppToken public token;
  InvestorWhiteList public investorWhiteList;
  address public beneficiary;

  uint public tokenPriceUsd;
  uint public totalTokens; 

  uint public ethUsdRate;

  uint public collected = 0;
  uint public withdrawn = 0;
  uint public tokensSold = 0;
  uint public investorCount = 0;
  uint public weiRefunded = 0;

  uint public startTime;
  uint public endTime;

  bool public crowdsaleFinished = false;

  mapping (address => bool) public refunded;
  mapping (address => uint) public deposited;

  uint public constant BONUS_LEVEL_1 = 40;
  uint public constant BONUS_LEVEL_2 = 35;
  uint public constant BONUS_LEVEL_3 = 30;

  uint public firstStage;
  uint public secondStage;
  uint public thirdStage;

  uint public constant MINIMAL_PURCHASE = 250 ether;
  uint public constant LIMIT_PER_USER = 500000 ether;

  event NewContribution(address indexed holder, uint tokenAmount, uint etherAmount);
  event NewReferralTransfer(address indexed investor, address indexed referral, uint tokenAmount);
  event Refunded(address indexed holder, uint amount);
  event Deposited(address indexed holder, uint amount);

  modifier preSaleActive() {
    require(block.timestamp >= startTime && block.timestamp < endTime);
    _;
  }

  modifier preSaleEnded() {
    require(block.timestamp >= endTime);
    _;
  }

  modifier inWhiteList() {
    require(investorWhiteList.isAllowed(msg.sender));
    _;
  }

  function AnythingAppTokenPreSale(
    address _token,
    address _beneficiary,
    address _investorWhiteList,

    uint _totalTokens,
    uint _tokenPriceUsd,

    uint _baseEthUsdPrice,

    uint _firstStage,
    uint _secondStage,
    uint _thirdStage,

    uint _startTime,
    uint _endTime
  ) {
    ethUsdRate = _baseEthUsdPrice;
    tokenPriceUsd = _tokenPriceUsd;

    totalTokens = _totalTokens.mul(1 ether);

    token = AnythingAppToken(_token);
    investorWhiteList = InvestorWhiteList(_investorWhiteList);
    beneficiary = _beneficiary;

    firstStage = _firstStage.mul(1 ether);
    secondStage = _secondStage.mul(1 ether);
    thirdStage = _thirdStage.mul(1 ether);

    startTime = _startTime;
    endTime = _endTime;
  }

  function() payable inWhiteList {
    doPurchase(msg.sender);
  }

  function tokenFallback(address _from, uint _value, bytes _data) public pure { }

  function doPurchase(address _owner) private preSaleActive inNormalState {
    if (token.balanceOf(msg.sender) == 0) investorCount++;

    uint tokens = msg.value.mul(ethUsdRate).div(tokenPriceUsd);
    address referral = investorWhiteList.getReferralOf(msg.sender);
    uint referralBonus = calculateReferralBonus(tokens);
    uint bonus = calculateBonus(tokens, referral);

    tokens = tokens.add(bonus);

    uint newTokensSold = tokensSold.add(tokens);
    if (referralBonus > 0 && referral != 0x0) {
      newTokensSold = newTokensSold.add(referralBonus);
    }

    require(newTokensSold <= totalTokens);
    require(token.balanceOf(msg.sender).add(tokens) <= LIMIT_PER_USER);

    tokensSold = newTokensSold;

    collected = collected.add(msg.value);
    deposited[msg.sender] = deposited[msg.sender].add(msg.value);

    token.transfer(msg.sender, tokens);
    NewContribution(_owner, tokens, msg.value);

    if (referralBonus > 0 && referral != 0x0) {
      token.transfer(referral, referralBonus);
      NewReferralTransfer(msg.sender, referral, referralBonus);
    }
  }

  function calculateBonus(uint _tokens, address _referral) private returns (uint _bonuses) {
    uint bonus;

    if (tokensSold < firstStage) {
      bonus = BONUS_LEVEL_1;
    } else if (tokensSold >= firstStage && tokensSold < secondStage) {
      bonus = BONUS_LEVEL_2;
    } else {
      bonus = BONUS_LEVEL_3;
    }

    if (_referral != 0x0) {
      bonus += 5;
    }

    return _tokens.mul(bonus).div(100);
  }

  function calculateReferralBonus(uint _tokens) internal constant returns (uint _bonus) {
    return _tokens.mul(20).div(100);
  }

  function withdraw() external onlyOwner {
    uint withdrawLimit = 500 ether;
    if (withdrawn < withdrawLimit) {
      uint toWithdraw = collected.sub(withdrawn);
      if (toWithdraw + withdrawn > withdrawLimit) {
        toWithdraw = withdrawLimit.sub(withdrawn);
      }
      beneficiary.transfer(toWithdraw);
      withdrawn = withdrawn.add(toWithdraw);
      return;
    }
    require(block.timestamp >= endTime);
    beneficiary.transfer(collected);
    token.transfer(beneficiary, token.balanceOf(this));
    crowdsaleFinished = true;
  }

  function refund() external preSaleEnded inNormalState {
    require(refunded[msg.sender] == false);

    uint refund = deposited[msg.sender];
    require(refund > 0);

    deposited[msg.sender] = 0;
    refunded[msg.sender] = true;
    weiRefunded = weiRefunded.add(refund);
    msg.sender.transfer(refund);
    Refunded(msg.sender, refund);
  }

  function receiveEthPrice(uint ethUsdPrice) external onlyEthPriceProvider {
    require(ethUsdPrice > 0);
    ethUsdRate = ethUsdPrice;
  }

  function setEthPriceProvider(address provider) external onlyOwner {
    require(provider != 0x0);
    ethPriceProvider = provider;
  }

  function setNewWhiteList(address newWhiteList) external onlyOwner {
    require(newWhiteList != 0x0);
    investorWhiteList = InvestorWhiteList(newWhiteList);
  }
}