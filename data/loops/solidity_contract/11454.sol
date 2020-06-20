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

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
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
  







 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
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



 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
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


 
contract StandardBurnableToken is BurnableToken, StandardToken {

   
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
     
     
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
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
  
  
  

interface CrowdsaleContract {
  function isActive() public view returns(bool);
}

contract BulleonToken is StandardBurnableToken, PausableToken, Claimable, CanReclaimToken {
   
  event AddedToWhitelist(address wallet);
  event RemoveWhitelist(address wallet);

   
  string public constant name = "Bulleon";  
  string public constant symbol = "BUL";  
  uint8 public constant decimals = 18;  
  uint256 constant exchangersBalance = 39991750231582759746295 + 14715165984103328399573 + 1846107707643607869274;  

   
  address constant premineWallet = 0x286BE9799488cA4543399c2ec964e7184077711C;
  uint256 constant premineAmount = 178420 * (10 ** uint256(decimals));

   
  address public CrowdsaleAddress;
  CrowdsaleContract crowdsale;
  mapping(address=>bool) whitelist;  

   
  constructor() public {
    totalSupply_ = 7970000 * (10 ** uint256(decimals));
    balances[msg.sender] = totalSupply_;
    transfer(premineWallet, premineAmount.add(exchangersBalance));

    addToWhitelist(msg.sender);
    addToWhitelist(premineWallet);
    paused = true;  
  }

   
  function setCrowdsaleAddress(address _ico) public onlyOwner {
    CrowdsaleAddress = _ico;
    crowdsale = CrowdsaleContract(CrowdsaleAddress);
    addToWhitelist(CrowdsaleAddress);
  }

   
  function pause() onlyOwner whenNotPaused public {
    revert();
  }

   
  modifier whenNotPaused() {
    require(!paused || whitelist[msg.sender]);
    _;
  }

   
  function unpause() whenPaused public {
    require(!crowdsale.isActive() || msg.sender == owner);  
    paused = false;
    emit Unpause();
  }

   
  function addToWhitelist(address wallet) public onlyOwner {
    require(!whitelist[wallet]);
    whitelist[wallet] = true;
    emit AddedToWhitelist(wallet);
  }

   
  function delWhitelist(address wallet) public onlyOwner {
    require(whitelist[wallet]);
    whitelist[wallet] = false;
    emit RemoveWhitelist(wallet);
  }

   
  function kill() onlyOwner {
    selfdestruct(owner);
  }
}



contract BulleonCrowdsale is Claimable, CanReclaimToken {
    using SafeMath for uint256;
     
    event AddedToBlacklist(address wallet);
    event RemovedFromBlacklist(address wallet);

     
    string public version = "2.0";

     
    address public withdrawWallet = 0xAd74Bd38911fE4C19c95D14b5733372c3978C2D9;
    uint256 public endDate = 1546300799;  
    BulleonToken public rewardToken;
     
    uint256[] public tokensRate = [
      1000,  
      800,  
      600,  
      400,  
      200,  
      100,  
      75,  
      50,  
      25,  
      10  
    ];
     
    uint256[] public tokensCap = [
      760000,  
      760000,  
      760000,  
      760000,  
      760000,  
      760000,  
      760000,  
      760000,  
      760000,  
      759000   
    ];
    mapping(address=>bool) public isBlacklisted;

     
    uint256 public totalSold = 329406072304513072322000;  
    uint256 public soldOnStage = 329406072304513072322000;  
    uint8 public currentStage = 0;

     
    uint256 public bonus = 0;
    uint256 constant BONUS_COEFF = 1000;  
    mapping(address=>uint256) public investmentsOf;  

    
    function isActive() public view returns (bool) {
      return !(availableTokens() == 0 || now > endDate);
    }

     

     
    function stageCap() public view returns(uint256) {
      return tokensCap[currentStage].mul(1 ether);
    }

     
    function availableOnStage() public view returns(uint256) {
        return stageCap().sub(soldOnStage) > availableTokens() ? availableTokens() : stageCap().sub(soldOnStage);
    }

     
    function stageBaseRate() public view returns(uint256) {
      return tokensRate[currentStage];
    }

     
    function stageRate() public view returns(uint256) {
      return stageBaseRate().mul(BONUS_COEFF.add(getBonus())).div(BONUS_COEFF);
    }

    constructor(address token) public {
        require(token != 0x0);
        rewardToken = BulleonToken(token);
    }

    function () public payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
      bool validPurchase = beneficiary != 0x0 && msg.value != 0 && !isBlacklisted[msg.sender];
      uint256 currentTokensAmount = availableTokens();
       
      require(isActive() && validPurchase);
      investmentsOf[msg.sender] = investmentsOf[msg.sender].add(msg.value);
      uint256 boughtTokens;
      uint256 refundAmount = 0;

       
      uint256[2] memory tokensAndRefund = calcMultiStage();
      boughtTokens = tokensAndRefund[0];
      refundAmount = tokensAndRefund[1];
       
      require(boughtTokens <= currentTokensAmount);

      totalSold = totalSold.add(boughtTokens);  

      if(soldOnStage >= stageCap()) {
        toNextStage();
      }

      rewardToken.transfer(beneficiary, boughtTokens);

      if (refundAmount > 0)
          refundMoney(refundAmount);

      withdrawFunds(this.balance);
    }

     
    function forceWithdraw() public onlyOwner {
      withdrawFunds(this.balance);
    }

     
    function calcMultiStage() internal returns(uint256[2]) {
      uint256 stageBoughtTokens;
      uint256 undistributedAmount = msg.value;
      uint256 _boughtTokens = 0;
      uint256 undistributedTokens = availableTokens();

      while(undistributedAmount > 0 && undistributedTokens > 0) {
        bool needNextStage = false;

        stageBoughtTokens = getTokensAmount(undistributedAmount);

        if (stageBoughtTokens > availableOnStage()) {
          stageBoughtTokens = availableOnStage();
          needNextStage = true;
        }

        _boughtTokens = _boughtTokens.add(stageBoughtTokens);
        undistributedTokens = undistributedTokens.sub(stageBoughtTokens);
        undistributedAmount = undistributedAmount.sub(getTokensCost(stageBoughtTokens));
        soldOnStage = soldOnStage.add(stageBoughtTokens);
        if (needNextStage)
          toNextStage();
      }
      return [_boughtTokens,undistributedAmount];
    }

     
    function setWithdraw(address _withdrawWallet) public onlyOwner {
        require(_withdrawWallet != 0x0);
        withdrawWallet = _withdrawWallet;
    }

     
    function refundMoney(uint256 refundAmount) internal {
      msg.sender.transfer(refundAmount);
    }

     
    function burnTokens(uint256 amount) public onlyOwner {
      rewardToken.burn(amount);
    }

     
    function getTokensCost(uint256 _tokensAmount) public view returns(uint256) {
      return _tokensAmount.div(stageRate());
    }

    function getTokensAmount(uint256 _amountInWei) public view returns(uint256) {
      return _amountInWei.mul(stageRate());
    }



     
    function toNextStage() internal {
        if (
          currentStage < tokensRate.length &&
          currentStage < tokensCap.length
        ) {
          currentStage++;
          soldOnStage = 0;
        }
    }

    function availableTokens() public view returns(uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function withdrawFunds(uint256 amount) internal {
        withdrawWallet.transfer(amount);
    }

    function kill() public onlyOwner {
      require(!isActive());  
      rewardToken.burn(availableTokens());  
      selfdestruct(owner);  
    }

    function setBonus(uint256 bonusAmount) public onlyOwner {
      require(
        bonusAmount < 100 * BONUS_COEFF &&
        bonusAmount >= 0
      );
      bonus = bonusAmount;
    }

    function getBonus() public view returns(uint256) {
      uint256 _bonus = bonus;
      uint256 investments = investmentsOf[msg.sender];
      if(investments > 50 ether)
        _bonus += 250;  
      else
      if(investments > 20 ether)
        _bonus += 200;  
      else
      if(investments > 10 ether)
        _bonus += 150;  
      else
      if(investments > 5 ether)
        _bonus += 100;  
      else
      if(investments > 1 ether)
        _bonus += 50;  

      return _bonus;
    }

    function addBlacklist(address wallet) public onlyOwner {
      require(!isBlacklisted[wallet]);
      isBlacklisted[wallet] = true;
      emit AddedToBlacklist(wallet);
    }

    function delBlacklist(address wallet) public onlyOwner {
      require(isBlacklisted[wallet]);
      isBlacklisted[wallet] = false;
      emit RemovedFromBlacklist(wallet);
    }
    
}