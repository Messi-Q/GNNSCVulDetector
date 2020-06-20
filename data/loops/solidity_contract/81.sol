pragma solidity ^0.4.24;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public { owner = msg.sender;  }
 
  modifier onlyOwner() {     
      address sender =  msg.sender;
      address _owner = owner;
      require(msg.sender == _owner);    
      _;  
  }
  
  function transferOwnership(address newOwner) onlyOwner public { 
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
    emit Transfer(msg.sender, _to, _value);
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
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
    emit Mint(_to, _amount);
    emit Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
contract BrickToken is MintableToken {

    string public constant name = "Brick"; 
    string public constant symbol = "BRK";
    uint8 public constant decimals = 18;

    function getTotalSupply() view public returns (uint256) {
        return totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        super.transfer(_to, _value);
    }
    
}

 
contract BrickCrowdsale is Ownable {
    using SafeMath for uint256;
    
     
    uint256 public startTime;
    uint256 public endTime;
     
    uint256 public weiRaised;
    uint256 public limitDateSale;  
    uint256 public currentTime;
    
    bool public isSoftCapHit = false;
    bool public isStarted = false;
    bool public isFinalized = false;
     
    uint256 icoPvtRate  = 40; 
    uint256 icoPreRate  = 50;
    uint256 ico1Rate    = 65;
    uint256 ico2Rate    = 75;
    uint256 ico3Rate    = 90;
     
    uint256 public pvtTokens        = (40000) * (10**18);
    uint256 public preSaleTokens    = (6000000) * (10**18);
    uint256 public ico1Tokens       = (8000000) * (10**18);
    uint256 public ico2Tokens       = (8000000) * (10**18);
    uint256 public ico3Tokens       = (8000000) * (10**18);
    uint256 public totalTokens      = (40000000)* (10**18);  
    
       
    address public advisoryEthWallet        = 0x0D7629d32546CD493bc33ADEF115D4489f5599Be;
    address public infraEthWallet           = 0x536D36a05F6592aa29BB0beE30cda706B1272521;
    address public techDevelopmentEthWallet = 0x4d0B70d8E612b5dca3597C64643a8d1efd5965e1;
    address public operationsEthWallet      = 0xbc67B82924eEc8643A4f2ceDa59B5acfd888A967;
    
     address public wallet = 0x44d44CA0f75bdd3AE8806D02515E8268459c554A;  
     
   struct ContributorData {
        uint256 contributionAmount;
        uint256 tokensIssued;
    }
   
    mapping(address => ContributorData) public contributorList;
    mapping(uint => address) contributorIndexes;
    uint nextContributorIndex;

    constructor() public {}
    
   function init( uint256 _tokensForCrowdsale, uint256 _etherInUSD, address _tokenAddress, uint256 _softCapInEthers, uint256 _hardCapInEthers, 
        uint _saleDurationInDays, uint bonus) onlyOwner public {
        
        
        currentTime = now;
        setTokensForCrowdSale(_tokensForCrowdsale);
        setRate(_etherInUSD);
        setTokenAddress(_tokenAddress);
        setSoftCap(_softCapInEthers);
        setHardCap(_hardCapInEthers);
        setSaleDuration(_saleDurationInDays);
        setSaleBonus(bonus);
        start();
         
   }
   
     
    function start() onlyOwner public {
        require(!isStarted);
        require(!hasStarted());
        require(tokenAddress != address(0));
        require(saleDuration != 0);
        require(totalTokens != 0);
        require(tokensForCrowdSale != 0);
        require(softCap != 0);
        require(hardCap != 0);
        
        starting();
        emit BrickStarted();
        
        isStarted = true;
         
    }
 
    function splitTokens() internal {   
        token.mint(techDevelopmentEthWallet, totalTokens.mul(3).div(100));           
        tokensIssuedTillNow = tokensIssuedTillNow + totalTokens.mul(3).div(100);
        token.mint(operationsEthWallet, totalTokens.mul(7).div(100));                 
        tokensIssuedTillNow = tokensIssuedTillNow + totalTokens.mul(7).div(100);
        
    }
    
       
   uint256 public tokensForCrowdSale = 0;
   function setTokensForCrowdSale(uint256 _tokensForCrowdsale) onlyOwner public {
       tokensForCrowdSale = _tokensForCrowdsale.mul(10 ** 18);  
   }
 
   
    uint256 public rate=0;
    uint256 public etherInUSD;
    function setRate(uint256 _etherInUSD) internal {
        etherInUSD = _etherInUSD;
        rate = getCurrentRateInCents().mul(10**18).div(100).div(_etherInUSD);
    }
    
    function setRate(uint256 rateInCents, uint256 _etherInUSD) public onlyOwner {
        etherInUSD = _etherInUSD;
        rate = rateInCents.mul(10**18).div(100).div(_etherInUSD);
    }
    
    function updateRateInWei() internal {  
        require(etherInUSD != 0);
        rate = getCurrentRateInCents().mul(10**18).div(100).div(etherInUSD);
    }
    
    function getCurrentRateInCents() public view returns (uint256)
    {
        if(currentRound == 1) {
            return icoPvtRate;
        } else if(currentRound == 2) {
            return icoPreRate;
        } else if(currentRound == 3) {
            return ico1Rate;
        } else if(currentRound == 4) {
            return  ico2Rate;
        } else if(currentRound == 5) {
            return ico3Rate;
        } else {
            return ico3Rate;
        }
    }
     
    BrickToken public token;
    address tokenAddress = 0x0; 
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;  
        token = BrickToken(_tokenAddress);
    }
    
 
    function setPvtTokens (uint256 _pvtTokens)onlyOwner public {
        require(!icoPvtEnded);
        pvtTokens = (_pvtTokens).mul(10 ** 18);
    }
    function setPreSaleTokens (uint256 _preSaleTokens)onlyOwner public {
        require(!icoPreEnded);
        preSaleTokens = (_preSaleTokens).mul(10 ** 18);
    }
    function setIco1Tokens (uint256 _ico1Tokens)onlyOwner public {
        require(!ico1Ended);
        ico1Tokens = (_ico1Tokens).mul(10 ** 18);
    }
    function setIco2Tokens (uint256 _ico2Tokens)onlyOwner public {
        require(!ico2Ended);
        ico2Tokens = (_ico2Tokens).mul(10 ** 18);
    }
    function setIco3Tokens (uint256 _ico3Tokens)onlyOwner public {
        require(!ico3Ended);
        ico3Tokens = (_ico3Tokens).mul(10 ** 18);
    }
    
   uint256 public softCap = 0;
   function setSoftCap(uint256 _softCap) onlyOwner public {
       softCap = _softCap.mul(10 ** 18); 
    }
   
   uint256 public hardCap = 0; 
   function setHardCap(uint256 _hardCap) onlyOwner public {
       hardCap = _hardCap.mul(10 ** 18); 
   }
  
     
    uint public saleDuration = 0;  
    function setSaleDuration(uint _saleDurationInDays) onlyOwner public {
        saleDuration = _saleDurationInDays;
        limitDateSale = startTime.add(saleDuration * 1 days);
        endTime = limitDateSale;
    }
  
    uint public saleBonus = 0;  
    function setSaleBonus(uint bonus) public onlyOwner{
        saleBonus = bonus;
    }
    
     
    function () public payable {
        buyPhaseTokens(msg.sender);
    }
   
   function transferTokenOwnership(address _address) onlyOwner public {
       token.transferOwnership(_address);
   }
    
    function releaseTokens(address _contributerAddress, uint256 tokensOfContributor) internal {
       token.mint(_contributerAddress, tokensOfContributor);
    }
    
    function currentTokenSupply() public view returns(uint256){
        return token.getTotalSupply();
    }
    
   function buyPhaseTokens(address beneficiary) public payable 
   { 
        assert(!ico3Ended);
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;
         
        uint256 tokens = computeTokens(weiAmount);  
        require(isWithinTokenAllocLimit(tokens));
       
        if(int(pvtTokens - tokensIssuedTillNow) > 0) {  
            require(int (tokens) < (int(pvtTokens -  tokensIssuedTillNow)));
            buyTokens(tokens,weiAmount,beneficiary);
        } else if (int (preSaleTokens + pvtTokens - tokensIssuedTillNow) > 0) {   
            require(int(tokens) < (int(preSaleTokens + pvtTokens - tokensIssuedTillNow)));
            buyTokens(tokens,weiAmount,beneficiary);
        } else if(int(ico1Tokens + preSaleTokens + pvtTokens - tokensIssuedTillNow) > 0) {   
            require(int(tokens) < (int(ico1Tokens + preSaleTokens + pvtTokens -tokensIssuedTillNow)));
            buyTokens(tokens,weiAmount,beneficiary);
        } else if(int(ico2Tokens + ico1Tokens + preSaleTokens + pvtTokens - (tokensIssuedTillNow)) > 0) {   
            require(int(tokens) < (int(ico2Tokens + ico1Tokens + preSaleTokens + pvtTokens - (tokensIssuedTillNow))));
            buyTokens(tokens,weiAmount,beneficiary);
        }  else if(!ico3Ended && (int(tokensForCrowdSale - (tokensIssuedTillNow)) > 0)) {  
            require(int(tokens) < (int(tokensForCrowdSale - (tokensIssuedTillNow))));
            buyTokens(tokens,weiAmount,beneficiary);
        }
   }
   uint256 public tokensIssuedTillNow=0;
   function buyTokens(uint256 tokens, uint256 weiAmount ,address beneficiary) internal {
       
         
        weiRaised = weiRaised.add(weiAmount);

        if (contributorList[beneficiary].contributionAmount == 0) {  
            contributorIndexes[nextContributorIndex] = beneficiary;
            nextContributorIndex += 1;
        }
        
        contributorList[beneficiary].contributionAmount += weiAmount;
        contributorList[beneficiary].tokensIssued += tokens;
        tokensIssuedTillNow = tokensIssuedTillNow + tokens;
        releaseTokens(beneficiary, tokens);  
        forwardFunds();  
        emit BrickTokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }
   
  
       
    event BrickTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
    function investorCount() constant public returns(uint) {
        return nextContributorIndex;
    }
    
    function hasStarted() public constant returns (bool) {
        return (startTime != 0 && now > startTime);
    }

    function isWithinSaleTimeLimit() internal view returns (bool) {
        return now <= limitDateSale;
    }

    function isWithinSaleLimit(uint256 _tokens) internal view returns (bool) {
        return token.getTotalSupply().add(_tokens) <= tokensForCrowdSale;
    }
    
    function computeTokens(uint256 weiAmount) view internal returns (uint256) {
       return weiAmount.mul(10 ** 18).div(rate);
    }
    
    function isWithinTokenAllocLimit(uint256 _tokens) view internal returns (bool) {
        return (isWithinSaleTimeLimit() && isWithinSaleLimit(_tokens));
    }

     
     
    function validPurchase() internal constant returns (bool) {
        bool withinCap = weiRaised.add(msg.value) <= hardCap;
        bool withinPeriod = now >= startTime && now <= endTime; 
        bool nonZeroPurchase = msg.value != 0; 
        return (withinPeriod && nonZeroPurchase) && withinCap && isWithinSaleTimeLimit();
    }

     
     
    function hasEnded() public constant returns (bool) {
        bool capReached = weiRaised >= hardCap;
        return (endTime != 0 && now > endTime) || capReached;
    }

  

  event BrickStarted();
  event BrickFinalized();

   
    function finalize() onlyOwner public {
        require(!isFinalized);
         
        
        finalization();
        emit BrickFinalized();
        
        isFinalized = true;
    }

    function starting() internal {
        startTime = now;
        limitDateSale = startTime.add(saleDuration * 1 days);
        endTime = limitDateSale;
    }

    function finalization() internal {
         splitTokens();

        token.mint(wallet, totalTokens.sub(tokensIssuedTillNow));
        if(address(this).balance > 0){  
            processFundsIfAny();
        }
    }
    
      
    function forwardFunds() internal {
        
        require(advisoryEthWallet != address(0));
        require(infraEthWallet != address(0));
        require(techDevelopmentEthWallet != address(0));
        require(operationsEthWallet != address(0));
        
        operationsEthWallet.transfer(msg.value.mul(60).div(100));
        advisoryEthWallet.transfer(msg.value.mul(5).div(100));
        infraEthWallet.transfer(msg.value.mul(10).div(100));
        techDevelopmentEthWallet.transfer(msg.value.mul(25).div(100));
    }
    
      
    function processFundsIfAny() internal {
        
        require(advisoryEthWallet != address(0));
        require(infraEthWallet != address(0));
        require(techDevelopmentEthWallet != address(0));
        require(operationsEthWallet != address(0));
        
        operationsEthWallet.transfer(address(this).balance.mul(60).div(100));
        advisoryEthWallet.transfer(address(this).balance.mul(5).div(100));
        infraEthWallet.transfer(address(this).balance.mul(10).div(100));
        techDevelopmentEthWallet.transfer(address(this).balance.mul(25).div(100));
    }
    
     
    
    uint256 public currentRound = 1;
    bool public icoPvtEnded = false;
     bool public icoPreEnded = false;
      bool public ico1Ended = false;
       bool public ico2Ended = false;
        bool public ico3Ended = false;
    
    function endPvtSale() onlyOwner public        
    {
        require(!icoPvtEnded);
        pvtTokens = tokensIssuedTillNow;
        currentRound = 2;
        updateRateInWei();
        icoPvtEnded = true;
        
    }
     function endPreSale() onlyOwner public       
    {
        require(!icoPreEnded && icoPvtEnded);
        preSaleTokens = tokensIssuedTillNow - pvtTokens; 
        currentRound = 3;
        updateRateInWei();
        icoPreEnded = true;
    }
     function endIcoSaleRound1() onlyOwner public    
    {
        require(!ico1Ended && icoPreEnded);
       ico1Tokens = tokensIssuedTillNow - preSaleTokens - pvtTokens; 
       currentRound = 4;
       updateRateInWei();
       ico1Ended = true;
    }
     function endIcoSaleRound2() onlyOwner public    
    {
       require(!ico2Ended && ico1Ended);
       ico2Tokens = tokensIssuedTillNow - ico1Tokens - preSaleTokens - pvtTokens;
       currentRound = 5;
       updateRateInWei();
       ico2Ended=true;
    }
     function endIcoSaleRound3() onlyOwner public   
     {
        require(!ico3Ended && ico2Ended);
        ico3Tokens = tokensIssuedTillNow - ico2Tokens - ico1Tokens - preSaleTokens - pvtTokens;
        updateRateInWei();
        ico3Ended = true;
    }
    
    modifier afterDeadline() { if (hasEnded() || isFinalized) _; }  
    
    function selfDestroy(address _address) public onlyOwner {  
        assert(isFinalized);
        selfdestruct(_address);
    }
    
}