pragma solidity ^0.4.21;

 

 
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

contract SintToken is BurnableToken, CappedToken {

    event TransfersUnlocked();
    event Timelock(address indexed beneficiary, uint256 releaseTime);

    string public constant name = "Sint Token";
    string public constant symbol = "SIN";
    uint8 public constant decimals = 18;

    mapping (address => uint256) private lockedUntil;  

    bool public lockedTransfers = true;

    function SintToken(
        uint256 _cap
    )
        public
        CappedToken(_cap.mul(1 ether))
    {
         
    }

    modifier whenLockedTransfers() {
        require(lockedTransfers);
        _;
    }

    modifier whenUnlockedTransfers(address _sender) {
        require(!lockedTransfers);
        require(lockedUntil[_sender] < now, "Timelock");  
        _;
    }

    function unlockTransfers()
        onlyOwner
        whenLockedTransfers
        public
    {
        lockedTransfers = false;
        emit TransfersUnlocked();
    }

    function timelock(address _beneficiary, uint256 _releaseTime)
        onlyOwner
        whenLockedTransfers
        public
        returns (bool)
    {
        lockedUntil[_beneficiary] = _releaseTime;
        emit Timelock(_beneficiary, _releaseTime);
        return true;
    }

    function transfer(address _to, uint256 _value)
        whenUnlockedTransfers(msg.sender)
        public
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
        whenUnlockedTransfers(_from)
        public
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

}

 

 

contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
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
    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

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

 

 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  function CappedCrowdsale(uint256 _cap) public {
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

 

 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }

   
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
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

 

contract SintCrowdsale is CappedCrowdsale, TimedCrowdsale, MintedCrowdsale, Ownable {

    uint256 public constant minAmount = 0.1 ether;

     
    uint256[3] internal bonusEndDates = [
        1525687140,  
        1526291940,  
        1526896740  
    ];

    uint8[3] internal bonusPercentages = [
        30,
        20,
        10
    ];

    address[8] internal advisorWallets = [
        0x542A625Ab5182Af9219B92A723e0B937a5edDCa5,  
        0xBd8DD5e35C9935fCB48B7575FbF1A25FC3BD0dCd,  
        0xb5C51Ca28cbb7F07a8123275C3b51319588E767d,  
        0x31F9961B4b42221680C3d86eA08761E4E121f231,  
        0x8164876957be1bF660b81419421B16641af19dF9,  
        0x3e2eDBE3cC53f5105D8451D73846de47B38931f6,  
        0xcacc29637Ca90bC49F0aeD017C1eFCa50E0C2951,  
        0xc7F218965226391B89e7aEC7c10dafF384Eee7C7  
    ];

    address internal teamWallet = 0x78f1C69DcB99A5038e511e6f42F40ABd6bFA4d2a;

    function SintCrowdsale(
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _rate,
        address _wallet,
        SintToken _token,
        uint256 _cap
    )
        public
        Crowdsale(_rate, _wallet, _token)
        CappedCrowdsale(_cap.mul(1 ether))
        TimedCrowdsale(_openingTime, _closingTime)
    {
        require(bonusEndDates.length == bonusPercentages.length);
        require(advisorWallets.length > 0);
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
    {
        require(_weiAmount >= minAmount);
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    function _getCurrentBonus()
        internal
        view
        returns (uint8)
    {
        for (uint8 i = 0; i < bonusEndDates.length; i++)
        {
            if (bonusEndDates[i] > now)
            {
                return 100 + bonusPercentages[i];
            }
        }

        return 100;
    }

    function _getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        uint8 currentBonus = _getCurrentBonus();
        return _weiAmount.mul(rate).mul(currentBonus).div(100);
    }

    function distributeTeamTokens()
        onlyOwner
        public
    {
        require(hasClosed());

        uint256 tokenCap = CappedToken(token).cap();

         
         
        uint256 advisorAllowance = tokenCap.mul(3).div(100).div(advisorWallets.length);
        for (uint8 i = 0; i < advisorWallets.length; i++)
        {
            require(MintableToken(token).mint(advisorWallets[i], advisorAllowance));
        }

         
         
        uint256 teamAllowance = tokenCap.mul(6).div(100);
        require(MintableToken(token).mint(teamWallet, teamAllowance));
        require(SintToken(token).timelock(teamWallet, closingTime + 60 * 60 * 24 * 365 * 2));
    }

    function transferTokenOwnership(address newOwner)
        onlyOwner
        public
    {
        SintToken(token).transferOwnership(newOwner);
    }

}