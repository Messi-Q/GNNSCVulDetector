pragma solidity ^0.4.18;


 
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

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
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

 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BitcoinusToken is ERC20, Ownable {
  using SafeMath for uint256;

  string public constant name = "Bitcoinus";
    string public constant symbol = "BITS";
    uint8 public constant decimals = 18;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  event Mint(address indexed to, uint256 amount);
    event MintFinished();

  bool public mintingFinished = false;

  modifier canTransfer() {
    require(mintingFinished);
    _;
  }

   
  function transfer(address _to, uint256 _value) public canTransfer returns (bool) {
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


   
  function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool) {
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

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
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

contract BitcoinusCrowdsale is Ownable {
  using SafeMath for uint256;
   
  address public constant WALLET = 0x3f39CD8a8Ae0540F0FD38aB695D36ceCf0f254E3;
   
  address public constant TEAM_WALLET = 0x35317879205E9fd59AeeC429b5494B84D8507C20;
   
  address public constant BOUNTY_WALLET = 0x088C48cA51A024909f06DF60597492492Eb66C2a;
   
  address public constant COMPANY_WALLET = 0x576B5cA75d4598dC31640F395F6201C5Dd0EbbB4;

  uint256 public constant TEAM_TOKENS = 4000000e18;
  uint256 public constant TEAM_TOKENS_LOCK_PERIOD = 60 * 60 * 24 * 365;  
  uint256 public constant COMPANY_TOKENS = 10000000e18;
  uint256 public constant COMPANY_TOKENS_LOCK_PERIOD = 60 * 60 * 24 * 180;  
  uint256 public constant BOUNTY_TOKENS = 1000000e18;
  uint256 public constant SOFT_CAP = 3000000e18;
  uint256 public constant ICO_TOKENS = 50000000e18;
  uint256 public constant START_TIME = 1516579200;  
  uint256 public constant END_TIME = 1525996800;  
  uint256 public constant RATE = 1000;
  uint256 public constant LARGE_PURCHASE = 1500e18;
  uint256 public constant LARGE_PURCHASE_BONUS = 5;

  Stage[] stages;

  struct Stage {
    uint256 till;
    uint256 cap;
    uint8 discount;
  }

   
  BitcoinusToken public token;

   
  uint256 public weiRaised;

   
    RefundVault public vault;

  uint256 public currentStage = 0;
    bool public isFinalized = false;

  address tokenMinter;

  TokenTimelock public teamTimelock;
  TokenTimelock public companyTimelock;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  event Finalized();
   
  event ManualTokenMintRequiresRefund(address indexed purchaser, uint256 value);

  function BitcoinusCrowdsale(address _token) public {
    stages.push(Stage({ till: 1519344000, discount: 47, cap: 8000000e18 }));  
    stages.push(Stage({ till: 1521849600, discount: 40, cap: 17000000e18 }));  
    stages.push(Stage({ till: 1523836800, discount: 30, cap: 15000000e18 }));  
    stages.push(Stage({ till: 1525219200, discount: 15, cap: 7000000e18 }));  
    stages.push(Stage({ till: 1525996800, discount: 5,  cap: 3000000e18 }));  

    token = BitcoinusToken(_token);
    vault = new RefundVault(WALLET);
    tokenMinter = msg.sender;
  }

  modifier onlyTokenMinterOrOwner() {
    require(msg.sender == tokenMinter || msg.sender == owner);
    _;
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 nowTime = getNow();
     
    while (currentStage < stages.length && stages[currentStage].till < nowTime) {
      stages[stages.length - 1].cap = stages[stages.length - 1].cap.add(stages[currentStage].cap);  
      stages[currentStage].cap = 0;
      currentStage = currentStage.add(1);
    }

     
    uint256 tokens = calculateTokens(weiAmount);

    uint256 excess = appendContribution(beneficiary, tokens);

    if (excess > 0) {  
      uint256 refund = excess.mul(weiAmount).div(tokens);
      weiAmount = weiAmount.sub(refund);
      msg.sender.transfer(refund);
    }

     
    weiRaised = weiRaised.add(weiAmount);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens.sub(excess));

    if (goalReached()) {
      WALLET.transfer(weiAmount);
    } else {
      vault.deposit.value(weiAmount)(msg.sender);
    }
  }

  function calculateTokens(uint256 _weiAmount) internal view returns (uint256) {
    uint256 tokens = _weiAmount.mul(RATE).mul(100).div(uint256(100).sub(stages[currentStage].discount));

    uint256 bonus = 0;
    if (currentStage > 0 && tokens >= LARGE_PURCHASE) {
      bonus = tokens.mul(LARGE_PURCHASE_BONUS).div(100);
    }

    return tokens.add(bonus);
  }

  function appendContribution(address _beneficiary, uint256 _tokens) internal returns (uint256) {
    uint256 excess = _tokens;
    uint256 tokensToMint = 0;

    while (excess > 0 && currentStage < stages.length) {
      Stage storage stage = stages[currentStage];
      if (excess >= stage.cap) {
        excess = excess.sub(stage.cap);
        tokensToMint = tokensToMint.add(stage.cap);
        stage.cap = 0;
        currentStage = currentStage.add(1);
      } else {
        stage.cap = stage.cap.sub(excess);
        tokensToMint = tokensToMint.add(excess);
        excess = 0;
      }
    }
    token.mint(_beneficiary, tokensToMint);
    return excess;
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = getNow() >= START_TIME && getNow() <= END_TIME;
    bool nonZeroPurchase = msg.value != 0;
    bool canMint = token.totalSupply() < ICO_TOKENS;
    bool validStage = (currentStage < stages.length);
    return withinPeriod && nonZeroPurchase && canMint && validStage;
  }

   
    function claimRefund() public {
      require(isFinalized);
      require(!goalReached());

      vault.refund(msg.sender);
  }

   
    function finalize() onlyOwner public {
      require(!isFinalized);
      require(hasEnded());

      if (goalReached()) {
      vault.close();

      teamTimelock = new TokenTimelock(token, TEAM_WALLET, getNow().add(TEAM_TOKENS_LOCK_PERIOD));
      token.mint(teamTimelock, TEAM_TOKENS);

      companyTimelock = new TokenTimelock(token, COMPANY_WALLET, getNow().add(COMPANY_TOKENS_LOCK_PERIOD));
      token.mint(companyTimelock, COMPANY_TOKENS);

      token.mint(BOUNTY_WALLET, BOUNTY_TOKENS);

      token.finishMinting();
      token.transferOwnership(0x1);
      } else {
          vault.enableRefunds();
      }

      Finalized();

      isFinalized = true;
    }

   
  function hasEnded() public view returns (bool) {
    return getNow() > END_TIME || token.totalSupply() == ICO_TOKENS;
  }

    function goalReached() public view returns (bool) {
      return token.totalSupply() >= SOFT_CAP;
    }

     
    function () external payable {
      if (!isFinalized) {
        buyTokens(msg.sender);
    } else {
      claimRefund();
      }
    }

    function mintTokens(address[] _receivers, uint256[] _amounts) external onlyTokenMinterOrOwner {
    require(_receivers.length > 0 && _receivers.length <= 100);
    require(_receivers.length == _amounts.length);
    require(!isFinalized);
    for (uint256 i = 0; i < _receivers.length; i++) {
      address receiver = _receivers[i];
      uint256 amount = _amounts[i];

        require(receiver != address(0));
        require(amount > 0);

        uint256 excess = appendContribution(receiver, amount);

        if (excess > 0) {
          ManualTokenMintRequiresRefund(receiver, excess);
        }
    }
    }

    function setTokenMinter(address _tokenMinter) public onlyOwner {
      require(_tokenMinter != address(0));
      tokenMinter = _tokenMinter;
    }

  function getNow() internal view returns (uint256) {
    return now;
  }
}