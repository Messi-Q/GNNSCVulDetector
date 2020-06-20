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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract Token {
  function transfer(address _to, uint256 _value) public returns (bool);
}

 
contract Crowdsale is Ownable {
  using SafeMath for uint256;

   
  Token public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  uint256 public startTime = now;

   
  uint256 round1StartTime;
  uint256 round1EndTime;
  uint256 round2StartTime;
  uint256 round2EndTime;
  uint256 round3StartTime;
  uint256 round3EndTime;
  uint256 round4StartTime;
  uint256 round4EndTime;

   
  uint256 public round1Bonus = 20;
  uint256 public round2Bonus = 15;
  uint256 public round3Bonus = 5;

   
  uint256 public minContribution = 100 finney;

   
  uint256 public round1Cap = uint256(9e8).mul(1 ether);
  uint256 public round2Cap = uint256(12e8).mul(1 ether);
  uint256 public round3Cap = uint256(15e8).mul(1 ether);
  uint256 public round4Cap = uint256(24e8).mul(1 ether);

   
  uint256 public round1Sold;
  uint256 public round2Sold;
  uint256 public round3Sold;
  uint256 public round4Sold;

   
  mapping(address => uint256) public contributions;

   
  uint256 hardCap = 12500 ether;
   
  uint256 softCap = 1250 ether;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  event ExternalTokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _newOwner, address _wallet, Token _token) public {
    require(_wallet != address(0));
    require(_token != address(0));
    rate = _rate;
    owner = _newOwner;
    wallet = _wallet;
    token = _token;
    round1StartTime = startTime;
    round1EndTime = round1StartTime.add(7 days);
    round2StartTime = round1EndTime.add(1 days);
    round2EndTime = round2StartTime.add(10 days);
    round3StartTime = round2EndTime.add(1 days);
    round3EndTime = round3StartTime.add(14 days);
    round4StartTime = round3EndTime.add(1 days);
    round4EndTime = round4StartTime.add(21 days);
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   

  function _getStageIndex () internal view returns (uint8) {
    if (now < round1StartTime) return 0;
    if (now <= round1EndTime) return 1;
    if (now < round2StartTime) return 2;
    if (now <= round2EndTime) return 3;
    if (now < round3StartTime) return 4;
    if (now <= round3EndTime) return 5;
    if (now < round4StartTime) return 6;
    if (now <= round4EndTime) return 7;
    return 8;
  }

   

  function getStageName () public view returns (string) {
    uint8 stageIndex = _getStageIndex();
    if (stageIndex == 0) return 'Pause';
    if (stageIndex == 1) return 'Round1';
    if (stageIndex == 2) return 'Round1 end';
    if (stageIndex == 3) return 'Round2';
    if (stageIndex == 4) return 'Round2 end';
    if (stageIndex == 5) return 'Round3';
    if (stageIndex == 6) return 'Round3 end';
    if (stageIndex == 7) return 'Round4';
    if (stageIndex == 8) return 'Round4 end';
    return 'Pause';
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    uint8 stageIndex = _getStageIndex();
    require(stageIndex > 0);
    require(stageIndex <= 8);

    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount, stageIndex);

     
    weiRaised = weiRaised.add(weiAmount);
    contributions[msg.sender] = contributions[msg.sender].add(weiAmount);

    if (stageIndex == 1 || stageIndex == 2) round1Sold = round1Sold.add(tokens);
    else if (stageIndex == 3 || stageIndex == 4) round2Sold = round2Sold.add(tokens);
    else if (stageIndex == 5 || stageIndex == 6) round3Sold = round3Sold.add(tokens);
    else round4Sold = round4Sold.add(tokens);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );
    if (weiRaised >= softCap) _forwardFunds();
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal view
  {
    require(_beneficiary != address(0));
    require(_weiAmount > 0);
    require(weiRaised.add(_weiAmount) <= hardCap);

    require(_weiAmount >= minContribution);
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

   
  function _getTokenAmount(uint256 _weiAmount, uint8 _stageIndex)
    internal view returns (uint256)
  {
    uint256 _bonus = 0;
    uint256 _cap;
    if (_stageIndex == 1) {
      _bonus = round1Bonus;
      _cap = round1Cap.sub(round1Sold);
    } else if (_stageIndex == 2) {
      _cap = round2Cap.sub(round1Sold);
    } else if (_stageIndex == 3) {
      _bonus = round2Bonus;
      _cap = round1Cap.sub(round1Sold).add(round2Cap).sub(round2Sold);
    } else if (_stageIndex == 4) {
      _cap = round1Cap.sub(round1Sold).add(round2Cap).sub(round2Sold);
    } else if (_stageIndex == 5) {
      _bonus = round3Bonus;
      _cap = round1Cap.sub(round1Sold).add(round2Cap).sub(round2Sold).add(round3Cap).sub(round3Sold);
    }  else if (_stageIndex == 6) {
      _cap = round1Cap.sub(round1Sold).add(round2Cap).sub(round2Sold).add(round3Cap).sub(round3Sold);
    } else {
      _cap = round1Cap.sub(round1Sold).add(round2Cap).sub(round2Sold).add(round3Cap).sub(round3Sold).add(round4Cap).sub(round4Sold);
    }

    uint256 _tokenAmount = _weiAmount.mul(rate);
    if (_bonus > 0) {
      uint256 _bonusTokens = _tokenAmount.mul(_bonus).div(100);
      _tokenAmount = _tokenAmount.add(_bonusTokens);
    }
    if (_stageIndex < 8) require(_tokenAmount <= _cap);
    return _tokenAmount;
  }

  function refund () public returns (bool) {
    require(now > round4EndTime);
    require(weiRaised < softCap);
    require(contributions[msg.sender] > 0);
    uint256 refundAmount = contributions[msg.sender];
    contributions[msg.sender] = 0;
    weiRaised = weiRaised.sub(refundAmount);
    msg.sender.transfer(refundAmount);
    return true;
  }

   
  function _forwardFunds() internal {
    wallet.transfer(address(this).balance);
  }

  function transferSoldTokens(address _beneficiary, uint256 _tokenAmount) public onlyOwner returns (bool) {
    uint8 stageIndex = _getStageIndex();
    require(stageIndex > 0);
    require(stageIndex <= 8);

    if (stageIndex == 1 || stageIndex == 2) {
      round1Sold = round1Sold.add(_tokenAmount);
      require(round1Sold <= round1Cap);
    } else if (stageIndex == 3 || stageIndex == 4) {
      round2Sold = round2Sold.add(_tokenAmount);
      require(round2Sold <= round2Cap);
    } else if (stageIndex == 5 || stageIndex == 6) {
      round3Sold = round3Sold.add(_tokenAmount);
      require(round3Sold <= round3Cap);
    } else if (stageIndex == 7) {
      round4Sold = round4Sold.add(_tokenAmount);
      require(round4Sold <= round4Cap);
    }
    emit ExternalTokenPurchase(
      _beneficiary,
      _beneficiary,
      _tokenAmount
    );

    require(token.transfer(_beneficiary, _tokenAmount));
    return true;
  }
}