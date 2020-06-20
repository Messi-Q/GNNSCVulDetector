pragma solidity ^0.4.19;

 
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


   
  function transferOwnership(address newOwner) public onlyOwner{
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

 
contract ChariotToken is StandardToken, Ownable {

  string public constant name = "Chariot Coin";
  string public constant symbol = "TOM";
  uint8 public constant decimals = 18;
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event MintPaused(bool pause);

  bool public mintingFinished = false;
  bool public mintingPaused = false;
  address public saleAgent = address(0);

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier unpauseMint() {
    require(!mintingPaused);
    _;
  }

  function setSaleAgent(address newSaleAgnet) public {
    require(msg.sender == saleAgent || msg.sender == owner);
    saleAgent = newSaleAgnet;
  }

   
  function pauseMinting(bool _mintingPaused) canMint public returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner));
    mintingPaused = _mintingPaused;
    MintPaused(_mintingPaused);
    return _mintingPaused;
  }

   
  function mint(address _to, uint256 _amount) canMint unpauseMint public returns (bool) {
    require(msg.sender == saleAgent || msg.sender == owner);
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(this), _to, _amount);
    return true;
  }

   
  function finishMinting() canMint public returns (bool) {
    require((msg.sender == saleAgent || msg.sender == owner));
    mintingFinished = true;
    MintFinished();
    return true;
  }

  event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }

  function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(msg.sender == saleAgent || msg.sender == owner);
        require(balances[_from] >= _value); 
        require(_value <= allowed[_from][msg.sender]); 
        balances[_from] = balances[_from].sub(_value);  
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);  
        totalSupply = totalSupply.sub(_value);
        Burn(_from, _value);
        return true;
    }

}

 
contract TokenSale is Ownable{
  using SafeMath for uint256;
   
    
  ChariotToken public token;

  uint256 public startTime;
  uint256 public endTime;

  uint256 public initialSupply = 37600000 * 1 ether;

   
  uint256 limit;
  uint256 period;
   
  address public wallet;

   
  uint256 public rate = 1000;

   
  address public TeamAndAdvisors;
  address public Investors;
  address public EADC;
  address public Bounty;

   
  uint256 public weiRaised;
  uint256 public weiSoftCap = 800 * 1 ether;
  uint256 public weiHardCap = 1600 * 1 ether;

  modifier saleIsOn() {
      require(now > startTime && now < endTime);
      require(weiRaised <= weiHardCap);
      require(initialSupply >= token.totalSupply());
      _;
  }

  uint256 discountStage1 = 60;
  uint256 discountStage2 = 55;
  uint256 discountStage3 = 50;
  uint256 discountStage4 = 40;

  function setDiscountStage(
    uint256 _newDiscountStage1,
    uint256 _newDiscountStage2,
    uint256 _newDiscountStage3,
    uint256 _newDiscountStage4
    ) onlyOwner public {
    discountStage1 = _newDiscountStage1;
    discountStage2 = _newDiscountStage2;
    discountStage3 = _newDiscountStage3;
    discountStage4 = _newDiscountStage4;
  }

  function setTime(uint _startTime, uint _endTime) public onlyOwner {
    require(now < _endTime && _startTime < _endTime);
    endTime = _endTime;
    startTime = _startTime;
  }

  function setRate(uint _newRate) public onlyOwner {
    rate = _newRate;
  }

  function setTeamAddress(
    address _TeamAndAdvisors,
    address _Investors,
    address _EADC,
    address _Bounty,
    address _wallet) public onlyOwner {
    TeamAndAdvisors = _TeamAndAdvisors;
    Investors = _Investors;
    EADC = _EADC;
    Bounty = _Bounty;
    wallet = _wallet;
  }

  function getDiscountStage() public view returns (uint256) {
    if(now < startTime + 5 days) {
        return discountStage1;
      } else if(now >= startTime + 5 days && now < startTime + 10 days) {
        return discountStage2;
      } else if(now >= startTime + 10 days && now < startTime + 15 days) {
        return discountStage3;
      } else if(now >= startTime + 15 days && now < endTime) {
        return discountStage4;
      }
  }

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event TokenPartners(address indexed purchaser, address indexed beneficiary, uint256 amount);

  function TokenSale(
    uint256 _startTime,
    uint256 _endTime,
    address _wallet,
    uint256 _limit,
    uint256 _period,
    address _TeamAndAdvisors,
    address _Investors,
    address _Bounty,
    address _EADC
    ) public {
    require(_wallet != address(0));
    require(_TeamAndAdvisors != address(0));
    require(_Investors != address(0));
    require(_EADC != address(0));
    require(_Bounty != address(0));
    require(_endTime > _startTime);
    require(now < _startTime);
    token = new ChariotToken();
    startTime = _startTime;
    endTime = _endTime;
    wallet = _wallet;
    limit = _limit * 1 ether;
    period = _period;
    TeamAndAdvisors = _TeamAndAdvisors;
    Investors = _Investors;
    EADC = _EADC;
    Bounty = _Bounty;
    token.setSaleAgent(owner);
  }

  function updatePrice() returns(uint256){
    uint256 _days = now.sub(startTime).div(1 days);  
    return (_days % period).add(1).mul(rate);  
  }
  
  function setLimit(uint256 _newLimit) public onlyOwner {
    limit = _newLimit * 1 ether;
  }

   
  function isUnderLimit(uint256 _value) public returns (bool){
    uint256 _days = now.sub(startTime).div(1 days);  
    uint256 coinsLimit = (_days % period).add(1).mul(limit);  
    return (msg.sender).balance.add(_value) <= coinsLimit;
  }

  function buyTokens(address beneficiary) saleIsOn public payable {
    require(beneficiary != address(0));

    uint256 weiAmount = msg.value;
    uint256 all = 100;
    uint256 tokens;
    
     
    tokens = weiAmount.mul(updatePrice()).mul(100).div(all.sub(getDiscountStage()));

     
    weiRaised = weiRaised.add(weiAmount);
    if(endTime.sub(now).div(1 days) > 5) {
      require(isUnderLimit(tokens));
    }

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    wallet.transfer(weiAmount.mul(30).div(100));
    Investors.transfer(weiAmount.mul(65).div(100));
    EADC.transfer(weiAmount.mul(5).div(100));

    uint256 taaTokens = tokens.mul(27).div(100);
    uint256 bountyTokens = tokens.mul(3).div(100);

    token.mint(TeamAndAdvisors, taaTokens);
    token.mint(Bounty, bountyTokens);

    TokenPartners(msg.sender, TeamAndAdvisors, taaTokens);
    TokenPartners(msg.sender, Bounty, bountyTokens);  
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }
}