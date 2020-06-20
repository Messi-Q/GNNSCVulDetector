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
pragma solidity ^0.4.18;


 
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


 

contract MintableToken is StandardToken, Ownable {
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
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
contract YRXToken is MintableToken {
    string public constant name = "Yoritex Token";
    string public constant symbol = "YRX";
    uint8 public constant decimals = 18;
    address public crowdsaleAddress;

    uint256 public constant INITIAL_SUPPLY = 510000000 * 1 ether;

    modifier nonZeroAddress(address _to) {                  
        require(_to != 0x0);
        _;
    }

    modifier nonZeroAmount(uint _amount) {                  
        require(_amount > 0);
        _;
    }

    modifier nonZeroValue() {                               
        require(msg.value > 0);
        _;
    }

    modifier onlyCrowdsale() {                              
        require(msg.sender == crowdsaleAddress);
        _;
    }

     
    function YRXToken() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply;
    }

     
     
     
    function setCrowdsaleAddress(address _crowdsaleAddress) external onlyOwner nonZeroAddress(_crowdsaleAddress) returns (bool success){
        require(crowdsaleAddress == 0x0);
        crowdsaleAddress = _crowdsaleAddress;
        decrementBalance(owner, totalSupply);
        addToBalance(crowdsaleAddress, totalSupply);
        Transfer(0x0, _crowdsaleAddress, totalSupply);
        return true;
    }

     
     
     
    function transferFromCrowdsale(address _to, uint256 _amount) external onlyCrowdsale nonZeroAmount(_amount) nonZeroAddress(_to) returns (bool success) {
        require(balanceOf(crowdsaleAddress) >= _amount);
        decrementBalance(crowdsaleAddress, _amount);
        addToBalance(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

     
     
     
    function addToBalance(address _address, uint _amount) internal {
        balances[_address] = balances[_address].add(_amount);
    }

     
     
     
    function decrementBalance(address _address, uint _amount) internal {
        balances[_address] = balances[_address].sub(_amount);
    }

}

 

contract YRXCrowdsale is Ownable {
  using SafeMath for uint256;

   
  bool public isPreSaleFinalised;
   
  bool public isFinalised;
   
  YRXToken public YRX;
   
  address public wallet;

   
  uint256 public weiRaised;

   
  uint256 public preSaleTotalSupply;
  uint256 public mainSaleTotalSupply;
   
  uint256 public bountyTotalSupply;
  uint256 private mainSaleTokensExtra;

  event WalletAddressChanged(address _wallet);            
  event AmountRaised(address beneficiary, uint amountRaised);  
  event Mint(address indexed to, uint256 amount);
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  modifier nonZeroAddress(address _to) {                  
    require(_to != 0x0);
    _;
  }

  modifier nonZeroAmount(uint _amount) {                  
    require(_amount > 0);
    _;
  }

  modifier nonZeroValue() {                               
    require(msg.value > 0);
    _;
  }

  modifier crowdsaleIsActive() {                          
    require(!isFinalised && (isInPreSale() || isInMainSale()));
    _;
  }

  function YRXCrowdsale(address _wallet, address _token) public {

     

     
    require(mainSaleStartTime() >= now);                  
    require(preSaleEndTime() < mainSaleStartTime());       
    require(preSaleStartTime() < preSaleEndTime());        
    require(mainSaleStartTime() < mainSaleEndTime());      

     
    YRX = YRXToken(_token);
    wallet = _wallet;
    isPreSaleFinalised = false;
    isFinalised = false;

     
    preSaleTotalSupply = 0;
    mainSaleTotalSupply = 0;
    bountyTotalSupply = 0;
    mainSaleTokensExtra = 0;
  }

   
   
   
  function changeWalletAddress(address _wallet) external onlyOwner {
    wallet = _wallet;
    WalletAddressChanged(_wallet);
  }


  function maxTokens() public pure returns(uint256) {
    return 510000000 * 1 ether;
  }

  function preSaleMaxTokens() public pure returns(uint256) {
    return 51000000 * 1 ether;
  }

  function mainSaleMaxTokens() public view returns(uint256) {
    return 433500000  * 1 ether + mainSaleTokensExtra;
  }

  function bountyMaxTokens() public pure returns(uint256) {
    return 25500000 * 1 ether;
  }

  function preSaleStartTime() public pure returns(uint256) {
    return 1511913600;
  }

  function preSaleEndTime() public pure returns(uint256) {
    return 1515628799;
  }

  function mainSaleStartTime() public pure returns(uint256) {
    return 1515628800;
  }

  function mainSaleEndTime() public pure returns(uint256) {
    return 1525996800;
  }

  function rate() public pure returns(uint256) {
    return 540;
  }

  function discountRate() public pure returns(uint256) {
    return 1350;
  }

  function discountICO() public pure returns(uint256) {
    return 60;
  }

  function isInPreSale() public constant returns(bool){
    return now >= preSaleStartTime() && now <= preSaleEndTime();
  }

  function isInMainSale() public constant returns(bool){
    return now >= mainSaleStartTime() && now <= mainSaleEndTime();
  }

  function totalSupply() public view returns(uint256){
    return YRX.totalSupply();
  }

   
  function () public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public crowdsaleIsActive nonZeroAddress(beneficiary) nonZeroValue payable {
    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount * rate();
    if (isInPreSale()) {
      require(!isPreSaleFinalised);
      tokens = weiAmount * discountRate();
      require(tokens <= preSaleTokenLeft());
    }

    if (isInMainSale()) {
       
      tokens = weiAmount * discountRate();
      require(mainSaleTotalSupply + tokens <= mainSaleMaxTokens());
    }

     
    weiRaised = weiRaised.add(weiAmount);
    if (isInPreSale())
      preSaleTotalSupply += tokens;
    if (isInMainSale())
      mainSaleTotalSupply += tokens;

    forwardFunds();
    if (!YRX.transferFromCrowdsale(beneficiary, tokens)) {revert();}
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }

   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function mint(address beneficiary, uint256 amount) public onlyOwner crowdsaleIsActive nonZeroAddress(beneficiary) nonZeroAmount(amount) {
     
    bool withinPreSalePeriod = isInPreSale();
    bool withinMainSalePeriod = isInMainSale();
    if (withinPreSalePeriod) {
      require(!isPreSaleFinalised);
      require(amount <= preSaleTokenLeft());
    }
    if (withinMainSalePeriod) {
      require(amount <= (mainSaleMaxTokens() - mainSaleTotalSupply));
    }

    if (withinPreSalePeriod)
      preSaleTotalSupply += amount;
    if (withinMainSalePeriod)
      mainSaleTotalSupply += amount;

    if (!YRX.transferFromCrowdsale(beneficiary, amount)) {revert();}
    Mint(beneficiary, amount);
  }

  function preSaleTokenLeft() public constant returns(uint256){
    return preSaleMaxTokens() - preSaleTotalSupply;
  }

   
  function finalisePreSale() public onlyOwner {
    require(!isFinalised);
    require(!isPreSaleFinalised);
    require(now >= preSaleStartTime());  

    if (preSaleTokenLeft() > 0) {
      mainSaleTokensExtra = preSaleTokenLeft();
    }

    isPreSaleFinalised = true;
  }

   
  function finalise() public onlyOwner returns(bool success){
    require(!isFinalised);
    require(now >= mainSaleStartTime());  
    AmountRaised(wallet, weiRaised);
    isFinalised = true;
    return true;
  }

   
  function mintBounty(address beneficiary, uint256 amount) public onlyOwner crowdsaleIsActive nonZeroAddress(beneficiary) nonZeroAmount(amount) {
    require(amount <= (bountyMaxTokens() - bountyTotalSupply));

    bountyTotalSupply += amount;
    if (!YRX.transferFromCrowdsale(beneficiary, amount)) {revert();}
    Mint(beneficiary, amount);
  }

}