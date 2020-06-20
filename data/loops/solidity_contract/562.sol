pragma solidity ^0.4.24;

contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Ownable {

   
  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnerChanged(owner, _newOwner);
    owner = _newOwner;
  }

  event OwnerChanged(address indexed previousOwner,address indexed newOwner);

}

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract Stoppable is Ownable {
    
     
    bool public stopped = false;

     
    bool public withdrawalEnabled = false;

     
    modifier whenStopped() {
        require(stopped);
        _;
    }

     
    modifier whenNotStopped() {
        require(!stopped);
        _;
    }

    modifier whenWithdrawalEnabled() {
        require(withdrawalEnabled);
        _;
    }

    modifier whenWithdrawalDisabled() {
        require(!withdrawalEnabled);
        _;
    }

     
    function stop() public onlyOwner whenNotStopped {
        stopped = true;
        emit Stopped(owner);
    }

     
    function restart() public onlyOwner whenStopped {
        stopped = false;
        withdrawalEnabled = false;
        emit Restarted(owner);
    }

     
    function enableWithdrawal() public onlyOwner whenStopped whenWithdrawalDisabled {
        withdrawalEnabled = true;
        emit WithdrawalEnabled(owner);
    }

     
    function disableWithdrawal() public onlyOwner whenWithdrawalEnabled {
        withdrawalEnabled = false;
        emit WithdrawalDisabled(owner);
    }

     
    event Stopped(address owner);
    
     
    event Restarted(address owner);

     
    event WithdrawalEnabled(address owner);
    
     
    event WithdrawalDisabled(address owner);
}

contract Whitelist {

     
    address public whitelister;

     
    mapping (address => bool) whitelist;

     
    constructor() public {
        whitelister = msg.sender;
    }

     
    modifier onlyWhitelister() {
        require(msg.sender == whitelister);
        _;
    }

     
    function addToWhitelist(address _address) public onlyWhitelister {
        require(_address != address(0));
        emit WhitelistAdd(whitelister, _address);
        whitelist[_address] = true;
    }
    
     
    function removeFromWhitelist(address _address) public onlyWhitelister {
        require(_address != address(0));
        emit WhitelistRemove(whitelister, _address);
        whitelist[_address] = false;
    }

     
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

     
    function changeWhitelister(address _newWhitelister) public onlyWhitelister {
        require(_newWhitelister != address(0));
        emit WhitelisterChanged(whitelister, _newWhitelister);
        whitelister = _newWhitelister;
    }

     
    event WhitelisterChanged(address indexed previousWhitelister, address indexed newWhitelister);
    
     
    event WhitelistAdd(address indexed whitelister, address indexed whitelistedAddress);
     
    event WhitelistRemove(address indexed whitelister, address indexed whitelistedAddress); 
}

contract ElpisCrowdsale is Stoppable, Whitelist {
    using SafeMath for uint256;

     
    ERC20 public token;

     
    address public wallet;

     
    mapping (address => uint256) public ethBalances;

     
    mapping (address => uint256) public elpBalances;

     
    uint256 public rate;

     
    uint256 public threshold;

     
    uint256 public weiRaised;

     
    uint256 public usdRaised;

     
    uint256 public tokensSold;

     
    uint256 public cap;

     
    uint256 public deploymentBlock;

     
    uint256 public constant AMOUNT_PER_PHASE = 14500000 ether;

     
    constructor(uint256 _rate, uint256 _threshold, uint256 _cap, ERC20 _token, address _wallet) public {
        require(_rate > 0);
        require(_threshold > 0);
        require(_cap > 0);
        require(_token != address(0));
        require(_wallet != address(0));

        rate = _rate;
        threshold = _threshold;
        cap = _cap;
        token = _token;
        wallet = _wallet;
        deploymentBlock = block.number;
    }

     
    function setRate(uint256 _rate) public onlyOwner {
        emit RateChanged(owner, rate, _rate);
        rate = _rate;
    }

     
    function setThreshold(uint256 _threshold) public onlyOwner {
        emit ThresholdChanged(owner, threshold, _threshold);
        threshold = _threshold;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable whenNotStopped {
        uint256 weiAmount = msg.value;
        require(_beneficiary != address(0));
        require(weiAmount != 0);
        weiRaised = weiRaised.add(weiAmount);
        require(weiRaised <= cap);

        uint256 dollars = _getUsdAmount(weiAmount);
        uint256 tokens = _getTokenAmount(dollars);

         
        uint256 previousEthBalance = ethBalances[_beneficiary];
        ethBalances[_beneficiary] = ethBalances[_beneficiary].add(weiAmount);
        elpBalances[_beneficiary] = elpBalances[_beneficiary].add(tokens);
        tokensSold = tokensSold.add(tokens);
        usdRaised = usdRaised.add(dollars);

        if (ethBalances[_beneficiary] > threshold) {
            whitelist[_beneficiary] = false;
             
             
            if (previousEthBalance < threshold)
                wallet.transfer(threshold - previousEthBalance);
            emit NeedKyc(_beneficiary, weiAmount, ethBalances[_beneficiary]);
        } else {
            whitelist[_beneficiary] = true;
             
             
            wallet.transfer(weiAmount);
            emit Contribution(_beneficiary, weiAmount, ethBalances[_beneficiary]);
        }

        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    }

     
    function withdraw() external whenWithdrawalEnabled {
        uint256 ethBalance = ethBalances[msg.sender];
        require(ethBalance > 0);
        uint256 elpBalance = elpBalances[msg.sender];

         
        elpBalances[msg.sender] = 0;
        ethBalances[msg.sender] = 0;

        if (isWhitelisted(msg.sender)) {
             
            token.transfer(msg.sender, elpBalance);
        } else {
             
            token.transfer(msg.sender, elpBalance.mul(threshold).div(ethBalance));

            if (ethBalance > threshold) {
                 
                 
                msg.sender.transfer(ethBalance - threshold);
            }
        }
        emit Withdrawal(msg.sender, ethBalance, elpBalance);
    }

     
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(token));
        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20 tokenReference = ERC20(_token);
        uint balance = tokenReference.balanceOf(address(this));
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }

     
    function _getTokenAmount(uint256 _usdAmount) internal view returns (uint256) {
        uint256 phase = getPhase();
        uint256 initialPriceNumerator = 110;
        uint256 initialPriceDenominator = 1000;

        uint256 scaleNumerator = 104 ** phase;
        uint256 scaleDenominator = 100 ** phase;

        return _usdAmount.mul(initialPriceNumerator).mul(scaleNumerator).div(initialPriceDenominator).div(scaleDenominator);
    }

     
    function _getUsdAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }

     
    function getPhase() public view returns (uint256) {
        return tokensSold / AMOUNT_PER_PHASE;
    }

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    event RateChanged(address indexed owner, uint256 oldValue, uint256 newValue);

     
    event ThresholdChanged(address indexed owner, uint256 oldValue, uint256 newValue);

     
    event Contribution(address indexed beneficiary, uint256 contributionAmount, uint256 totalAmount);

     
    event NeedKyc(address indexed beneficiary, uint256 contributionAmount, uint256 totalAmount);

     
    event Withdrawal(address indexed beneficiary, uint256 ethBalance, uint256 elpBalance);

     
    event ClaimedTokens(address indexed token, address indexed owner, uint256 amount);
}