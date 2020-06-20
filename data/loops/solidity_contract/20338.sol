pragma solidity ^0.4.18;


 
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


 
 
 
 
 
 
 
 
 
 
 
 
contract HoloToken is Ownable {
  string public constant name = "HoloToken";
  string public constant symbol = "HOT";
  uint8 public constant decimals = 18;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MintingFinished();
  event Burn(uint256 amount);

  uint256 public totalSupply;


   
   
   

  using SafeMath for uint256;

  mapping(address => uint256) public balances;

   
  function transfer(address _to, uint256 _value) public whenMintingFinished returns (bool) {
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


   
   
   
  mapping (address => mapping (address => uint256)) public allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public whenMintingFinished returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public whenMintingFinished returns (bool) {
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


   
   
   

  bool public mintingFinished = false;
  address public destroyer;
  address public minter;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier whenMintingFinished() {
    require(mintingFinished);
    _;
  }

  modifier onlyMinter() {
    require(msg.sender == minter);
    _;
  }

  function setMinter(address _minter) external onlyOwner {
    minter = _minter;
  }

  function mint(address _to, uint256 _amount) external onlyMinter canMint  returns (bool) {
    require(balances[_to] + _amount > balances[_to]);  
    require(totalSupply + _amount > totalSupply);      
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  function finishMinting() external onlyMinter returns (bool) {
    mintingFinished = true;
    MintingFinished();
    return true;
  }


   
   
   


  modifier onlyDestroyer() {
     require(msg.sender == destroyer);
     _;
  }

  function setDestroyer(address _destroyer) external onlyOwner {
    destroyer = _destroyer;
  }

  function burn(uint256 _amount) external onlyDestroyer {
    require(balances[destroyer] >= _amount && _amount > 0);
    balances[destroyer] = balances[destroyer].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    Burn(_amount);
  }
}


 
 
 
contract HoloWhitelist is Ownable {
  address public updater;

  struct KnownFunder {
    bool whitelisted;
    mapping(uint => uint256) reservedTokensPerDay;
  }

  mapping(address => KnownFunder) public knownFunders;

  event Whitelisted(address[] funders);
  event ReservedTokensSet(uint day, address[] funders, uint256[] reservedTokens);

  modifier onlyUpdater {
    require(msg.sender == updater);
    _;
  }

  function HoloWhitelist() public {
    updater = msg.sender;
  }

  function setUpdater(address new_updater) external onlyOwner {
    updater = new_updater;
  }

   
  function whitelist(address[] funders) external onlyUpdater {
    for (uint i = 0; i < funders.length; i++) {
        knownFunders[funders[i]].whitelisted = true;
    }
    Whitelisted(funders);
  }

   
  function unwhitelist(address[] funders) external onlyUpdater {
    for (uint i = 0; i < funders.length; i++) {
        knownFunders[funders[i]].whitelisted = false;
    }
  }

   
   
   
  function setReservedTokens(uint day, address[] funders, uint256[] reservedTokens) external onlyUpdater {
    for (uint i = 0; i < funders.length; i++) {
        knownFunders[funders[i]].reservedTokensPerDay[day] = reservedTokens[i];
    }
    ReservedTokensSet(day, funders, reservedTokens);
  }

   
  function isWhitelisted(address funder) external view returns (bool) {
    return knownFunders[funder].whitelisted;
  }

   
   
   
  function reservedTokens(address funder, uint day) external view returns (uint256) {
    return knownFunders[funder].reservedTokensPerDay[day];
  }


}


 
 
 
 
 
 
 
 
 
 
 
contract HoloSale is Ownable, Pausable{
  using SafeMath for uint256;

   
  uint256 public startBlock;
  uint256 public endBlock;
   
   
  uint256 public rate;
   
  uint256 public maximumPercentageOfDaysSupply;
   
  uint256 public minimumAmountWei;
   
  address public wallet;

   
  HoloToken private tokenContract;
   
   
  HoloWhitelist private whitelistContract;

   
   
  address private updater;

   
  bool private finalized = false;

  uint256 public totalSupply;

   
  struct Day {
     
    uint256 supply;
     
    uint256 soldFromUnreserved;
     
    uint256 reserved;
     
    uint256 soldFromReserved;
     
     
     
    mapping(address => uint256) fuelBoughtByAddress;
  }

   
  Day[] public statsByDay;

  event CreditsCreated(address beneficiary, uint256 amountWei, uint256 amountHolos);
  event Update(uint256 newTotalSupply, uint256 reservedTokensNextDay);

  modifier onlyUpdater {
    require(msg.sender == updater);
    _;
  }

   
   
   
  function holosForWei(uint256 amountWei) internal view returns (uint256) {
    return amountWei * rate / 1000000000000000000;
  }

   
   
   
   
   
   
  function HoloSale(
    uint256 _startBlock, uint256 _endBlock,
    uint256 _rate,
    uint256 _minimumAmountWei, uint256 _maximumPercentageOfDaysSupply,
    address _wallet) public
  {
    require(_startBlock >= block.number);
    require(_endBlock >= _startBlock);
    require(_rate > 0);
    require(_wallet != 0x0);

    updater = msg.sender;
    startBlock = _startBlock;
    endBlock = _endBlock;
    rate = _rate;
    maximumPercentageOfDaysSupply = _maximumPercentageOfDaysSupply;
    minimumAmountWei = _minimumAmountWei;
    wallet = _wallet;
  }

   
   
   

  function setUpdater(address _updater) external onlyOwner {
    updater = _updater;
  }

  function setTokenContract(HoloToken _tokenContract) external onlyOwner {
    tokenContract = _tokenContract;
  }

  function setWhitelistContract(HoloWhitelist _whitelistContract) external onlyOwner {
    whitelistContract = _whitelistContract;
  }

  function currentDay() public view returns (uint) {
    return statsByDay.length;
  }

  function todaysSupply() external view returns (uint) {
    return statsByDay[currentDay()-1].supply;
  }

  function todaySold() external view returns (uint) {
    return statsByDay[currentDay()-1].soldFromUnreserved + statsByDay[currentDay()-1].soldFromReserved;
  }

  function todayReserved() external view returns (uint) {
    return statsByDay[currentDay()-1].reserved;
  }

  function boughtToday(address beneficiary) external view returns (uint) {
    return statsByDay[currentDay()-1].fuelBoughtByAddress[beneficiary];
  }

   
   
   

   
  function () public payable {
    buyFuel(msg.sender);
  }

   
   
  function buyFuel(address beneficiary) public payable whenNotPaused{
    require(currentDay() > 0);
    require(whitelistContract.isWhitelisted(beneficiary));
    require(beneficiary != 0x0);
    require(withinPeriod());

     
    uint256 amountOfHolosAsked = holosForWei(msg.value);

     
    uint dayIndex = statsByDay.length-1;
    Day storage today = statsByDay[dayIndex];

     
    uint256 reservedHolos = whitelistContract.reservedTokens(beneficiary, dayIndex);
     
    uint256 alreadyBought = today.fuelBoughtByAddress[beneficiary];
    if(alreadyBought >= reservedHolos) {
      reservedHolos = 0;
    } else {
      reservedHolos = reservedHolos.sub(alreadyBought);
    }

     
    uint256 askedMoreThanReserved;
    uint256 useFromReserved;
    if(amountOfHolosAsked > reservedHolos) {
      askedMoreThanReserved = amountOfHolosAsked.sub(reservedHolos);
      useFromReserved = reservedHolos;
    } else {
      askedMoreThanReserved = 0;
      useFromReserved = amountOfHolosAsked;
    }

    if(reservedHolos == 0) {
       
       
       
      require(msg.value >= minimumAmountWei);
    }

     
     
    require(lessThanMaxRatio(beneficiary, askedMoreThanReserved, today));
    require(lessThanSupply(askedMoreThanReserved, today));

     
     
    wallet.transfer(msg.value);
     
    tokenContract.mint(beneficiary, amountOfHolosAsked);
     
    today.soldFromUnreserved = today.soldFromUnreserved.add(askedMoreThanReserved);
    today.soldFromReserved = today.soldFromReserved.add(useFromReserved);
    today.fuelBoughtByAddress[beneficiary] = today.fuelBoughtByAddress[beneficiary].add(amountOfHolosAsked);
    CreditsCreated(beneficiary, msg.value, amountOfHolosAsked);
  }

   
  function withinPeriod() internal constant returns (bool) {
    uint256 current = block.number;
    return current >= startBlock && current <= endBlock;
  }

   
   
  function lessThanMaxRatio(address beneficiary, uint256 amount, Day storage today) internal view returns (bool) {
    uint256 boughtTodayBefore = today.fuelBoughtByAddress[beneficiary];
    return boughtTodayBefore.add(amount).mul(100).div(maximumPercentageOfDaysSupply) <= today.supply;
  }

   
  function lessThanSupply(uint256 amount, Day today) internal pure returns (bool) {
    return today.soldFromUnreserved.add(amount) <= today.supply.sub(today.reserved);
  }

   
   
   


  function update(uint256 newTotalSupply, uint256 reservedTokensNextDay) external onlyUpdater {
    totalSupply = newTotalSupply;
     
    uint256 daysSupply = newTotalSupply.sub(tokenContract.totalSupply());
    statsByDay.push(Day(daysSupply, 0, reservedTokensNextDay, 0));
    Update(newTotalSupply, reservedTokensNextDay);
  }

   
   
   

   
  function hasEnded() public constant returns (bool) {
    return block.number > endBlock;
  }

   
   
   
   
  function finalize() external onlyOwner {
    require(!finalized);
    require(hasEnded());
    uint256 receiptsMinted = tokenContract.totalSupply();
    uint256 shareForTheTeam = receiptsMinted.div(3);
    tokenContract.mint(wallet, shareForTheTeam);
    tokenContract.finishMinting();
    finalized = true;
  }
}