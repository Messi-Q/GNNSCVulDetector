pragma solidity ^0.4.21;

 

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

   
  function balanceOf(address _owner) public view returns (uint256) {
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

 

contract HoldToken is MintableToken {
    using SafeMath for uint256;

    string public name = 'HOLD';
    string public symbol = 'HOLD';
    uint8 public decimals = 18;

    event Burn(address indexed burner, uint256 value);
    event BurnTransferred(address indexed previousBurner, address indexed newBurner);

    address burnerRole;

    modifier onlyBurner() {
        require(msg.sender == burnerRole);
        _;
    }

    function HoldToken(address _burner) public {
        burnerRole = _burner;
    }

    function transferBurnRole(address newBurner) public onlyBurner {
        require(newBurner != address(0));
        BurnTransferred(burnerRole, newBurner);
        burnerRole = newBurner;
    }

    function burn(uint256 _value) public onlyBurner {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0), _value);
    }
}

 

 
contract Crowdsale {
    using SafeMath for uint256;

     
    HoldToken public token;

     
    uint256 public startTime;
    uint256 public endTime;

    uint256 public rate;

     
    address public wallet;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed beneficiary, uint256 indexed value, uint256 indexed amount, uint256 transactionId);


    function Crowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        uint256 _initialWeiRaised
    ) public {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_wallet != address(0));
        require(_rate > 0);

        token = new HoldToken(_wallet);
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
        weiRaised = _initialWeiRaised;
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }
}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 

 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
     
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
     
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

 

contract CappedCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    uint256 public hardCap;
    uint256 public tokensToLock;
    uint256 public releaseTime;
    bool public isFinalized = false;
    TokenTimelock public timeLock;

    event Finalized();
    event FinishMinting();
    event TokensMinted(
        address indexed beneficiary,
        uint256 indexed amount
    );

    function CappedCrowdsale(uint256 _hardCap, uint256 _tokensToLock, uint256 _releaseTime) public {
        require(_hardCap > 0);
        require(_tokensToLock > 0);
        require(_releaseTime > endTime);
        hardCap = _hardCap;
        releaseTime = _releaseTime;
        tokensToLock = _tokensToLock;

        timeLock = new TokenTimelock(token, wallet, releaseTime);
    }

     
    function finalize() onlyOwner public {
        require(!isFinalized);

        token.mint(address(timeLock), tokensToLock);

        Finalized();
        isFinalized = true;
    }

    function finishMinting() onlyOwner public {
        require(token.mintingFinished() == false);
        require(isFinalized);
        token.finishMinting();

        FinishMinting();
    }

    function mint(address beneficiary, uint256 amount) onlyOwner public {
        require(!token.mintingFinished());
        require(isFinalized);
        require(amount > 0);
        require(beneficiary != address(0));
        token.mint(beneficiary, amount);

        TokensMinted(beneficiary, amount);
    }

     
     
    function hasEnded() public view returns (bool) {
        bool capReached = weiRaised >= hardCap;
        return super.hasEnded() || capReached || isFinalized;
    }

}

 

contract OnlyWhiteListedAddresses is Ownable {
    using SafeMath for uint256;
    address utilityAccount;
    mapping (address => bool) whitelist;
    mapping (address => address) public referrals;

    modifier onlyOwnerOrUtility() {
        require(msg.sender == owner || msg.sender == utilityAccount);
        _;
    }

    event WhitelistedAddresses(
        address[] users
    );

    event ReferralsAdded(
        address[] user,
        address[] referral
    );

    function OnlyWhiteListedAddresses(address _utilityAccount) public {
        utilityAccount = _utilityAccount;
    }

    function whitelistAddress (address[] users) public onlyOwnerOrUtility {
        for (uint i = 0; i < users.length; i++) {
            whitelist[users[i]] = true;
        }
        WhitelistedAddresses(users);
    }

    function addAddressReferrals (address[] users, address[] _referrals) public onlyOwnerOrUtility {
        require(users.length == _referrals.length);
        for (uint i = 0; i < users.length; i++) {
            require(isWhiteListedAddress(users[i]));

            referrals[users[i]] = _referrals[i];
        }
        ReferralsAdded(users, _referrals);
    }

    function isWhiteListedAddress (address addr) public view returns (bool) {
        return whitelist[addr];
    }
}

 

contract HoldCrowdsale is CappedCrowdsale, OnlyWhiteListedAddresses {
    using SafeMath for uint256;

    struct TokenPurchaseRecord {
        uint256 timestamp;
        uint256 weiAmount;
        address beneficiary;
    }

    uint256 transactionId = 1;

    mapping (uint256 => TokenPurchaseRecord) pendingTransactions;
    mapping (uint256 => bool) completedTransactions;

    uint256 public referralPercentage;
    uint256 public individualCap;

     
    event TokenPurchaseRequest(
        uint256 indexed transactionId,
        address beneficiary,
        uint256 indexed timestamp,
        uint256 indexed weiAmount,
        uint256 tokensAmount
    );

    event ReferralTokensSent(
        address indexed beneficiary,
        uint256 indexed tokensAmount,
        uint256 indexed transactionId
    );

    event BonusTokensSent(
        address indexed beneficiary,
        uint256 indexed tokensAmount,
        uint256 indexed transactionId
    );

    function HoldCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _icoHardCapWei,
        uint256 _referralPercentage,
        uint256 _rate,
        address _wallet,
        uint256 _tokensToLock,
        uint256 _releaseTime,
        uint256 _privateWeiRaised,
        uint256 _individualCap,
        address _utilityAccount
    ) public
    OnlyWhiteListedAddresses(_utilityAccount)
    CappedCrowdsale(_icoHardCapWei, _tokensToLock, _releaseTime)
    Crowdsale(_startTime, _endTime, _rate, _wallet, _privateWeiRaised)
    {
        referralPercentage = _referralPercentage;
        individualCap = _individualCap;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(!isFinalized);
        require(beneficiary == msg.sender);
        require(msg.value != 0);
        require(msg.value >= individualCap);

        uint256 weiAmount = msg.value;
        require(isWhiteListedAddress(beneficiary));
        require(validPurchase(weiAmount));

         
        weiRaised = weiRaised.add(weiAmount);

        uint256 _transactionId = transactionId;
        uint256 tokensAmount = weiAmount.mul(rate);

        pendingTransactions[_transactionId] = TokenPurchaseRecord(now, weiAmount, beneficiary);
        transactionId += 1;


        TokenPurchaseRequest(_transactionId, beneficiary, now, weiAmount, tokensAmount);
        forwardFunds();
    }

    function issueTokensMultiple(uint256[] _transactionIds, uint256[] bonusTokensAmounts) public onlyOwner {
        require(isFinalized);
        require(_transactionIds.length == bonusTokensAmounts.length);
        for (uint i = 0; i < _transactionIds.length; i++) {
            issueTokens(_transactionIds[i], bonusTokensAmounts[i]);
        }
    }

    function issueTokens(uint256 _transactionId, uint256 bonusTokensAmount) internal {
        require(completedTransactions[_transactionId] != true);
        require(pendingTransactions[_transactionId].timestamp != 0);

        TokenPurchaseRecord memory record = pendingTransactions[_transactionId];
        uint256 tokens = record.weiAmount.mul(rate);
        address referralAddress = referrals[record.beneficiary];

        token.mint(record.beneficiary, tokens);
        TokenPurchase(record.beneficiary, record.weiAmount, tokens, _transactionId);

        completedTransactions[_transactionId] = true;

        if (bonusTokensAmount != 0) {
            require(bonusTokensAmount != 0);
            token.mint(record.beneficiary, bonusTokensAmount);
            BonusTokensSent(record.beneficiary, bonusTokensAmount, _transactionId);
        }

        if (referralAddress != address(0)) {
            uint256 referralAmount = tokens.mul(referralPercentage).div(uint256(100));
            token.mint(referralAddress, referralAmount);
            ReferralTokensSent(referralAddress, referralAmount, _transactionId);
        }
    }

    function validPurchase(uint256 weiAmount) internal view returns (bool) {
        bool withinCap = weiRaised.add(weiAmount) <= hardCap;
        bool withinCrowdsaleInterval = now >= startTime && now <= endTime;
        return withinCrowdsaleInterval && withinCap;
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

 

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function Migrations() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}