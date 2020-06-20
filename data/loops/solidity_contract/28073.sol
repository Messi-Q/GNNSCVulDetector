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

 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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


 

contract BeeToken is StandardToken, BurnableToken, Ownable {
    string public constant symbol = "BEE";
    string public constant name = "Bee Token";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 500000000 * (10 ** uint256(decimals));
    uint256 public constant TOKEN_OFFERING_ALLOWANCE = 150000000 * (10 ** uint256(decimals));
    uint256 public constant ADMIN_ALLOWANCE = INITIAL_SUPPLY - TOKEN_OFFERING_ALLOWANCE;
    
     
    address public adminAddr;
     
    address public tokenOfferingAddr;
     
    bool public transferEnabled = false;
    
     
    modifier onlyWhenTransferAllowed() {
        require(transferEnabled || msg.sender == adminAddr || msg.sender == tokenOfferingAddr);
        _;
    }

     
    modifier onlyTokenOfferingAddrNotSet() {
        require(tokenOfferingAddr == address(0x0));
        _;
    }

     
    modifier validDestination(address to) {
        require(to != address(0x0));
        require(to != address(this));
        require(to != owner);
        require(to != address(adminAddr));
        require(to != address(tokenOfferingAddr));
        _;
    }
    
     
    function BeeToken(address admin) public {
        totalSupply = INITIAL_SUPPLY;
        
         
        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);

         
        adminAddr = admin;
        approve(adminAddr, ADMIN_ALLOWANCE);
    }

     
    function setTokenOffering(address offeringAddr, uint256 amountForSale) external onlyOwner onlyTokenOfferingAddrNotSet {
        require(!transferEnabled);

        uint256 amount = (amountForSale == 0) ? TOKEN_OFFERING_ALLOWANCE : amountForSale;
        require(amount <= TOKEN_OFFERING_ALLOWANCE);

        approve(offeringAddr, amount);
        tokenOfferingAddr = offeringAddr;
    }
    
     
    function enableTransfer() external onlyOwner {
        transferEnabled = true;

         
        approve(tokenOfferingAddr, 0);
    }

     
    function transfer(address to, uint256 value) public onlyWhenTransferAllowed validDestination(to) returns (bool) {
        return super.transfer(to, value);
    }
    
     
    function transferFrom(address from, address to, uint256 value) public onlyWhenTransferAllowed validDestination(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }
    
     
    function burn(uint256 value) public {
        require(transferEnabled || msg.sender == owner);
        super.burn(value);
    }
}

contract BeeTokenOffering is Pausable {
    using SafeMath for uint256;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public beneficiary;

     
    BeeToken public token;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    uint256 public capDoublingTimestamp;
    uint256 public capReleaseTimestamp;

     
    uint256[3] public tierCaps;

     
    mapping(uint8 => mapping(address => bool)) public whitelists;

     
    mapping(address => uint256) public contributions;

     
    uint256 public constant FUNDING_ETH_HARD_CAP = 5000 * 1 ether;

     
    Stages public stage;

    enum Stages { 
        Setup,
        OfferingStarted,
        OfferingEnded
    }

    event OfferingOpens(uint256 startTime, uint256 endTime);
    event OfferingCloses(uint256 endTime, uint256 totalWeiRaised);
     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

     
    modifier atStage(Stages expectedStage) {
        require(stage == expectedStage);
        _;
    }

     
    modifier validPurchase(uint8 tier) {
        require(tier < tierCaps.length);
        require(now >= startTime && now <= endTime && stage == Stages.OfferingStarted);

        uint256 contributionInWei = msg.value;
        address participant = msg.sender;
        require(participant != address(0) && contributionInWei > 100000000000000000);
        require(weiRaised.add(contributionInWei) <= FUNDING_ETH_HARD_CAP);

        uint256 initialCapInWei = tierCaps[tier];
        
        if (now < capDoublingTimestamp) {
            require(contributions[participant].add(contributionInWei) <= initialCapInWei);
        } else if (now < capReleaseTimestamp) {
            require(contributions[participant].add(contributionInWei) <= initialCapInWei.mul(2));
        }

        _;
    }

     
    function BeeTokenOffering(
        uint256 beeToEtherRate, 
        address beneficiaryAddr, 
        uint256 baseContributionCapInWei,
        address tokenAddress
    ) public {
        require(beeToEtherRate > 0);
        require(beneficiaryAddr != address(0));
        require(tokenAddress != address(0));

        token = BeeToken(tokenAddress);
        rate = beeToEtherRate;
        beneficiary = beneficiaryAddr;
        stage = Stages.Setup;

         
        tierCaps[0] = baseContributionCapInWei.mul(3);
        tierCaps[1] = baseContributionCapInWei.mul(2);
        tierCaps[2] = baseContributionCapInWei;
    }

     
    function () public payable {
        buy();
    }

     
    function ownerSafeWithdrawal() external onlyOwner {
        beneficiary.transfer(this.balance);
    }

    function updateRate(uint256 beeToEtherRate) public onlyOwner atStage(Stages.Setup) {
        rate = beeToEtherRate;
    }

     
    function whitelist(uint8[] tiers, address[] users) public onlyOwner {
        require(tiers.length == users.length);
        for (uint32 i = 0; i < users.length; i++) {
            require(tiers[i] < tierCaps.length);
            whitelists[tiers[i]][users[i]] = true;
        }
    }

     
    function startOffering(uint256 durationInSeconds) public onlyOwner atStage(Stages.Setup) {
        stage = Stages.OfferingStarted;
        startTime = now;
        capDoublingTimestamp = startTime + 24 hours;
        capReleaseTimestamp = startTime + 48 hours;
        endTime = capReleaseTimestamp.add(durationInSeconds);
        OfferingOpens(startTime, endTime);
    }

     
    function endOffering() public onlyOwner atStage(Stages.OfferingStarted) {
        endOfferingImpl();
    }
    
     
    function buy() public payable whenNotPaused atStage(Stages.OfferingStarted) returns (bool) {
        for (uint8 i = 0; i < tierCaps.length; ++i) {
            if (whitelists[i][msg.sender]) {
                buyTokensTier(i);
                return true;
            }
        }
        revert();
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime || stage == Stages.OfferingEnded;
    }

     
    function buyTokensTier(uint8 tier) internal validPurchase(tier) {
        address participant = msg.sender;
        uint256 contributionInWei = msg.value;

         
        uint256 tokens = contributionInWei.mul(rate);
        
        if (!token.transferFrom(token.owner(), participant, tokens)) {
            revert();
        }

        weiRaised = weiRaised.add(contributionInWei);
        contributions[participant] = contributions[participant].add(contributionInWei);
         
        if (weiRaised >= FUNDING_ETH_HARD_CAP) {
            endOfferingImpl();
        }
        
         
        beneficiary.transfer(contributionInWei);
        TokenPurchase(msg.sender, contributionInWei, tokens);       
    }

     
    function endOfferingImpl() internal {
        endTime = now;
        stage = Stages.OfferingEnded;
        OfferingCloses(endTime, weiRaised);
    }

     
    function allocateTokensBeforeOffering(address to, uint256 tokens)
        public
        onlyOwner
        atStage(Stages.Setup)
        returns (bool)
    {
        if (!token.transferFrom(token.owner(), to, tokens)) {
            revert();
        }
        return true;
    }
    
     
    function batchAllocateTokensBeforeOffering(address[] toList, uint256[] tokensList)
        external
        onlyOwner
        atStage(Stages.Setup)
        returns (bool)
    {
        require(toList.length == tokensList.length);

        for (uint32 i = 0; i < toList.length; i++) {
            allocateTokensBeforeOffering(toList[i], tokensList[i]);
        }
        return true;
    }

}