pragma solidity ^0.4.18;

 
contract ERC20Basic {
  uint256 public totalSupply;

  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
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
}

 
contract SpendToken is StandardToken {
  string public constant name = "Spend Token";
  string public constant symbol = "SPEND";
  uint8 public constant decimals = 18;

  address public presale;
  address public team;

  uint public constant TOKEN_LIMIT = 50000000;

   
  function SpendToken(address _presale, address _team) public {
    require(_presale != address(0));
    require(_team != address(0));

    presale = _presale;
    team = _team;
  }

   
  function mint(address _holder, uint _value) external {
    require(msg.sender == presale);
    require(_value > 0);
    require(totalSupply + _value <= TOKEN_LIMIT);

    balances[_holder] += _value;
    totalSupply += _value;

    Transfer(0x0, _holder, _value);
  }
}

 
contract MoxyOnePresale {
  enum PreSaleState {
    PreSaleStarted,
    PreSaleFinished
  }

  SpendToken public token;
  PreSaleState public preSaleState = PreSaleState.PreSaleStarted;
  address public team;
  bool public isPaused = false;
  uint256 public pricePerToken = 1 ether / 1000;

  event PreSaleStarted();
  event PreSaleFinished();
  event PreSalePaused();
  event PreSaleResumed();
  event TokenBuy(address indexed buyer, uint256 tokens);

   
  modifier teamOnly {
    require(msg.sender == team);

    _;
  }

   
  function MoxyOnePresale() public {
    team = msg.sender;
    token = new SpendToken(this, team);
  }

   
  function pausePreSale() external teamOnly {
    require(!isPaused);
    require(preSaleState == PreSaleState.PreSaleStarted);

    isPaused = true;

    PreSalePaused();
  }

   
  function resumePreSale() external teamOnly {
    require(isPaused);
    require(preSaleState == PreSaleState.PreSaleStarted);

    isPaused = false;

    PreSaleResumed();
  }

   
  function finishPreSale() external teamOnly {
    require(preSaleState == PreSaleState.PreSaleStarted);

    preSaleState = PreSaleState.PreSaleFinished;

    PreSaleFinished();
  }

   
  function withdrawFunds(address _target, uint256 _amount) external teamOnly {
    _target.transfer(_amount);
  }

   
  function buyTokens(address _buyer, uint256 _value) internal returns (uint) {
    require(_buyer != address(0));
    require(_value > 0);
    require(preSaleState == PreSaleState.PreSaleStarted);
    require(!isPaused);

    uint256 boughtTokens = _value / pricePerToken;

    require(boughtTokens > 0);

    token.mint(_buyer, boughtTokens);

    TokenBuy(_buyer, boughtTokens);
  }

   
  function () external payable {
    buyTokens(msg.sender, msg.value);
  }
}