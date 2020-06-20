pragma solidity ^0.4.18;

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

contract LANCCrowdsale is Ownable {
  using SafeMath for uint256;

  address public fundDepositAddress = 0xE700569B98D4BF25E05c64C96560f77bCD44565E;

  uint256 public currentPeriod = 0;
  bool public isFinalized = false;
   
   
   
   
   
   

  mapping (uint256 => uint256) public rateMap;
  mapping (address => uint256) powerDayAddressLimits;

  uint256 public powerDayRate; 
  uint256 public powerDayEthPerPerson = 10;
  uint256 public presaleStartTime;
  uint256 public powerDayEndTime;

  uint256 public constant capPresale =  57 * (10**5) * 10**18;
  uint256 public constant capRound1 =  (288 * (10**5) * 10**18);
  uint256 public constant capRound2 =  (484 * (10**5) * 10**18);

  uint256 public rate = 0;  

   
  LANCToken public token;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function LANCCrowdsale() public {
    
     

    rateMap[1] = 2100;  
    powerDayRate = 2000;  
    rateMap[2] = 1900;   
    rateMap[3] = 1650;   
    rateMap[4] = 1400;   
    rateMap[5] = 0; 
  }

  function setTokenContract(address _token) public onlyOwner {
        require(_token != address(0) && token == address(0));
        require(LANCToken(_token).owner() == address(this));
        require(LANCToken(_token).totalSupply() == 0);
        require(!LANCToken(_token).mintingFinished());

        token = LANCToken(_token);
   }

   function mint(address _to, uint256 _amount) public onlyOwner {
       require(token != address(0));
       require(!LANCToken(token).mintingFinished());
       require(LANCToken(token).owner() == address(this));

       token.mint(_to, _amount);
   }

    

  function updateRates(uint256 rateIdx, uint256 newRate) public onlyOwner {
    require(rateIdx > 0 && rateIdx < 5);
    require(newRate > 0);

    rateMap[rateIdx] = newRate;

    if (rateIdx == currentPeriod) {
      rate = newRate;
    }
  }

  function updatePowerDayRate(uint256 newRate) public onlyOwner {
      powerDayRate = newRate;
  }

  function switchSaleState() public onlyOwner {
    require(token != address(0));

    if (currentPeriod > 4) {
      revert();  
    }

    currentPeriod = currentPeriod + 1;

    if (currentPeriod == 2) {
      presaleStartTime = now;
      powerDayEndTime = (presaleStartTime + 1 days);
    }

    rate = rateMap[currentPeriod];
  }

  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(token != address(0));
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 currentRate = rate;
    uint256 tokens;
    bool inPowerDay = saleInPowerDay();

     
    
     
    if (inPowerDay == true) {
      tokens = weiAmount.mul(powerDayRate);      
    } else {
      tokens = weiAmount.mul(currentRate);      
    }
    
     
    uint256 checkedSupply = token.totalSupply().add(tokens);
    require(willFitInCap(checkedSupply));
     

    if (inPowerDay == true) {
      uint256 newWeiAmountPerSender = powerDayAddressLimits[msg.sender].add(weiAmount);

       
      if (newWeiAmountPerSender > powerDayPerPersonCapInWei()) {
        revert();
      } else {
        powerDayAddressLimits[msg.sender] = newWeiAmountPerSender;
      }
    }

     
    
    token.mint(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function saleInPowerDay() internal view returns (bool) {
    bool inPresale = (currentPeriod == 2);
    bool inPowerDayPeriod = (now >= presaleStartTime && now <= powerDayEndTime);

    return inPresale && inPowerDayPeriod;
  }

  function powerDayPerPersonCapInWei() public view returns (uint) {
    require(token != address(0));
       

    return powerDayEthPerPerson * (10**token.decimals()); 
  }
  

  function willFitInCap(uint256 checkedSupply) internal view returns (bool) {
    if (currentPeriod == 1 || currentPeriod == 2) {
      return (checkedSupply <= capPresale);
    } else if (currentPeriod == 3) {
      return (checkedSupply <= capRound1);
    } else if (currentPeriod == 4) {
      return (checkedSupply <= capRound2);
    }

    return false;
  }

   
  function validPurchase() internal view returns (bool) {
    bool tokenAssigned = (token != address(0));
    bool inStartedState = (currentPeriod > 0 && currentPeriod < 5);
    bool nonZeroPurchase = msg.value != 0;

    return tokenAssigned && inStartedState && nonZeroPurchase && !isFinalized;
  }

   
  function finalizeSale() public onlyOwner {
    if (isFinalized == true) {
      revert();
    }

    uint newTokens = token.totalSupply();

     
    token.mint(fundDepositAddress, newTokens);

    token.finishMinting();
    token.transferOwnership(owner);

    isFinalized = true;
  }

   
  function hasEnded() public view returns (bool) {
    return currentPeriod > 4;
  }

   
   
  function forwardFunds() internal {
    fundDepositAddress.transfer(msg.value);
  }

  function powerDayRemainingLimitOf(address _owner) public view returns (uint256 balance) {
    return powerDayAddressLimits[_owner];
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

contract LANCToken is MintableToken {

  string public name = "LanceChain Token";
  string public symbol = "LANC";
  uint public decimals = 18;
  
}