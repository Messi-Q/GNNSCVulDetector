pragma solidity 0.4.19;

 
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256)  {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
  
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
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

  uint256 totalSupply_;


   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
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
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
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

   
  function increaseApproval (address _spender, uint _addedValue)
    public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
  public
    returns (bool success) {
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

 
contract OrigamiToken is StandardToken, Ownable {
    string  public  constant name = "Origami Network";
    string  public  constant symbol = "ORI";
    uint8    public  constant decimals = 18;

    uint    public  transferableStartTime;

    address public  tokenSaleContract;
    address public  bountyWallet;


    modifier onlyWhenTransferEnabled() 
    {
        if ( now <= transferableStartTime ) {
            require(msg.sender == tokenSaleContract || msg.sender == bountyWallet || msg.sender == owner);
        }
        _;
    }

    modifier validDestination(address to) 
    {
        require(to != address(this));
        _;
    }

    function OrigamiToken(
        uint tokenTotalAmount, 
        uint _transferableStartTime, 
        address _admin, 
        address _bountyWallet) public
    {
         
        totalSupply_ = tokenTotalAmount * (10 ** uint256(decimals));

         
        balances[msg.sender] = totalSupply_;
        Transfer(address(0x0), msg.sender, totalSupply_);

         
        transferableStartTime = _transferableStartTime;
         
        tokenSaleContract = msg.sender;
         
        bountyWallet = _bountyWallet;

        transferOwnership(_admin);  
    }

     
    function transfer(address _to, uint _value)
        public
        validDestination(_to)
        onlyWhenTransferEnabled
        returns (bool) 
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value)
        public
        validDestination(_to)
        onlyWhenTransferEnabled
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    event Burn(address indexed _burner, uint _value);

     
    function burn(uint _value) 
        public
        onlyWhenTransferEnabled
        returns (bool)
    {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(msg.sender, _value);
        Transfer(msg.sender, address(0x0), _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) 
        public
        onlyWhenTransferEnabled
        returns(bool) 
    {
        assert(transferFrom(_from, msg.sender, _value));
        return burn(_value);
    }

     
    function emergencyERC20Drain(ERC20 token, uint amount )
        public
        onlyOwner 
    {
        token.transfer(owner, amount);
    }
}

 
contract StandardCrowdsale {
  using SafeMath for uint256;

   
  StandardToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function StandardCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

     
     
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }


   
  function validPurchase() internal view returns (bool) {
     
    return true;
  }

}

 
contract CappedCrowdsale is StandardCrowdsale {
  using SafeMath for uint256;

  uint256 public cap;
  

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached || super.hasEnded();
  }

   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised < cap;
    return withinCap && super.validPurchase();
  }

}



 
contract WhitelistedCrowdsale is StandardCrowdsale, Ownable {
    
    mapping(address=>bool) public registered;

    event RegistrationStatusChanged(address target, bool isRegistered);

     
    function changeRegistrationStatus(address target, bool isRegistered)
        public
        onlyOwner
    {
        registered[target] = isRegistered;
        RegistrationStatusChanged(target, isRegistered);
    }

     
    function changeRegistrationStatuses(address[] targets, bool isRegistered)
        public
        onlyOwner
    {
        for (uint i = 0; i < targets.length; i++) {
            changeRegistrationStatus(targets[i], isRegistered);
        }
    }

     
    function validPurchase() internal view  returns (bool) {
        return super.validPurchase() && registered[msg.sender];
    }
}

 
contract OrigamiTokenSale is Ownable, CappedCrowdsale, WhitelistedCrowdsale {
     
    uint private constant HARD_CAP_IN_WEI = 5000 ether;
    uint private constant HARD_CAP_IN_WEI_PRESALE = 1000 ether;

     
    uint private constant BONUS_TWENTY_AMOUNT = 200 ether;
    uint private constant BONUS_TEN_AMOUNT = 100 ether;
    uint private constant BONUS_FIVE_AMOUNT = 50 ether;   
    
     
    uint private constant MINIMUM_INVEST_IN_WEI_PRESALE = 0.5 ether;
    uint private constant CONTRIBUTOR_MAX_PRESALE_CONTRIBUTION = 50 ether;
    uint private constant MINIMUM_INVEST_IN_WEI_SALE = 0.1 ether;
    uint private constant CONTRIBUTOR_MAX_SALE_CONTRIBUTION = 500 ether;

     
    address private constant ORIGAMI_WALLET = 0xf498ED871995C178a5815dd6D80AE60e1c5Ca2F4;
    
     
    address private constant BOUNTY_WALLET = 0xDBA7a16383658AeDf0A28Eabf2032479F128f26D;
    uint private constant BOUNTY_AMOUNT = 3000000e18;

     
    uint private constant PERIOD_AFTERSALE_NOT_TRANSFERABLE_IN_SEC = 7 days;    

     
    uint private constant TOTAL_ORI_TOKEN_SUPPLY = 50000000;

     
    uint private constant RATE_ETH_ORI = 6000;
    

     
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 private presaleEndedAt;
    uint256 public preSaleWeiRaised;
    
     
    uint public firstWeekEndTime;
    uint public secondWeekEndTime;  
    
    
     
    mapping(address => uint256) wei_invested_by_contributor_in_presale;
    mapping(address => uint256) wei_invested_by_contributor_in_sale;

    event OrigamiTokenPurchase(address indexed beneficiary, uint256 value, uint256 final_tokens, uint256 initial_tokens, uint256 bonus);

    function OrigamiTokenSale(uint256 _presaleStartTime, uint256 _presaleEndTime, uint256 _startTime, uint256 _endTime, uint256 _firstWeekEndTime, uint256 _secondWeekEndTime) public
      WhitelistedCrowdsale()
      CappedCrowdsale(HARD_CAP_IN_WEI)
      StandardCrowdsale(_startTime, _endTime, RATE_ETH_ORI, ORIGAMI_WALLET)
    {
         
        token = createTokenContract();
         
        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
        firstWeekEndTime = _firstWeekEndTime;
        secondWeekEndTime = _secondWeekEndTime;

         
        token.transfer(BOUNTY_WALLET, BOUNTY_AMOUNT);
    }
    
     
    function preSaleOpen() 
        public
        view 
        returns(bool)
    {
        return (now >= presaleStartTime && now <= presaleEndTime && preSaleWeiRaised < HARD_CAP_IN_WEI_PRESALE);
    }
    
     
    function preSaleEndedAt() 
        public
        view 
        returns(uint256)
    {
        return presaleEndedAt;
    }
    
     
    function saleOpen() 
        public
        view 
        returns(bool)
    {
        return (now >= startTime && now <= endTime);
    }
    
     
    function getInvestedAmount(address _address)
    public
    view
    returns (uint256)
    {
        uint256 investedAmount = wei_invested_by_contributor_in_presale[_address];
        investedAmount = investedAmount.add(wei_invested_by_contributor_in_sale[_address]);
        return investedAmount;
    }

     
    function getBonusFactor(uint256 _weiAmount)
        private view returns(uint256)
    {
         
        uint256 bonus = 0;

         
        if(now >= presaleStartTime && now <= presaleEndTime) {
            bonus = 15;
         
        } else {        
           
          if(_weiAmount >= BONUS_TWENTY_AMOUNT) {
              bonus = 20;
          }
           
          else if(_weiAmount >= BONUS_TEN_AMOUNT || now <= firstWeekEndTime) {
              bonus = 10;
          }
           
          else if(_weiAmount >= BONUS_FIVE_AMOUNT || now <= secondWeekEndTime) {
              bonus = 5;
          }
        }
        
        return bonus;
    }
    
     
    function buyTokens() 
       public 
       payable 
    {
        require(validPurchase());
        uint256 weiAmount = msg.value;

         
        uint256 tokens = weiAmount.mul(rate);

         
        uint256 bonus = getBonusFactor(weiAmount);
        
         
        uint256 final_bonus_amount = (tokens * bonus) / 100;
        
          
        uint256 final_tokens = tokens.add(final_bonus_amount);
         
        require(token.transfer(msg.sender, final_tokens)); 

          
        OrigamiTokenPurchase(msg.sender, weiAmount, final_tokens, tokens, final_bonus_amount);

         
        forwardFunds();

         
        weiRaised = weiRaised.add(weiAmount);

         
        if (preSaleOpen()) {
            wei_invested_by_contributor_in_presale[msg.sender] =  wei_invested_by_contributor_in_presale[msg.sender].add(weiAmount);
            preSaleWeiRaised = preSaleWeiRaised.add(weiAmount);
            if(weiRaised >= HARD_CAP_IN_WEI_PRESALE){
                presaleEndedAt = now;
            }
        }else{
            wei_invested_by_contributor_in_sale[msg.sender] =  wei_invested_by_contributor_in_sale[msg.sender].add(weiAmount);  
            if(weiRaised >= HARD_CAP_IN_WEI){
              endTime = now;
            }
        }
    }


     
    function createTokenContract () 
      internal 
      returns(StandardToken) 
    {
        return new OrigamiToken(TOTAL_ORI_TOKEN_SUPPLY, endTime.add(PERIOD_AFTERSALE_NOT_TRANSFERABLE_IN_SEC), ORIGAMI_WALLET, BOUNTY_WALLET);
    }

     
    function () external
       payable 
    {
        buyTokens();
    }
    
     
    function getContributorRemainingPresaleAmount(address wallet) public view returns(uint256) {
        uint256 invested_amount =  wei_invested_by_contributor_in_presale[wallet];
        return CONTRIBUTOR_MAX_PRESALE_CONTRIBUTION - invested_amount;
    }
    
         
    function getContributorRemainingSaleAmount(address wallet) public view returns(uint256) {
        uint256 invested_amount =  wei_invested_by_contributor_in_sale[wallet];
        return CONTRIBUTOR_MAX_SALE_CONTRIBUTION - invested_amount;
    }

     
    function drainRemainingToken () 
      public
      onlyOwner
    {
        require(hasEnded());
        token.transfer(ORIGAMI_WALLET, token.balanceOf(this));
    }
    
     
    function validPurchase () internal view returns(bool) 
    {
         
        if (preSaleOpen()) {
             
            if(preSaleWeiRaised > HARD_CAP_IN_WEI_PRESALE){
                return false;
            }
             
            if(msg.value < MINIMUM_INVEST_IN_WEI_PRESALE){
                 return false;
            }
             
            uint256 maxInvestAmount = getContributorRemainingPresaleAmount(msg.sender);
            if(msg.value > maxInvestAmount){
              return false;
            }
        }else if(saleOpen()){
             
            if(msg.value < MINIMUM_INVEST_IN_WEI_SALE){
                 return false;
            }
            
              
             uint256 maxInvestAmountSale = getContributorRemainingSaleAmount(msg.sender);
             if(msg.value > maxInvestAmountSale){
               return false;
            }
        }else{
            return false;
        }

         
        bool nonZeroPurchase = msg.value != 0;
        return super.validPurchase() && nonZeroPurchase;
    }

}