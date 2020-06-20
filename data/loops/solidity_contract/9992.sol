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


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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


contract WhiteListedBasic {
    function addWhiteListed(address[] addrs) external;
    function removeWhiteListed(address addr) external;
    function isWhiteListed(address addr) external view returns (bool);
}

contract OperatableBasic {
    function setMinter (address addr) external;
    function setWhiteLister (address addr) external;
}

contract Operatable is Claimable, OperatableBasic {
    address public minter;
    address public whiteLister;
    address public launcher;

    event NewMinter(address newMinter);
    event NewWhiteLister(address newwhiteLister);

    modifier canOperate() {
        require(msg.sender == minter || msg.sender == whiteLister || msg.sender == owner);
        _;
    }

    constructor() public {
        minter = owner;
        whiteLister = owner;
        launcher = owner;
    }

    function setMinter (address addr) external onlyOwner {
        minter = addr;
        emit NewMinter(minter);
    }

    function setWhiteLister (address addr) external onlyOwner {
        whiteLister = addr;
        emit NewWhiteLister(whiteLister);
    }

    modifier ownerOrMinter()  {
        require ((msg.sender == minter) || (msg.sender == owner));
        _;
    }

    modifier onlyLauncher()  {
        require (msg.sender == launcher);
        _;
    }

    modifier onlyWhiteLister()  {
        require (msg.sender == whiteLister);
        _;
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


contract WhiteListed is Operatable, WhiteListedBasic, Salvageable {


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

    function isWhiteListed(address addr) external view returns (bool) {
        return whiteList[addr];
    }
}
contract GoConfig {
    string public constant NAME = "GOeureka";
    string public constant SYMBOL = "GOT";
    uint8 public constant DECIMALS = 18;
    uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);
    uint public constant TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
}

contract GOeureka is  Salvageable, PausableToken, GoConfig {
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

    constructor() public {
        paused = true;
    }

    function mint(address _to, uint _amount) ownerOrMinter canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= TOTALSUPPLY);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() ownerOrMinter canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function sendBatchCS(address[] _recipients, uint[] _values) external ownerOrMinter returns (bool) {
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

     

       
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes _data
    )
    public
    payable
    whenNotPaused
    returns (bool)
    {
        require(_to != address(this));

        super.transfer(_to, _value);

         
        require(_to.call.value(msg.value)(_data));
        return true;
    }


}


contract gotTokenSaleConfig is GoConfig {
    uint public constant MIN_PRESALE = 10 ether;

    uint public constant VESTING_AMOUNT = 100000000 * DECIMALSFACTOR;
    address public constant VESTING_WALLET = 0xf0cf34Be9cAB4354b228193FF4F6A2C61DdE95f4;   
        
    uint public constant RESERVE_AMOUNT = 300000000 * DECIMALSFACTOR;
    address public constant RESERVE_WALLET = 0x83Fee7D53b6A5B5fD0d60b772c2B56b02D8835da;  

    uint public constant PRESALE_START = 1529035246;  
    uint public constant SALE_START = PRESALE_START + 4 weeks;
        
    uint public constant SALE_CAP = 600000000 * DECIMALSFACTOR;

    address public constant MULTISIG_ETH = RESERVE_WALLET;

}

contract GOeurekaSale is Claimable, gotTokenSaleConfig, Pausable, Salvageable {
    using SafeMath for uint256;

     
    GOeureka public token;

    WhiteListedBasic public whiteListed;

     
    uint256 public presaleStart;
    uint256 public presaleEnd;

    uint256 public week1Start;
    uint256 public week1End;
    uint256 public week2End;
    uint256 public week3End;

     
    uint256 public presaleCap;
    uint256 public week1Cap;
    uint256 public week2Cap;
    uint256 public week3Cap;

     
    uint256 public minContribution;

    uint public currentCap;
     

     
    address public multiSig;

     
    uint256 public weiRaised;

     
    uint256 public tokensRaised;

     
    mapping(address => uint256) public contributions;
    uint256 public numberOfContributors = 0;

     
    uint public basicRate;
 
     

    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
    event SaleClosed();
    event HardcapReached();
    event NewCapActivated(uint256 newCap);

 
     

    constructor(GOeureka token_, WhiteListedBasic _whiteListed) public {
        calcDates(PRESALE_START, SALE_START);  

        basicRate = 3000;   
        calculateRates();

        
        multiSig = MULTISIG_ETH;

         
        token = token_;

        whiteListed = _whiteListed;
    }

    bool allocated = false;
    function mintAllocations() external onlyOwner {
        require(!allocated);
        allocated = true;
        token.mint(VESTING_WALLET,VESTING_AMOUNT);
        token.mint(RESERVE_WALLET,RESERVE_AMOUNT);
    }

    function setDates(uint presaleStart_, uint saleStart) external onlyOwner {
        calcDates(presaleStart_, saleStart);
    }

    function calcDates(uint presaleStart_, uint saleStart) internal {
        require(weiRaised == 0);
        require(now < presaleStart_);
        require(presaleStart_ < saleStart);
        presaleStart = presaleStart_;
        week1Start = saleStart;

        presaleEnd = saleStart; 

        week1End = week1Start + 1 weeks;
        week2End = week1Start + 2 weeks; 
        week3End = week1Start + 4 weeks;
    }

    function setWallet(address _newWallet) public onlyOwner {
        multiSig = _newWallet;
    } 


     
    function hasEnded() public view returns (bool) {
        if (now > week3End)
            return true;
        if (tokensRaised >= SALE_CAP)
            return true;  
        return false;
    }

     
    function isWhiteListed(address beneficiary) internal view returns (bool) {
        return whiteListed.isWhiteListed(beneficiary);
    }

    modifier onlyAuthorised(address beneficiary) {
        require(isWhiteListed(beneficiary),"Not authorised");
        require (now >= presaleStart,"too early");
        require (!hasEnded(),"ended");
        require (multiSig != 0x0,"MultiSig empty");
        require ((msg.value > minContribution) || (weiRaised.add(minContribution) > week3Cap),"Value too small");
        _;
    }

    function setNewRate(uint newRate) onlyOwner public {
        require(weiRaised == 0);
        require(0 < newRate && newRate < 5000);
        basicRate = newRate;
        calculateRates();
    }

    function calculateRates() internal {
        presaleCap =              uint(150000000 * DECIMALSFACTOR).div(basicRate);
        week1Cap = presaleCap.add(uint(100000000 * DECIMALSFACTOR).div(basicRate));
        week2Cap = week1Cap.add(uint(100000000 * DECIMALSFACTOR).div(basicRate));
        week3Cap = week2Cap.add(uint(200000000 * DECIMALSFACTOR).div(basicRate));
        minContribution = uint(100 * DECIMALSFACTOR).div(basicRate);
        currentCap = presaleCap;
    }


    function getTokens(uint256 amountInWei) 
    internal
    view
    returns (uint256 tokens, uint256 currentCap_)
    {
        if ((now < week1Start) && (weiRaised < presaleCap)) {
            require(amountInWei.add(contributions[msg.sender]) >= MIN_PRESALE);  
            return (amountInWei.mul(basicRate).mul(115).div(100), presaleCap);
        }
        if ((now <= week1End) && (weiRaised < week1Cap)) {
            return (amountInWei.mul(basicRate).mul(110).div(100), week1Cap);
        }
        if ((now <= week2End) && (weiRaised < week2Cap)) {
            return (amountInWei.mul(basicRate).mul(105).div(100), week2Cap);
        }
        if ((now <= week3End) && (weiRaised < week3Cap)) { 
            return (amountInWei.mul(basicRate), week3Cap);
        }
        revert();
    }

  
     
    function buyTokens(address beneficiary, uint256 value)
        internal
        onlyAuthorised(beneficiary) 
        whenNotPaused
    {
        uint256 newTokens;
        uint256 newestTokens;
        uint256 thisPhase = value;
        uint256 nextPhase = 0;
        uint256 refund = 0;

        if (weiRaised.add(value) > currentCap) {  
            thisPhase = currentCap.sub(weiRaised);
            nextPhase = value.sub(thisPhase);
        }
        (newTokens, currentCap) = getTokens(thisPhase);
        weiRaised = weiRaised.add(thisPhase);
         
        if (nextPhase > 0) {
            if (weiRaised.add(nextPhase) <= week3Cap) {  
                weiRaised = weiRaised.add(nextPhase);
                (newestTokens, currentCap) = getTokens(nextPhase);
                newTokens = newTokens.add(newestTokens);
                emit NewCapActivated(currentCap);
            } else {  
                refund = nextPhase;
                nextPhase = 0;
                emit HardcapReached();
            }
        }
        if (contributions[beneficiary] == 0) {
            numberOfContributors++;
        }
        contributions[beneficiary] = contributions[beneficiary].add(thisPhase).add(nextPhase);
        tokensRaised = tokensRaised.add(newTokens);
        token.mint(beneficiary,newTokens);
        emit TokenPurchase(beneficiary, thisPhase.add(nextPhase), newTokens);
        multiSig.transfer(thisPhase.add(nextPhase));
        if (refund > 0) {
            beneficiary.transfer(refund);
        }
    }

    function placeTokens(address beneficiary, uint256 tokens) 
        public       
        onlyOwner
    {
        require(now < presaleStart);
        tokensRaised = tokensRaised.add(tokens);
        token.mint(beneficiary,tokens);
    }


     
    function finishSale() public onlyOwner {
        require(hasEnded());
        token.finishMinting();
        emit SaleClosed();
    }

     
    function () public payable {
        buyTokens(msg.sender, msg.value);
    }

}