pragma solidity 0.4.20;


 
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


contract LongevityToken is StandardToken {
    string public name = "Longevity";
    string public symbol = "LTY";
    uint8 public decimals = 2;
    uint256 public cap = 2**256 - 1;  
    bool public mintingFinished = false;
    mapping (address => bool) owners;
    mapping (address => bool) minters;
     
    struct Tap {
        uint256 startTime;  
        uint256 tokensIssued;  
        uint256 mintSpeed;  
    }
    Tap public mintTap;
    bool public capFinalized = false;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);
    event MinterAdded(address indexed newMinter);
    event MinterRemoved(address indexed removedMinter);
    event Burn(address indexed burner, uint256 value);
    event MintTapSet(uint256 startTime, uint256 mintSpeed);
    event SetCap(uint256 currectTotalSupply, uint256 cap);

    function LongevityToken() public {
        owners[msg.sender] = true;
    }

     
    function mint(address _to, uint256 _amount) onlyMinter public returns (bool) {
        require(!mintingFinished);
        require(totalSupply.add(_amount) <= cap);
        passThroughTap(_amount);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwner public returns (bool) {
        require(!mintingFinished);
        mintingFinished = true;
        MintFinished();
        return true;
    }

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

     
    function addOwner(address _address) onlyOwner public {
        owners[_address] = true;
        OwnerAdded(_address);
    }

     
    function delOwner(address _address) onlyOwner public {
        owners[_address] = false;
        OwnerRemoved(_address);
    }

     
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

     
    function addMinter(address _address) onlyOwner public {
        minters[_address] = true;
        MinterAdded(_address);
    }

     
    function delMinter(address _address) onlyOwner public {
        minters[_address] = false;
        MinterRemoved(_address);
    }

     
    modifier onlyMinter() {
        require(minters[msg.sender]);
        _;
    }

     
    function passThroughTap(uint256 _tokensRequested) internal {
        require(_tokensRequested <= getTapRemaining());
        mintTap.tokensIssued = mintTap.tokensIssued.add(_tokensRequested);
    }

     
    function getTapRemaining() public view returns (uint256) {
        uint256 tapTime = now.sub(mintTap.startTime).add(1);
        uint256 totalTokensAllowed = tapTime.mul(mintTap.mintSpeed);
        uint256 tokensRemaining = totalTokensAllowed.sub(mintTap.tokensIssued);
        return tokensRemaining;
    }

     
    function setMintTap(uint256 _mintSpeed) onlyOwner public {
        mintTap.startTime = now;
        mintTap.tokensIssued = 0;
        mintTap.mintSpeed = _mintSpeed;
        MintTapSet(mintTap.startTime, mintTap.mintSpeed);
    }
     
    function setCap() onlyOwner public {
        require(!capFinalized);
        require(cap == 2**256 - 1);
        cap = totalSupply.mul(2);
        capFinalized = true;
        SetCap(totalSupply, cap);
    }
}


 
contract LongevityCrowdsale {
    using SafeMath for uint256;

     
    LongevityToken public token;

     
    mapping (address => bool) public owners;

     
    mapping (address => bool) public bots;

     
    mapping (address => bool) public cashiers;

     
    uint256 public rateUSDcETH;

     
    mapping (uint => Phase) phases;

     
    uint public totalPhases = 0;

     
    struct Phase {
        uint256 startTime;
        uint256 endTime;
        uint256 bonusPercent;
    }

     
    uint256 public constant minContributionUSDc = 1000;

    bool public finalized = false;

     
     
    uint256 public weiRaised;
    uint256 public USDcRaised;

     
    address[] public wallets;
    mapping (address => bool) inList;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 bonusPercent, uint256 amount);
    event OffChainTokenPurchase(address indexed beneficiary, uint256 tokensSold, uint256 USDcAmount);

     
    event RateUpdate(uint256 rate);

     
    event WalletAdded(address indexed wallet);
    event WalletRemoved(address indexed wallet);

     
    event OwnerAdded(address indexed newOwner);
    event OwnerRemoved(address indexed removedOwner);

     
    event BotAdded(address indexed newBot);
    event BotRemoved(address indexed removedBot);

     
    event CashierAdded(address indexed newBot);
    event CashierRemoved(address indexed removedBot);

     
    event TotalPhasesChanged(uint value);
    event SetPhase(uint index, uint256 _startTime, uint256 _endTime, uint256 _bonusPercent);
    event DelPhase(uint index);

    function LongevityCrowdsale(address _tokenAddress, uint256 _initialRate) public {
        require(_tokenAddress != address(0));
        token = LongevityToken(_tokenAddress);
        rateUSDcETH = _initialRate;
        owners[msg.sender] = true;
        bots[msg.sender] = true;
        phases[0].bonusPercent = 40;
        phases[0].startTime = 1520453700;
        phases[0].endTime = 1520460000;

        addWallet(msg.sender);
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(msg.value != 0);
        require(isInPhase(now));

        uint256 currentBonusPercent = getBonusPercent(now);

        uint256 weiAmount = msg.value;

        require(calculateUSDcValue(weiAmount) >= minContributionUSDc);

         
        uint256 tokens = calculateTokenAmount(weiAmount, currentBonusPercent);
        
        weiRaised = weiRaised.add(weiAmount);
        USDcRaised = USDcRaised.add(calculateUSDcValue(weiRaised));

        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, currentBonusPercent, tokens);

        forwardFunds();
    }

     
    function offChainPurchase(address beneficiary, uint256 tokensSold, uint256 USDcAmount) onlyCashier public {
        require(beneficiary != address(0));
        USDcRaised = USDcRaised.add(USDcAmount);
        token.mint(beneficiary, tokensSold);
        OffChainTokenPurchase(beneficiary, tokensSold, USDcAmount);
    }

     
     
    function getBonusPercent(uint256 datetime) public view returns (uint256) {
        require(isInPhase(datetime));
        for (uint i = 0; i < totalPhases; i++) {
            if (datetime >= phases[i].startTime && datetime <= phases[i].endTime) {
                return phases[i].bonusPercent;
            }
        }
    }

     
    function isInPhase(uint256 datetime) public view returns (bool) {
        for (uint i = 0; i < totalPhases; i++) {
            if (datetime >= phases[i].startTime && datetime <= phases[i].endTime) {
                return true;
            }
        }
    }

     
    function setRate(uint256 _rateUSDcETH) public onlyBot {
         
        assert(_rateUSDcETH < rateUSDcETH.mul(110).div(100));
        assert(_rateUSDcETH > rateUSDcETH.mul(90).div(100));
        rateUSDcETH = _rateUSDcETH;
        RateUpdate(rateUSDcETH);
    }

     
    function addOwner(address _address) onlyOwner public {
        owners[_address] = true;
        OwnerAdded(_address);
    }

     
    function delOwner(address _address) onlyOwner public {
        owners[_address] = false;
        OwnerRemoved(_address);
    }

     
    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

     
    function addBot(address _address) onlyOwner public {
        bots[_address] = true;
        BotAdded(_address);
    }

     
    function delBot(address _address) onlyOwner public {
        bots[_address] = false;
        BotRemoved(_address);
    }

     
    modifier onlyBot() {
        require(bots[msg.sender]);
        _;
    }

     
    function addCashier(address _address) onlyOwner public {
        cashiers[_address] = true;
        CashierAdded(_address);
    }

     
    function delCashier(address _address) onlyOwner public {
        cashiers[_address] = false;
        CashierRemoved(_address);
    }

     
    modifier onlyCashier() {
        require(cashiers[msg.sender]);
        _;
    }

     
    function calculateUSDcValue(uint256 _weiDeposit) public view returns (uint256) {

         
        uint256 weiPerUSDc = 1 ether/rateUSDcETH;

         
        uint256 depositValueInUSDc = _weiDeposit.div(weiPerUSDc);
        return depositValueInUSDc;
    }

     
     
    function calculateTokenAmount(uint256 _weiDeposit, uint256 _bonusTokensPercent) public view returns (uint256) {
        uint256 mainTokens = calculateUSDcValue(_weiDeposit);
        uint256 bonusTokens = mainTokens.mul(_bonusTokensPercent).div(100);
        return mainTokens.add(bonusTokens);
    }

     
    function forwardFunds() internal {
        uint256 value = msg.value / wallets.length;
        uint256 rest = msg.value - (value * wallets.length);
        for (uint i = 0; i < wallets.length - 1; i++) {
            wallets[i].transfer(value);
        }
        wallets[wallets.length - 1].transfer(value + rest);
    }

     
    function addWallet(address _address) onlyOwner public {
        require(!inList[_address]);
        wallets.push(_address);
        inList[_address] = true;
        WalletAdded(_address);
    }

     
    function setTotalPhases(uint value) onlyOwner public {
        totalPhases = value;
        TotalPhasesChanged(value);
    }

     
    function setPhase(uint index, uint256 _startTime, uint256 _endTime, uint256 _bonusPercent) onlyOwner public {
        require(index <= totalPhases);
        phases[index] = Phase(_startTime, _endTime, _bonusPercent);
        SetPhase(index, _startTime, _endTime, _bonusPercent);
    }

     
    function delPhase(uint index) onlyOwner public {
        require(index <= totalPhases);
        delete phases[index];
        DelPhase(index);
    }

     
    function delWallet(uint index) onlyOwner public {
        require(index < wallets.length);
        address remove = wallets[index];
        inList[remove] = false;
        for (uint i = index; i < wallets.length-1; i++) {
            wallets[i] = wallets[i+1];
        }
        wallets.length--;
        WalletRemoved(remove);
    }

     
    function getWalletsCount() public view returns (uint256) {
        return wallets.length;
    }

     
     
     
     
     
     
    function finalizeCrowdsale(address _teamAccount) onlyOwner public {
        require(!finalized);
        uint256 soldTokens = token.totalSupply();
        uint256 teamTokens = soldTokens.div(70).mul(30);
        token.mint(_teamAccount, teamTokens);
        token.setCap();
        finalized = true;
    }
}