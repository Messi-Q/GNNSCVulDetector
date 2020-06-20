pragma solidity ^0.4.15;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract StandardToken is ERC20Basic {

  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }


   
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

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}


 

contract MintableToken is BurnableToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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

}

 
contract GESToken is MintableToken, PausableToken {
  string public constant name = "Galaxy eSolutions";
  string public constant symbol = "GES";
  uint8 public constant decimals = 18;
}

 

contract GESTokenCrowdSale is Ownable {
  using SafeMath for uint256;

   
  bool public isFinalised;

   
  MintableToken public token;

   
  uint256 public mainSaleStartTime;
  uint256 public mainSaleEndTime;

   
  address public wallet;

   
  address public tokenWallet;

   
  uint256 public rate = 10000;

   
   
    
   
  uint256 public weiRaised = 1280109986123700000000 ;

   

   
  uint256 public saleMinimumWei = 100000000000000000; 
  
   
  uint256 public hardCap = 20000000000000000000000; 
  
   
   
   
   
  uint256 public tokensToSell = 216405356 * 10 ** 18; 

   
   struct AmountBonus {
    uint256 amount;
    uint percent;
  }
  AmountBonus[] public amountBonuses;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event FinalisedCrowdsale(uint256 totalSupply);

  function GESTokenCrowdSale(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime, address _wallet, address _tokenWallet) public {

     
    require(_mainSaleStartTime >= now);
     
    require(_mainSaleEndTime >= _mainSaleStartTime);

     
    require(_wallet != 0x0);
    require(_tokenWallet != 0x0);

     
    token = createTokenContract();
    
    amountBonuses.push(AmountBonus(    50000000000000000000, 20));
    amountBonuses.push(AmountBonus(   100000000000000000000, 25));
    amountBonuses.push(AmountBonus(   250000000000000000000, 30));
    amountBonuses.push(AmountBonus(   500000000000000000000, 35));
    amountBonuses.push(AmountBonus(  1000000000000000000000, 40));
    amountBonuses.push(AmountBonus(  2500000000000000000000, 45));
    amountBonuses.push(AmountBonus(200000000000000000000000, 50));


    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;

    wallet = msg.sender ;
    tokenWallet = msg.sender;

    isFinalised = false;

     
     
     
     
     
    token.mint(tokenWallet, 83594644 * 10 ** 18);
  }

   
  function createTokenContract() internal returns (MintableToken) {
    return new GESToken();
  }

   
  function () public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(!isFinalised);
    require(beneficiary != 0x0);
    require(msg.value != 0);
    require(now >= mainSaleStartTime && now <= mainSaleEndTime);
    uint256 newRaise = weiRaised.add(msg.value);
    require(msg.value >= saleMinimumWei && newRaise <= hardCap);

     
    uint256 bonusedTokens = applyBonus(msg.value);
    
     
    require(bonusedTokens < tokensToSell);

     
    weiRaised = newRaise;
    tokensToSell = tokensToSell.sub(bonusedTokens);
    token.mint(beneficiary, bonusedTokens);
    TokenPurchase(msg.sender, beneficiary, msg.value, bonusedTokens);
  }

   
  function finaliseCrowdsale() external onlyOwner returns (bool) {
    require(!isFinalised);
    token.finishMinting();
    forwardFunds();
    FinalisedCrowdsale(token.totalSupply());
    isFinalised = true;
    return true;
  }

   
  function pauseToken() external onlyOwner {
    require(!isFinalised);
    GESToken(token).pause();
  }

   
  function unpauseToken() external onlyOwner {
    GESToken(token).unpause();
  }

   
  function transferTokenOwnership(address newOwner) external onlyOwner {
    GESToken(token).transferOwnership(newOwner);
  }

   
  function mainSaleHasEnded() external constant returns (bool) {
    return now > mainSaleEndTime;
  }

   
  function forwardFunds() internal {
    wallet.transfer(this.balance);
  }

   
  function setMainSaleDates(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime) public onlyOwner returns (bool) {
    require(!isFinalised);
    require(_mainSaleStartTime < _mainSaleEndTime);
    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;
    return true;
  }

   
  function applyBonus(uint256 weiAmount) internal constant returns (uint256 bonusedTokens) {
     
    uint256 tokensToAdd = 0;

     
    uint256 tokens = weiAmount.mul(rate);
    
    for(uint8 i = 0; i < amountBonuses.length; i++){
        if(weiAmount < amountBonuses[i].amount){
           tokensToAdd = tokens.mul(amountBonuses[i].percent).div(100);
            return tokens.add(tokensToAdd);
        }
    }
     
    return tokens.mul(120).div(100);
  }

   
  function fetchFunds() onlyOwner public {
    wallet.transfer(this.balance);
  }

}