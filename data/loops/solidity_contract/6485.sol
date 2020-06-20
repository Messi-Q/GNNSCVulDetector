pragma solidity ^0.4.23;
 
 
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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

contract REDTTokenConfig {
    string public constant NAME = "Real Estate Doc Token";
    string public constant SYMBOL = "REDT";
    uint8 public constant DECIMALS = 18;
    uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);
    uint public constant TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

contract Operatable is Claimable {
    address public minter;
    address public whiteLister;
    address public launcher;

    modifier canOperate() {
        require(msg.sender == minter || msg.sender == whiteLister || msg.sender == owner);
        _;
    }

    constructor() public {
        minter = owner;
        whiteLister = owner;
        launcher = owner;
    }

    function setMinter (address addr) public onlyOwner {
        minter = addr;
    }

    function setWhiteLister (address addr) public onlyOwner {
        whiteLister = addr;
    }

    modifier onlyMinter()  {
        require (msg.sender == minter);
        _;
    }

    modifier onlyLauncher()  {
        require (msg.sender == minter);
        _;
    }

    modifier onlyWhiteLister()  {
        require (msg.sender == whiteLister);
        _;
    }
}
contract REDTTokenSaleConfig is REDTTokenConfig {
    uint public constant MIN_CONTRIBUTION      = 100 finney;

    

    

    

    uint public constant SALE_START = 1537189200;
    uint public constant SALE_END = 1540990800;
    
    uint public constant SALE0_END = 1537794000;
    uint public constant SALE0_RATE = 24000;
    uint public constant SALE0_CAP = 400000000 * DECIMALSFACTOR;
    
    uint public constant SALE1_END = 1538398800;
    uint public constant SALE1_RATE = 22000;
    uint public constant SALE1_CAP = 500000000 * DECIMALSFACTOR;
    
    uint public constant SALE2_END = 1540990800;
    uint public constant SALE2_RATE = 20000;
    uint public constant SALE2_CAP = 500000000 * DECIMALSFACTOR;
    
    uint public constant SALE_CAP = 500000000 * DECIMALSFACTOR;

    address public constant MULTISIG_ETH = 0x25C7A30F23a107ebF430FDFD582Afe1245B690Af;
    address public constant MULTISIG_TKN = 0x25C7A30F23a107ebF430FDFD582Afe1245B690Af;

}
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract WhiteListed is Operatable {


    uint public count;
    mapping (address => bool) public whiteList;

    event Whitelisted(address indexed addr, uint whitelistedCount, bool isWhitelisted);

    function addWhiteListed(address[] addrs) external canOperate {
        uint c = count;
        for (uint i = 0; i < addrs.length; i++) {
            if (!whiteList[addrs[i]]) {
                whiteList[addrs[i]] = true;
                c++;
                emit Whitelisted(addrs[i], count, true);
            }
        }
        count = c;
    }

    function removeWhiteListed(address addr) external canOperate {
        require(whiteList[addr]);
        whiteList[addr] = false;
        count--;
        emit Whitelisted(addr, count, false);
    }

}
contract Salvageable is Operatable {
     
    function emergencyERC20Drain(ERC20 oddToken, uint amount) public onlyLauncher {
        if (address(oddToken) == address(0)) {
            launcher.transfer(amount);
            return;
        }
        oddToken.transfer(launcher, amount);
    }
}
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract REDTToken is PausableToken, REDTTokenConfig, Salvageable {
    using SafeMath for uint;

    string public name = NAME;
    string public symbol = SYMBOL;
    uint8 public decimals = DECIMALS;
    bool public mintingFinished = false;

    event Mint(address indexed to, uint amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    constructor(address launcher_) public {
        launcher = launcher_;
        paused = true;
    }

    function mint(address _to, uint _amount) canMint onlyMinter public returns (bool) {
        require(totalSupply_.add(_amount) <= TOTALSUPPLY);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function sendBatchCS(address[] _recipients, uint[] _values) external canOperate returns (bool) {
        require(_recipients.length == _values.length);
        uint senderBalance = balances[msg.sender];
        for (uint i = 0; i < _values.length; i++) {
            uint value = _values[i];
            address to = _recipients[i];
            require(senderBalance >= value);        
            senderBalance = senderBalance - value;
            balances[to] += value;
            emit Transfer(msg.sender, to, value);
        }
        balances[msg.sender] = senderBalance;
        return true;
    }

}
contract REDTTokenSale is REDTTokenSaleConfig, Claimable, Pausable, Salvageable {
    using SafeMath for uint;
    bool public isFinalized = false;
    REDTToken public token;
    
    uint public tokensRaised;           
    uint public weiRaised;               
    WhiteListed public whiteListed;
    uint public numContributors;         

    mapping (address => uint) public contributions;  

    event Finalized();
    event TokenPurchase(address indexed beneficiary, uint value, uint amount);
    event TokenPresale(address indexed purchaser, uint amount);

    constructor( WhiteListed _whiteListed ) public {
        
        require(now < SALE_START);
        
        require(_whiteListed != address(0));
        
        whiteListed = _whiteListed;

        token = new REDTToken(owner);
    }

    function getRateAndCheckCap() public view returns (uint) {
        
        require(now>SALE_START);
        
        if ((now<SALE0_END) && (tokensRaised < SALE0_CAP))
            return SALE0_RATE;
        
        if ((now<SALE1_END) && (tokensRaised < SALE1_CAP))
            return SALE1_RATE;
        
        if ((now<SALE2_END) && (tokensRaised < SALE2_CAP))
            return SALE2_RATE;
        
        revert();
    }

     
    function () external payable {
        buyTokens(msg.sender, msg.value);
    }

    function buyTokens(address beneficiary, uint weiAmount) internal whenNotPaused {
        require(whiteListed.whiteList(beneficiary));
        require((weiAmount > MIN_CONTRIBUTION) || (weiAmount == SALE_CAP.sub(MIN_CONTRIBUTION)));

        weiRaised = weiRaised.add(weiAmount);
        uint tokens = weiAmount.mul(getRateAndCheckCap());

        if (contributions[beneficiary] == 0) {
            numContributors++;
        }

        contributions[beneficiary] = contributions[beneficiary].add(weiAmount);
        token.mint(beneficiary, tokens);
        emit TokenPurchase(beneficiary, weiAmount, tokens);
        forwardFunds();
    }

    function placeTokens(address beneficiary, uint256 numtokens) 
    public
	  onlyOwner
    {
        
        require(now < SALE_START);
        
        tokensRaised = tokensRaised.add(numtokens);
        token.mint(beneficiary,numtokens);
    }


    function tokensUnsold() public view returns(uint) {
        return token.TOTALSUPPLY().sub(token.totalSupply());
    }

     
    function hasEnded() public view returns (bool) {
        return ((now > SALE_END) || (tokensRaised >= SALE_CAP));
    }

     
    function forwardFunds() internal {
        
        MULTISIG_ETH.transfer(address(this).balance);
    }

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

     
    function finalization() internal {
        
        token.mint(MULTISIG_TKN,tokensUnsold());
        
        token.finishMinting();
        token.transferOwnership(owner);
    }
}