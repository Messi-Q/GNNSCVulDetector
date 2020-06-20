pragma solidity ^0.4.22;

 

 

contract ERC223ReceivingContract {
     
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
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

}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
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

 

 
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

contract SafeGuardsToken is CappedToken {

    string constant public name = "SafeGuards Coin";
    string constant public symbol = "SGCT";
    uint constant public decimals = 18;

     
    address public canBurnAddress;

     
    mapping (address => bool) public frozenList;

     
    uint256 public frozenPauseTime = now + 180 days;

     
    uint256 public burnPausedTime = now + 180 days;


    constructor(address _canBurnAddress) CappedToken(61 * 1e6 * 1e18) public {
        require(_canBurnAddress != 0x0);
        canBurnAddress = _canBurnAddress;
    }


     

    event ChangeFrozenPause(uint256 newFrozenPauseTime);

     
    function mintFrozen(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        frozenList[_to] = true;
        return super.mint(_to, _amount);
    }

    function changeFrozenTime(uint256 _newFrozenPauseTime) onlyOwner public returns (bool) {
        require(_newFrozenPauseTime > now);

        frozenPauseTime = _newFrozenPauseTime;
        emit ChangeFrozenPause(_newFrozenPauseTime);
        return true;
    }


     

    event Transfer(address indexed from, address indexed to, uint value, bytes data);

     
    function transfer(address _to, uint _value) public returns (bool) {
        bytes memory empty;
        return transfer(_to, _value, empty);
    }

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
        require(now > frozenPauseTime || !frozenList[msg.sender]);

        super.transfer(_to, _value);

        if (isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
            emit Transfer(msg.sender, _to, _value, _data);
        }

        return true;
    }

     
    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        bytes memory empty;
        return transferFrom(_from, _to, _value, empty);
    }

     
    function transferFrom(address _from, address _to, uint _value, bytes _data) public returns (bool) {
        require(now > frozenPauseTime || !frozenList[msg.sender]);

        super.transferFrom(_from, _to, _value);

        if (isContract(_to)) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(_from, _value, _data);
        }

        emit Transfer(_from, _to, _value, _data);
        return true;
    }

    function isContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
         
            length := extcodesize(_addr)
        }
        return (length>0);
    }


     

    event Burn(address indexed burner, uint256 value);
    event ChangeBurnPause(uint256 newBurnPauseTime);

     
    function burn(uint256 _value) public {
        require(burnPausedTime < now || msg.sender == canBurnAddress);

        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }

    function changeBurnPausedTime(uint256 _newBurnPauseTime) onlyOwner public returns (bool) {
        require(_newBurnPauseTime > burnPausedTime);

        burnPausedTime = _newBurnPauseTime;
        emit ChangeBurnPause(_newBurnPauseTime);
        return true;
    }
}

 

 

contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
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
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

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

 

 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    require(_openingTime >= now);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }
  
   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

 
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  constructor(uint256 _cap) public {
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

 

contract SafeGuardsPreSale is FinalizableCrowdsale, CappedCrowdsale {
    using SafeMath for uint256;

     
    uint256 public tokensSold;

     
    uint256 public minimumGoal;

     
    uint public loadedRefund;

     
    uint public weiRefunded;

     
    mapping (address => uint) public boughtAmountOf;

     
    uint256 constant public minimumAmountWei = 1e16;

     
    uint256 public presaleTransfersPaused = now + 180 days;

     
    uint256 public presaleBurnPaused = now + 180 days;

     

     
    uint constant public preSaleBonus1Time = 1535155200;  
    uint constant public preSaleBonus1Percent = 25;
    uint constant public preSaleBonus2Time = 1536019200;  
    uint constant public preSaleBonus2Percent = 15;
    uint constant public preSaleBonus3Time = 1536883200;  
    uint constant public preSaleBonus3Percent = 5;

     
    uint constant public preSaleBonus1Amount = 155   * 1e15;
    uint constant public preSaleBonus2Amount = 387   * 1e15;
    uint constant public preSaleBonus3Amount = 1550  * 1e15;
    uint constant public preSaleBonus4Amount = 15500 * 1e15;

     
    address constant public w_futureDevelopment = 0x4b297AB09bF4d2d8107fAa03cFF5377638Ec6C83;
    address constant public w_Reserv = 0xbb67c6E089c7801ab3c7790158868970ea0d8a7C;
    address constant public w_Founders = 0xa3b331037e29540F8BD30f3DE4fF4045a8115ff4;
    address constant public w_Team = 0xa8324689c94eC3cbE9413C61b00E86A96978b4A7;
    address constant public w_Advisers = 0x2516998954440b027171Ecb955A4C01DfF610F2d;
    address constant public w_Bounty = 0x1792b603F233220e1E623a6ab3FEc68deFa15f2F;


    event AddBonus(address indexed addr, uint256 amountWei, uint256 date, uint bonusType);

    struct Bonus {
        address addr;
        uint256 amountWei;
        uint256 date;
        uint bonusType;
    }

    struct Bonuses {
        address addr;
        uint256 numBonusesInAddress;
        uint256[] indexes;
    }

     
    mapping(address => Bonuses) public bonuses;

     
    Bonus[] public bonusList;

     
    function numBonuses() public view returns (uint256)
    { return bonusList.length; }

     
    function getBonusByAddressAndIndex(address _addr, uint256 _index) public view returns (uint256)
    { return bonuses[_addr].indexes[_index]; }


     
    constructor(
        uint256 _rate,
        address _wallet,
        ERC20 _token,
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _minimumGoal,
        uint256 _cap
    )
    Crowdsale(_rate * 1 ether, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    CappedCrowdsale(_cap * 1 ether)
    public
    {
        require(_rate > 0);
        require(_wallet != address(0));

        rate = _rate;
        wallet = _wallet;

        minimumGoal = _minimumGoal * 1 ether;
    }

     
    function changeTokenOwner(address _newTokenOwner) external onlyOwner {
        require(_newTokenOwner != 0x0);
        require(hasClosed());

        SafeGuardsToken(token).transferOwnership(_newTokenOwner);
    }

     
    function finalization() internal {
        require(isMinimumGoalReached());

        SafeGuardsToken(token).mint(w_futureDevelopment, tokensSold.mul(20).div(43));
        SafeGuardsToken(token).mint(w_Reserv, tokensSold.mul(20).div(43));
        SafeGuardsToken(token).mint(w_Founders, tokensSold.mul(7).div(43));
        SafeGuardsToken(token).mint(w_Team, tokensSold.mul(5).div(43));
        SafeGuardsToken(token).mint(w_Advisers, tokensSold.mul(3).div(43));
        SafeGuardsToken(token).mint(w_Bounty, tokensSold.mul(2).div(43));

        super.finalization();
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_weiAmount >= minimumAmountWei);

        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(SafeGuardsToken(token).mintFrozen(_beneficiary, _tokenAmount));
        tokensSold = tokensSold.add(_tokenAmount);
    }

    function changeTransfersPaused(uint256 _newFrozenPauseTime) onlyOwner public returns (bool) {
        require(_newFrozenPauseTime > now);

        presaleTransfersPaused = _newFrozenPauseTime;
        SafeGuardsToken(token).changeFrozenTime(_newFrozenPauseTime);
        return true;
    }

    function changeBurnPaused(uint256 _newBurnPauseTime) onlyOwner public returns (bool) {
        require(_newBurnPauseTime > presaleBurnPaused);

        presaleBurnPaused = _newBurnPauseTime;
        SafeGuardsToken(token).changeBurnPausedTime(_newBurnPauseTime);
        return true;
    }


     

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        require(_weiAmount >= minimumAmountWei);

        boughtAmountOf[msg.sender] = boughtAmountOf[msg.sender].add(_weiAmount);

        if (_weiAmount >= preSaleBonus1Amount) {
            if (_weiAmount >= preSaleBonus2Amount) {
                if (_weiAmount >= preSaleBonus3Amount) {
                    if (_weiAmount >= preSaleBonus4Amount) {
                        addBonusToUser(msg.sender, _weiAmount, preSaleBonus4Amount, 4);
                    } else {
                        addBonusToUser(msg.sender, _weiAmount, preSaleBonus3Amount, 3);
                    }
                } else {
                    addBonusToUser(msg.sender, _weiAmount, preSaleBonus2Amount, 2);
                }
            } else {
                addBonusToUser(msg.sender, _weiAmount, preSaleBonus1Amount, 1);
            }
        }
    }

    function addBonusToUser(address _addr, uint256 _weiAmount, uint256 _bonusAmount, uint _bonusType) internal {
        uint256 countBonuses = _weiAmount.div(_bonusAmount);

        Bonus memory b;
        b.addr = _addr;
        b.amountWei = _weiAmount;
        b.date = now;
        b.bonusType = _bonusType;

        for (uint256 i = 0; i < countBonuses; i++) {
            bonuses[_addr].addr = _addr;
            bonuses[_addr].numBonusesInAddress++;
            bonuses[_addr].indexes.push(bonusList.push(b) - 1);

            emit AddBonus(_addr, _weiAmount, now, _bonusType);
        }
    }

     
    function getCurrentRate() public view returns (uint256) {
        if (now > preSaleBonus3Time) {
            return rate;
        }

        if (now < preSaleBonus1Time) {
            return rate.add(rate.mul(preSaleBonus1Percent).div(100));
        }

        if (now < preSaleBonus2Time) {
            return rate.add(rate.mul(preSaleBonus2Percent).div(100));
        }

        if (now < preSaleBonus3Time) {
            return rate.add(rate.mul(preSaleBonus3Percent).div(100));
        }

        return rate;
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentRate = getCurrentRate();
        return currentRate.mul(_weiAmount);
    }


     

     
    event Refund(address buyer, uint weiAmount);
    event RefundLoaded(uint amount);

     
    function isMinimumGoalReached() public constant returns (bool) {
        return weiRaised >= minimumGoal;
    }

     
    function loadRefund() external payable {
        require(msg.sender == wallet);
        require(msg.value > 0);
        require(!isMinimumGoalReached());

        loadedRefund = loadedRefund.add(msg.value);

        emit RefundLoaded(msg.value);
    }

     
    function refund() external {
        require(!isMinimumGoalReached() && loadedRefund > 0);

        uint weiValue = boughtAmountOf[msg.sender];
        require(weiValue > 0);
        require(weiValue <= loadedRefund);

        boughtAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.add(weiValue);
        msg.sender.transfer(weiValue);

        emit Refund(msg.sender, weiValue);
    }
}