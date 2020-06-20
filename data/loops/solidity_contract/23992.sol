pragma solidity 0.4.15;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract Authorizable is Ownable {
    event LogAccess(address authAddress);
    event Grant(address authAddress, bool grant);

    mapping(address => bool) public auth;

    modifier authorized() {
        LogAccess(msg.sender);
        require(auth[msg.sender]);
        _;
    }

    function authorize(address _address) onlyOwner public {
        Grant(_address, true);
        auth[_address] = true;
    }

    function unauthorize(address _address) onlyOwner public {
        Grant(_address, false);
        auth[_address] = false;
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
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 
contract TutellusToken is MintableToken {
   string public name = "Tutellus";
   string public symbol = "TUT";
   uint8 public decimals = 18;
}

 

contract TutellusLockerVault is Authorizable {
    event Deposit(address indexed _address, uint256 _amount);
    event Verify(address indexed _address);
    event Release(address indexed _address);

    uint256 releaseTime;
    TutellusToken token;

    mapping(address => uint256) public amounts;
    mapping(address => bool) public verified;

    function TutellusLockerVault(
        uint256 _releaseTime, 
        address _token
    ) public 
    {
        require(_releaseTime > now);
        require(_token != address(0));
        
        releaseTime = _releaseTime;
        token = TutellusToken(_token);
    }

    function verify(address _address) authorized public {
        require(_address != address(0));
        
        verified[_address] = true;
        Verify(_address);
    }

    function deposit(address _address, uint256 _amount) authorized public {
        require(_address != address(0));
        require(_amount > 0);

        amounts[_address] += _amount;
        Deposit(_address, _amount);
    }

    function release() public returns(bool) {
        require(now >= releaseTime);
        require(verified[msg.sender]);

        uint256 amount = amounts[msg.sender];
        if (amount > 0) {
            amounts[msg.sender] = 0;
            if (!token.transfer(msg.sender, amount)) {
                amounts[msg.sender] = amount;
                return false;
            }
            Release(msg.sender);
        }
        return true;
    }
}

 

contract TutellusVault is Authorizable {
    event VaultMint(address indexed authAddress);

    TutellusToken public token;

    function TutellusVault() public {
        token = new TutellusToken();
    }

    function mint(address _to, uint256 _amount) authorized public returns (bool) {
        require(_to != address(0));
        require(_amount >= 0);

        VaultMint(msg.sender);
        return token.mint(_to, _amount);
    }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

 
contract TutellusFixedCrowdsale is CappedCrowdsale, Pausable {
    event ConditionsAdded(address indexed beneficiary, uint256 rate);
    
    mapping(address => uint256) public conditions;

    uint256 specialLimit;  
    uint256 minPreICO;  

    TutellusVault vault;
    TutellusLockerVault locker;

    function TutellusFixedCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _cap,
        uint256 _rate,
        address _wallet,

        address _tutellusVault,
        address _lockerVault,
        uint256 _specialLimit,
        uint256 _minPreICO
    )
        CappedCrowdsale(_cap)
        Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        require(_tutellusVault != address(0));
        require(_lockerVault != address(0));

        vault = TutellusVault(_tutellusVault);
        token = MintableToken(vault.token());

        locker = TutellusLockerVault(_lockerVault);

        specialLimit = _specialLimit;
        minPreICO = _minPreICO;
    }

    function addSpecialRateConditions(address _address, uint256 _rate) public onlyOwner {
        require(_address != address(0));
        require(_rate > 0);

        conditions[_address] = _rate;
        ConditionsAdded(_address, _rate);
    }

    function buyTokens(address beneficiary) whenNotPaused public payable {
        require(beneficiary != address(0));
        require(msg.value >= minPreICO);
        require(validPurchase());

        uint256 senderRate;

        if (conditions[beneficiary] != 0) {
            require(msg.value >= specialLimit);
            senderRate = conditions[beneficiary];
        } else {
            senderRate = rate;
        }

        uint256 weiAmount = msg.value;
         
        uint256 tokens = weiAmount.mul(senderRate);
         
        weiRaised = weiRaised.add(weiAmount);

        locker.deposit(beneficiary, tokens);
        vault.mint(locker, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    function createTokenContract() internal returns (MintableToken) {}
}