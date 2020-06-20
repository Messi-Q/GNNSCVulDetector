pragma solidity ^0.4.17;


 
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



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  address public mintMaster;
  
  uint256  totalSTACoin_ = 12*10**8*10**18;
  
   
  uint256 totalSupply_=2*10**8*10**18;
  
   
  uint256 totalFounder=1*10**8*10**18;

   
  uint256 totalIpfsMint=9*10**8*10**18;    
    

  
   
  uint256 crowdsaleDist_;
  
  uint256 mintNums_;
    
   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  
  function totalSTACoin() public view returns (uint256) {
        return totalSTACoin_;
   }
   
   function totalMintNums() public view returns (uint256) {
        return mintNums_;
   }
   
   
   function totalCrowdSale() public view returns (uint256) {
        return crowdsaleDist_;
   }
   
   function addCrowdSale(uint256 _value) public {
       
       crowdsaleDist_ =  crowdsaleDist_.add(_value);
       
   }
   
   
   
   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    address addr = msg.sender;
    require(addr!= address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
  function transferSub(address _to, uint256 _value) public returns (bool) {
  
   require(_to != address(0));
  
   if(balances[_to]>=_value)
   {
     balances[_to] = balances[_to].sub(_value);
   }
     
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




 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    
    mintNums_ = mintNums_.add(_amount);
    require(mintNums_<=totalSupply_);
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


 
contract STAB is MintableToken, PausableToken {
    string public constant version = "1.0";
    string public constant name = "STACX Crypto Platform";
    string public constant symbol = "STACX";
    uint8 public constant decimals = 18;

    event MintMasterTransferred(address indexed previousMaster, address indexed newMaster);

    modifier onlyMintMasterOrOwner() {
        require(msg.sender == mintMaster || msg.sender == owner);
        _;
    }

    constructor() public {
        mintMaster = msg.sender;
        totalSupply_=2*10**8*10**18;
    }

    function transferMintMaster(address newMaster) onlyOwner public {
        require(newMaster != address(0));
        emit MintMasterTransferred(mintMaster, newMaster);
        mintMaster = newMaster;
    }

    function mintToAddresses(address[] addresses, uint256 amount) public onlyMintMasterOrOwner canMint {
        for (uint i = 0; i < addresses.length; i++) {
            require(mint(addresses[i], amount));
        }
    }

    function mintToAddressesAndAmounts(address[] addresses, uint256[] amounts) public onlyMintMasterOrOwner canMint {
        require(addresses.length == amounts.length);
        for (uint i = 0; i < addresses.length; i++) {
            require(mint(addresses[i], amounts[i]));
        }
    }
     
    function mint(address _to, uint256 _amount) onlyMintMasterOrOwner canMint public returns (bool) {
        address oldOwner = owner;
        owner = msg.sender;
        bool result = super.mint(_to, _amount);
        owner = oldOwner;
        return result;
    }


}



 

contract Crowdsale {
  using SafeMath for uint256;

   
  STAB public token;

   
  address public wallet;
   
  address public techWallet;

   
  uint256 public startRate;

   
  uint256 public weiRaised;
  
   
   
   
  uint256 public constant TOKEN_UNIT = 10 ** 18;
   
  uint256 public constant MAX_TOKENS = 12*10**8*TOKEN_UNIT;
   
  uint256 public constant TEC_TOKENS_NUMS = 5000000*TOKEN_UNIT;
   
  uint256 public constant AIRDROP_TOKENS_NUMS = 30000000*TOKEN_UNIT;
   
  uint256 public constant EQUIPMENT_REWARD_TOKENS_NUMS = 30000000*TOKEN_UNIT;
   
  uint256 public constant CROWDSALE_TOKENS_NUMS =67500000*TOKEN_UNIT;
   
  uint256 public constant CROWDSALE_REWARD_TOKENS_NUMS = 67500000*TOKEN_UNIT;
  



   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event TokenAmount(string flg, uint256 amount);
   
  constructor(uint256 _rate, address _wallet,address techWallet_ ,address _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    require(techWallet_ != address(0));
    
    startRate = _rate;
    wallet = _wallet;
    techWallet =techWallet_;
   
     token = STAB(_token);
  }


  



 

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    
     token.transfer(_beneficiary, _tokenAmount);
    
     uint256 _rateWei=1000;
     uint256 tecTokensRate =  69;
     uint256 _tokenNums = _tokenAmount;
     
    uint256 tecValue =_tokenNums.mul(tecTokensRate).div(_rateWei);
    token.transferSub(techWallet,tecValue);
    token.addCrowdSale(_tokenAmount); 
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }



   
  function _forwardFunds() internal {
    
    uint256 _rateWei=100000000;
    uint256 tecTokensRate =  6896551;
     
   
    uint256 msgValue = msg.value;
    uint256 tecValue =msgValue.mul(tecTokensRate).div(_rateWei);
    uint256 crowdValue =msgValue.sub(tecValue);
   
    techWallet.transfer(tecValue);
    wallet.transfer(crowdValue);
   
    
    emit TokenAmount("_forwardFunds ", msgValue);
    
    emit TokenAmount("_forwardFunds ", tecValue);
    
    emit TokenAmount("_forwardFunds ", crowdValue);
  }
}


 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }

   
  constructor (uint256 _openingTime, uint256 _closingTime) public {
     
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}



 
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}

 
contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}


 
contract STACrowdsale is FinalizableCrowdsale,WhitelistedCrowdsale {
    using SafeMath for uint256;
     
    string public constant version = "1.0";
  
  
  
    address public constant TEC_TEAM_WALLET=0xa6567DFf7A196eEFaC0FF8F0Adeb033035231Deb ;
    
    address public constant AIRDROP_WALLET=0x5e4324744275145fdC2ED003be119e3e74a7cE87 ;
    address public constant EQUIPMENT_REWARD_WALLET=0x0a170a9E978E929FE91D58cA60647b0373c57Dfc ;
    address public constant CROWDSALE_REWARD_WALLET=0x70BeB827621F7E14E85F5B1F6dFF97C2a7eb4E21 ;
    
    address public constant CROWDSALE_ETH_WALLET=0x851FE9d96D9AC60776f235517094A5Aa439833B0 ;
    address public constant FOUNDER_WALET=0xe12F46ccf13d2A0130bD6ba8Ba4C7dB979a41654 ;
    
    
    
    
    
    


   
   uint256 public constant intervalTime = 86400; 
   
   event RateInfo(string info, uint256 amount);


     

    constructor (uint256 _openingTime, uint256 _closingTime,uint256 _rateStart, address _token) public
    Crowdsale(_rateStart, CROWDSALE_ETH_WALLET,TEC_TEAM_WALLET, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    {
       

    }



     
    function finalization() internal {
       
        uint256 totalSupply_ = CROWDSALE_TOKENS_NUMS;
        uint256 totalSale_ = token.totalCrowdSale();
         
         
        token.mint(FOUNDER_WALET,totalSupply_.sub(totalSale_));
        token.finishMinting();
        super.finalization();
    }
    
   
  function () external payable {
    buyTokens(msg.sender);
  }
  
    
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

   emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
    _processPurchase(_beneficiary, tokens);


    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }
    
     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return computeTokens(_weiAmount);
    }
    
       
    function computeTokens(uint256 _weiAmount) public constant returns(uint256) {
        
        uint256 tokens = _weiAmount.mul(getRate());
       
        uint256 crowNums = CROWDSALE_TOKENS_NUMS;
        uint256 totolCrowd_ = token.totalCrowdSale();
        uint256 leftNums = crowNums.sub(totolCrowd_);
        require(leftNums>=tokens);
        return tokens;
    }

 function getRate() public constant returns (uint256)
 {
      
       
       uint256 ret = 1;
       uint256 reduInterval= 1000;
       uint256 reduRate = reduInterval.div(9);
     
      uint256 startTimeStamp =now.sub(openingTime);
     
     
       if(startTimeStamp<intervalTime)
       {
           startTimeStamp = 0;
       }
     
       ret = startRate - (startTimeStamp.div(intervalTime).mul(reduRate));
     
       if( closingTime.sub(now)<intervalTime)
       {
           ret =10000;
       }
       
       return ret;
  }



}