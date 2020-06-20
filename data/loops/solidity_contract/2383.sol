pragma solidity ^0.4.24;


 
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


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
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


 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
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


contract LittlePhilCoin is MintableToken, PausableToken {
    string public name = "Little Phil Coin";
    string public symbol = "LPC";
    uint8 public decimals = 18;

    constructor () public {
         
        pause();
    }

}


 
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
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
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}


 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
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

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}


 
contract TokenCappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public tokenCap = 0;

     
    uint256 public tokensRaised = 0;

     
    event CapOverflow(address sender, uint256 weiAmount, uint256 receivedTokens);

     
    function capReached() public view returns (bool) {
        return tokensRaised >= tokenCap;
    }

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        super._updatePurchasingState(_beneficiary, _weiAmount);
        uint256 purchasedTokens = _getTokenAmount(_weiAmount);
        tokensRaised = tokensRaised.add(purchasedTokens);

        if (capReached()) {
             
            emit CapOverflow(_beneficiary, _weiAmount, purchasedTokens);
        }
    }

}


 
contract TieredCrowdsale is TokenCappedCrowdsale, Ownable {

    using SafeMath for uint256;

     
    enum SaleState { 
        Initial,               
        PrivateSale,           
        FinalisedPrivateSale,  
        PreSale,               
        FinalisedPreSale,      
        PublicSaleTier1,       
        PublicSaleTier2,       
        PublicSaleTier3,       
        PublicSaleTier4,       
        FinalisedPublicSale,   
        Closed                 
    }
    SaleState public state = SaleState.Initial;

    struct TierConfig {
        string stateName;
        uint256 tierRatePercentage;
        uint256 hardCap;
    }

    mapping(bytes32 => TierConfig) private tierConfigs;

     
    event IncrementTieredState(string stateName);

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(
            state == SaleState.PrivateSale ||
            state == SaleState.PreSale ||
            state == SaleState.PublicSaleTier1 ||
            state == SaleState.PublicSaleTier2 ||
            state == SaleState.PublicSaleTier3 ||
            state == SaleState.PublicSaleTier4
        );
    }

     
    constructor() public {
         
        createSalesTierConfigMap();
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentTierRate = getCurrentTierRatePercentage();

        uint256 requestedTokenAmount = _weiAmount.mul(rate).mul(currentTierRate).div(100);

        uint256 remainingTokens = tokenCap.sub(tokensRaised);

         
        if (requestedTokenAmount > remainingTokens) {
            return remainingTokens;
        }

        return requestedTokenAmount;
    }

     
    function createSalesTierConfigMap() private {

        tierConfigs [keccak256(SaleState.Initial)] = TierConfig({
            stateName: "Initial",
            tierRatePercentage: 0,
            hardCap: 0
        });
        tierConfigs [keccak256(SaleState.PrivateSale)] = TierConfig({
            stateName: "PrivateSale",
            tierRatePercentage: 100,
            hardCap: SafeMath.mul(400000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.FinalisedPrivateSale)] = TierConfig({
            stateName: "FinalisedPrivateSale",
            tierRatePercentage: 0,
            hardCap: 0
        });
        tierConfigs [keccak256(SaleState.PreSale)] = TierConfig({
            stateName: "PreSale",
            tierRatePercentage: 140,
            hardCap: SafeMath.mul(180000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.FinalisedPreSale)] = TierConfig({
            stateName: "FinalisedPreSale",
            tierRatePercentage: 0,
            hardCap: 0
        });
        tierConfigs [keccak256(SaleState.PublicSaleTier1)] = TierConfig({
            stateName: "PublicSaleTier1",
            tierRatePercentage: 130,
            hardCap: SafeMath.mul(265000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.PublicSaleTier2)] = TierConfig({
            stateName: "PublicSaleTier2",
            tierRatePercentage: 120,
            hardCap: SafeMath.mul(330000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.PublicSaleTier3)] = TierConfig({
            stateName: "PublicSaleTier3",
            tierRatePercentage: 110,
            hardCap: SafeMath.mul(375000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.PublicSaleTier4)] = TierConfig({
            stateName: "PublicSaleTier4",
            tierRatePercentage: 100,
            hardCap: SafeMath.mul(400000000, (10 ** 18))
        });
        tierConfigs [keccak256(SaleState.FinalisedPublicSale)] = TierConfig({
            stateName: "FinalisedPublicSale",
            tierRatePercentage: 0,
            hardCap: 0
        });
        tierConfigs [keccak256(SaleState.Closed)] = TierConfig({
            stateName: "Closed",
            tierRatePercentage: 0,
            hardCap: SafeMath.mul(400000000, (10 ** 18))
        });
        

    }

     
    function getCurrentTierRatePercentage() public view returns (uint256) {
        return tierConfigs[keccak256(state)].tierRatePercentage;
    }

     
    function getCurrentTierHardcap() public view returns (uint256) {
        return tierConfigs[keccak256(state)].hardCap;
    }

     
    function setState(uint256 _state) onlyOwner public {
        state = SaleState(_state);

         
        tokenCap = getCurrentTierHardcap();

        if (state == SaleState.Closed) {
            crowdsaleClosed();
        }
    }

    function getState() public view returns (string) {
        return tierConfigs[keccak256(state)].stateName;
    }

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        super._updatePurchasingState(_beneficiary, _weiAmount);

        if (capReached()) {
            if (state == SaleState.PrivateSale) {
                state = SaleState.FinalisedPrivateSale;
            }
            else if (state == SaleState.PreSale) {
                state = SaleState.FinalisedPreSale;
            }
            else if (state == SaleState.PublicSaleTier1) {
                state = SaleState.PublicSaleTier2;
            }
            else if (state == SaleState.PublicSaleTier2) {
                state = SaleState.PublicSaleTier3;
            }
            else if (state == SaleState.PublicSaleTier3) {
                state = SaleState.PublicSaleTier4;
            }
            else if (state == SaleState.PublicSaleTier4) {
                state = SaleState.FinalisedPublicSale;
            } else {
                return;
            }

            tokenCap = getCurrentTierHardcap();
            emit IncrementTieredState(getState());
        }

    }

     
    function crowdsaleClosed() internal {
         
    }

}

 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
     
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

contract InitialSupplyCrowdsale is Crowdsale, Ownable {

    using SafeMath for uint256;

    uint256 public constant decimals = 18;

     
    address public companyWallet;
    address public teamWallet;
    address public projectWallet;
    address public advisorWallet;
    address public bountyWallet;
    address public airdropWallet;

     
    TokenTimelock public teamTimeLock1;
    TokenTimelock public teamTimeLock2;

     
    uint256 public constant companyTokens    = SafeMath.mul(150000000, (10 ** decimals));
    uint256 public constant teamTokens       = SafeMath.mul(150000000, (10 ** decimals));
    uint256 public constant projectTokens    = SafeMath.mul(150000000, (10 ** decimals));
    uint256 public constant advisorTokens    = SafeMath.mul(100000000, (10 ** decimals));
    uint256 public constant bountyTokens     = SafeMath.mul(30000000, (10 ** decimals));
    uint256 public constant airdropTokens    = SafeMath.mul(20000000, (10 ** decimals));

    bool private isInitialised = false;

    constructor(
        address[6] _wallets
    ) public {
        address _companyWallet  = _wallets[0];
        address _teamWallet     = _wallets[1];
        address _projectWallet  = _wallets[2];
        address _advisorWallet  = _wallets[3];
        address _bountyWallet   = _wallets[4];
        address _airdropWallet  = _wallets[5];

        require(_companyWallet != address(0));
        require(_teamWallet != address(0));
        require(_projectWallet != address(0));
        require(_advisorWallet != address(0));
        require(_bountyWallet != address(0));
        require(_airdropWallet != address(0));

         
        companyWallet = _companyWallet;
        teamWallet = _teamWallet;
        projectWallet = _projectWallet;
        advisorWallet = _advisorWallet;
        bountyWallet = _bountyWallet;
        airdropWallet = _airdropWallet;

         
        teamTimeLock1 = new TokenTimelock(token, teamWallet, uint64(now + 182 days));
        teamTimeLock2 = new TokenTimelock(token, teamWallet, uint64(now + 365 days));
    }

     
    function setupInitialSupply() internal onlyOwner {
        require(isInitialised == false);
        uint256 teamTokensSplit = teamTokens.mul(50).div(100);

         
        LittlePhilCoin(token).mint(companyWallet, companyTokens);
        LittlePhilCoin(token).mint(projectWallet, projectTokens);
        LittlePhilCoin(token).mint(advisorWallet, advisorTokens);
        LittlePhilCoin(token).mint(bountyWallet, bountyTokens);
        LittlePhilCoin(token).mint(airdropWallet, airdropTokens);
        LittlePhilCoin(token).mint(address(teamTimeLock1), teamTokensSplit);
        LittlePhilCoin(token).mint(address(teamTimeLock2), teamTokensSplit);

        isInitialised = true;
    }

}

 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    emit Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}



contract TokenVestingCrowdsale is Crowdsale, Ownable {

    function addBeneficiaryVestor(
            address beneficiaryWallet, 
            uint256 tokenAmount, 
            uint256 vestingEpocStart, 
            uint256 cliffInSeconds, 
            uint256 vestingEpocEnd
        ) external onlyOwner {
        TokenVesting newVault = new TokenVesting(
            beneficiaryWallet, 
            vestingEpocStart, 
            cliffInSeconds, 
            vestingEpocEnd, 
            false
        );
        LittlePhilCoin(token).mint(address(newVault), tokenAmount);
    }

    function releaseVestingTokens(address vaultAddress) external onlyOwner {
        TokenVesting(vaultAddress).release(token);
    }

}


 
 

contract WhitelistedCrowdsale is Crowdsale, Ownable {

    address public whitelister;
    mapping(address => bool) public whitelist;

    constructor(address _whitelister) public {
        require(_whitelister != address(0));
        whitelister = _whitelister;
    }

    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }

    function addToWhitelist(address _beneficiary) public onlyOwnerOrWhitelister {
        whitelist[_beneficiary] = true;
    }

    function addManyToWhitelist(address[] _beneficiaries) public onlyOwnerOrWhitelister {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    function removeFromWhitelist(address _beneficiary) public onlyOwnerOrWhitelister {
        whitelist[_beneficiary] = false;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    modifier onlyOwnerOrWhitelister() {
        require(msg.sender == owner || msg.sender == whitelister);
        _;
    }
}

 
contract LittlePhilCrowdsale is MintedCrowdsale, TieredCrowdsale, InitialSupplyCrowdsale, TokenVestingCrowdsale, WhitelistedCrowdsale {

     
    event NewRate(uint256 rate);

     
    constructor(
        uint256 _rate,
        address _fundsWallet,
        address[6] _wallets,
        LittlePhilCoin _token,
        address _whitelister
    ) public
    Crowdsale(_rate, _fundsWallet, _token)
    InitialSupplyCrowdsale(_wallets) 
    WhitelistedCrowdsale(_whitelister){}

     
    function setupInitialState() external onlyOwner {
        setupInitialSupply();
    }

     
    function transferTokenOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
         
        LittlePhilCoin(token).transferOwnership(_newOwner);
    }

     
    function crowdsaleClosed() internal {
        uint256 remainingTokens = tokenCap.sub(tokensRaised);
        _deliverTokens(airdropWallet, remainingTokens);
        LittlePhilCoin(token).finishMinting();
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(_weiAmount >= 500000000000000000);
    }

     
    function setRate(uint256 _rate) public onlyOwner {
        require(_rate > 0);
        rate = _rate;
        emit NewRate(rate);
    }

      
    function mintForPrivateFiat(address _beneficiary, uint256 _weiAmount) public onlyOwner {
        _preValidatePurchase(_beneficiary, _weiAmount);

         
        uint256 tokens = _getTokenAmount(_weiAmount);

         
        weiRaised = weiRaised.add(_weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
            msg.sender,
            _beneficiary,
            _weiAmount,
            tokens
        );

        _updatePurchasingState(_beneficiary, _weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, _weiAmount);
    }

}