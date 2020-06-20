pragma solidity ^0.4.13;

contract ReentrancyGuard {

   
  bool private reentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
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

contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract DataWalletCrowdsale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

     
     
    uint256 public firstDayCap;
    uint256 public cap;
    uint256 public goal;
    uint256 public rate;
    uint256 public constant WEI_TO_INSIGHTS = 10**uint256(10);


    RefundVault public vault;
    DataWalletToken public token;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public firstDay;

    bool public isFinalized = false;
    uint256 public weiRaised;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public contribution;
    
    event WhitelistUpdate(address indexed purchaser, bool status);
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event TokenRefund(address indexed refundee, uint256 amount);

    event Finalized();
    

    function DataWalletCrowdsale(
        address _token, 
        address _wallet,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _cap,
        uint256 _firstDayCap,
        uint256 _goal
    ) {
        require(_startTime >= getBlockTimestamp());
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_goal > 0);
        require(_cap > 0);
        require(_wallet != 0x0);

        vault = new RefundVault(_wallet);
        token = DataWalletToken(_token);
        startTime = _startTime;
        endTime = _endTime;
        firstDay = startTime + 1 * 1 days;
        firstDayCap = _firstDayCap;
        rate = _rate;
        goal = _goal;
        cap = _cap;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) internal {
        require(beneficiary != 0x0);
        require(whitelist[beneficiary]);
        require(validPurchase());

         
        uint256 weiAmount = msg.value;

         
        if (getBlockTimestamp() <= firstDay) {
            require((contribution[beneficiary].add(weiAmount)) <= firstDayCap);
        }
         
        uint256 remainingToFund = cap.sub(weiRaised);
        if (weiAmount > remainingToFund) {
            weiAmount = remainingToFund;
        }
        uint256 weiToReturn = msg.value.sub(weiAmount);
         
        forwardFunds(weiAmount);
         
        if (weiToReturn > 0) {
            beneficiary.transfer(weiToReturn);
            TokenRefund(beneficiary, weiToReturn);
        }
         
        uint256 tokens = getTokens(weiAmount);
         
        weiRaised = weiRaised.add(weiAmount);
        contribution[beneficiary] = contribution[beneficiary].add(weiAmount);
     
         
        TokenPurchase(beneficiary, weiAmount, tokens);

        token.transfer(beneficiary, tokens); 
    }

    function getTokens(uint256 amount) internal constant returns (uint256) {
        return amount.mul(rate).div(WEI_TO_INSIGHTS);
    }

     
    function claimRefund() nonReentrant external {
        require(isFinalized);
        require(!goalReached());
        vault.refund(msg.sender);
    }

     
    function claimUnsold() onlyOwner {
        require(endTime <= getBlockTimestamp());
        uint256 unsold = token.balanceOf(this);

        if (unsold > 0) {
            require(token.transfer(msg.sender, unsold));
        }
    }

     
    function updateWhitelist(address[] addresses, bool status) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address contributorAddress = addresses[i];
            whitelist[contributorAddress] = status;
            WhitelistUpdate(contributorAddress, status);
        }
    }

     
    function finalize() onlyOwner {
        require(!isFinalized);
        require(hasEnded());

         
        isFinalized = true;
         
        Finalized();

        if (goalReached()) {
             
            vault.close();
             
            token.unpause();
             
            token.transferOwnership(owner);
        } else {
             
            vault.enableRefunds();
        }
    } 

     
    function forwardFunds(uint256 weiAmount) internal {
        vault.deposit.value(weiAmount)(msg.sender);
    }

     
    function hasEnded() public constant returns (bool) {
        bool passedEndTime = getBlockTimestamp() > endTime;
        return passedEndTime || capReached();
    }

    function capReached() public constant returns (bool) {
        return weiRaised >= cap;
    }

    function goalReached() public constant returns (bool) {
        return weiRaised >= goal;
    }

    function isWhitelisted(address contributor) public constant returns (bool) {
        return whitelist[contributor];
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = getBlockTimestamp() >= startTime && getBlockTimestamp() <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool capNotReached = weiRaised < cap;
        return withinPeriod && nonZeroPurchase && capNotReached;
    }

    function getBlockTimestamp() internal constant returns (uint256) {
        return block.timestamp;
    }
}

contract DataWalletToken is PausableToken, BurnableToken {

    string public constant name = "DataWallet Token";
    string public constant symbol = "DXT";
    uint8 public constant decimals = 8;
    uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**uint256(decimals);
    
     

    function DataWalletToken() public {
        totalSupply = INITIAL_SUPPLY;   
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function transfer(address beneficiary, uint256 amount) public returns (bool) {
        if (msg.sender != owner) {
            require(!paused);
        }
        require(beneficiary != address(0));
        require(amount <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[beneficiary] = balances[beneficiary].add(amount);
        Transfer(msg.sender, beneficiary, amount);
        return true;
    }
}