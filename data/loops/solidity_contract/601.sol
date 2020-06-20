pragma solidity 0.4.20;

 
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
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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

   
  function increaseApproval (address _spender, uint _addedValue) returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) returns (bool success) {
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

 
contract StandardCrowdsale {
    using SafeMath for uint256;

     
    StandardToken public token; 

     
    uint256 public icoStartTime;
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;

     
    address public wallet;

     
     
     
     
    uint256 public icoRate;
    uint256 public tier1Rate;
    uint256 public tier2Rate;
    uint256 public tier3Rate;
    uint256 public tier4Rate;


     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

     
    function StandardCrowdsale(
        uint256 _icoStartTime,  
        uint256 _presaleStartTime,
        uint256 _presaleEndTime,
        uint256 _icoRate, 
        uint256 _tier1Rate,
        uint256 _tier2Rate,
        uint256 _tier3Rate,
        uint256 _tier4Rate,
        address _wallet) {

        require(_icoStartTime >= now);
        require(_icoRate > 0);
        require(_wallet != 0x0);

        icoStartTime = _icoStartTime;
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        tier1Rate = _tier1Rate;
        tier2Rate = _tier2Rate;
        tier3Rate = _tier3Rate;
        tier4Rate = _tier4Rate;

        icoRate = _icoRate;
        wallet = _wallet;

        token = createTokenContract(); 
    }

    function createTokenContract() internal returns(StandardToken) {
        return new StandardToken();
    }

     
     
     
    function () payable {
        buyTokens();
    }

     
    function buyTokens() public payable {

         
        require(validPurchase()); 

        uint256 weiAmount = msg.value;

         
         
         
        uint256 tokens = weiAmount.mul(icoRate);

         
         
        if ((now >= presaleStartTime && now < presaleEndTime) && weiRaised.add(weiAmount) <= 600 ether) {        
            if (weiAmount < 2 ether) 
                tokens = weiAmount.mul(tier1Rate);
            if (weiAmount >= 2 ether && weiAmount < 5 ether) 
                tokens = weiAmount.mul(tier2Rate);
            if (weiAmount >= 5 ether && weiAmount < 10 ether)
                tokens = weiAmount.mul(tier3Rate);
            if (weiAmount >= 10 ether)
                tokens = weiAmount.mul(tier4Rate);
        } 

         
        weiRaised = weiRaised.add(weiAmount);

        require(token.transfer(msg.sender, tokens));
        TokenPurchase(msg.sender, weiAmount, tokens);

        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal returns(bool) {
        bool withinPresalePeriod = now >= presaleStartTime;
        bool withinICOPeriod = now >= icoStartTime;
        bool nonZeroPurchase = msg.value != 0;
        return (withinPresalePeriod && nonZeroPurchase && weiRaised <= 600 ether) || (withinICOPeriod && nonZeroPurchase && weiRaised <= 3000 ether);
    }
}

 
contract CappedCrowdsale is StandardCrowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached;
  }
}

  
contract WhitelistedCrowdsale is StandardCrowdsale, Ownable {
    
    mapping(address=>bool) public registered;

    event RegistrationStatusChanged(address target, bool isRegistered);

    function changeRegistrationStatus(address target, bool isRegistered) public onlyOwner {
        registered[target] = isRegistered;
        RegistrationStatusChanged(target, isRegistered);
    }

    function changeRegistrationStatuses(address[] targets, bool isRegistered) public onlyOwner {
        for (uint i = 0; i < targets.length; i++) {
            changeRegistrationStatus(targets[i], isRegistered);
        }
    }

    function validPurchase() internal returns (bool) {
        return super.validPurchase() && registered[msg.sender];
    }
}

 
contract ApolloCoinToken is StandardToken, Ownable {
    string  public  constant name = "ApolloCoin";
    string  public  constant symbol = "APC";
    uint8   public  constant decimals = 18;

    uint    public  transferableStartTime;

    address public  tokenSaleContract;
    address public  earlyInvestorWallet;


    modifier onlyWhenTransferEnabled() {
        if ( now <= transferableStartTime ) {
            require(msg.sender == tokenSaleContract || msg.sender == earlyInvestorWallet || msg.sender == owner);
        }
        _;
    }

    modifier validDestination(address to) {
        require(to != address(this));
        _;
    }

    function ApolloCoinToken(uint tokenTotalAmount, uint _transferableStartTime, address _admin, address _earlyInvestorWallet) {
        
        
       totalSupply = tokenTotalAmount * (10 ** uint256(decimals));

        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);

        transferableStartTime = _transferableStartTime;      
        tokenSaleContract = msg.sender;
        earlyInvestorWallet = _earlyInvestorWallet;

        transferOwnership(_admin); 
    }

    function transfer(address _to, uint _value) public validDestination(_to) onlyWhenTransferEnabled returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public validDestination(_to) onlyWhenTransferEnabled returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

     
    function burn(uint _value) public onlyWhenTransferEnabled returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public onlyWhenTransferEnabled returns(bool) {
        assert(transferFrom(_from, msg.sender, _value));
        return burn(_value);
    }

     
    function emergencyERC20Drain(ERC20 token, uint amount ) public onlyOwner {
        token.transfer(owner, amount);
    }
}

 
contract ApolloCoinTokenSale is Ownable, CappedCrowdsale, WhitelistedCrowdsale {
   
     
    uint private constant HARD_CAP = 3000 ether;

     
    uint public constant TOTAL_APC_SUPPLY = 21000000;

     
     
    uint private constant ICO_RATE = 900;

     
    uint private constant TIER1_RATE = 1080;
    uint private constant TIER2_RATE = 1440;
    uint private constant TIER3_RATE = 1620;
    uint private constant TIER4_RATE = 1800; 

     
    address public constant TEAM_WALLET = 0xd55de4cdade91f8b3d0ad44e5bc0074840bcf287;
    uint public constant TEAM_AMOUNT = 4200000e18;

     
    address public constant EARLY_INVESTOR_WALLET = 0x67e84a30d6c33f90e9aef0b9147455f4c8d85208;
    uint public constant EARLY_INVESTOR_AMOUNT = 7350000e18;

     
     
    address private constant APOLLOCOIN_COMPANY_WALLET = 0x129c3e7ac8e80511d50a77d757bb040a1132f59c;
    uint public constant APOLLOCOIN_COMPANY_AMOUNT = 6300000e18;
    
     
    uint public constant NON_TRANSFERABLE_TIME = 10 days;    

    function ApolloCoinTokenSale(uint256 _icoStartTime, uint256 _presaleStartTime, uint256 _presaleEndTime) WhitelistedCrowdsale() CappedCrowdsale(HARD_CAP) StandardCrowdsale(_icoStartTime, _presaleStartTime, _presaleEndTime, ICO_RATE, TIER1_RATE, TIER2_RATE, TIER3_RATE, TIER4_RATE, APOLLOCOIN_COMPANY_WALLET) {
        token.transfer(TEAM_WALLET, TEAM_AMOUNT);

        token.transfer(EARLY_INVESTOR_WALLET, EARLY_INVESTOR_AMOUNT);

        token.transfer(APOLLOCOIN_COMPANY_WALLET, APOLLOCOIN_COMPANY_AMOUNT);
    }

    function createTokenContract () internal returns(StandardToken) {
        return new ApolloCoinToken(TOTAL_APC_SUPPLY, NON_TRANSFERABLE_TIME, APOLLOCOIN_COMPANY_WALLET, EARLY_INVESTOR_WALLET);
    }

    function drainRemainingToken () public onlyOwner {
        require(hasEnded());
        token.transfer(APOLLOCOIN_COMPANY_WALLET, token.balanceOf(this));
    }
  
}