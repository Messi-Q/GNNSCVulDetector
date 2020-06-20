pragma solidity ^0.4.17;

contract J8TTokenConfig {
     
    uint8 public constant TOKEN_DECIMALS = 8;

     
    uint256 public constant J8T_DECIMALS_FACTOR = 10**uint256(TOKEN_DECIMALS);
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

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
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

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract J8TToken is J8TTokenConfig, BurnableToken, Ownable {
    string public constant name            = "J8T Token";
    string public constant symbol          = "J8T";
    uint256 public constant decimals       = TOKEN_DECIMALS;
    uint256 public constant INITIAL_SUPPLY = 1500000000 * (10 ** uint256(decimals));

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function J8TToken() {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;

         
         
         
         
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
     }
}


contract ACLManaged is Ownable {
    
     
     
     

     
    address public opsAddress;

     
    address public adminAddress;

     
     
     

    function ACLManaged() public Ownable() {}

     
    function setOpsAddress(address _opsAddress) external onlyOwner returns (bool) {
        require(_opsAddress != address(0));
        require(_opsAddress != address(this));

        opsAddress = _opsAddress;
        return true;
    }

     
    function setAdminAddress(address _adminAddress) external onlyOwner returns (bool) {
        require(_adminAddress != address(0));
        require(_adminAddress != address(this));

        adminAddress = _adminAddress;
        return true;
    }

     
    function isOwner(address _address) public view returns (bool) {
        bool result = (_address == owner);
        return result;
    }

     
    function isOps(address _address) public view returns (bool) {
        bool result = (_address == opsAddress);
        return result;
    }

     
    function isOpsOrAdmin(address _address) public view returns (bool) {
        bool result = (_address == opsAddress || _address == adminAddress);
        return result;
    }

     
    function isOwnerOrOpsOrAdmin(address _address) public view returns (bool) {
        bool result = (_address == opsAddress || _address == adminAddress || _address == owner);
        return result;
    }

     
    modifier onlyAdmin() {
         
        address _address = msg.sender;
        require(_address != address(0));
        require(_address == adminAddress);
        _;
    }

     
    modifier onlyOps() {
         
        address _address = msg.sender;
        require(_address != address(0));
        require(_address == opsAddress);
        _;
    }

     
    modifier onlyAdminAndOps() {
         
        address _address = msg.sender;
        require(_address != address(0));
        require(_address == opsAddress || _address == adminAddress);
        _;
    }
}

contract CrowdsaleConfig is J8TTokenConfig {
    using SafeMath for uint256;

     
    uint256 public constant START_TIMESTAMP = 1519801200;

     
    uint256 public constant END_TIMESTAMP   = 1521010800;

     
    uint256 public constant ETH_DECIMALS_FACTOR = 10**uint256(18);

     
    uint256 public constant TOKEN_SALE_SUPPLY = 450000000 * J8T_DECIMALS_FACTOR;

     
    uint256 public constant MIN_CONTRIBUTION_WEIS = 0.1 ether;

     
    uint256 public constant MAX_CONTRIBUTION_WEIS = 10 ether;

     
    uint256 constant dollar_per_kilo_token = 100;  
    uint256 public constant dollars_per_kilo_ether = 900000;  
     
    uint256 public constant INITIAL_TOKENS_PER_ETHER = dollars_per_kilo_ether.div(dollar_per_kilo_token);
}

contract Ledger is ACLManaged {
    
    using SafeMath for uint256;

     
     
     

     
     
     
    struct Allocation {
        uint256 amountGranted;
        uint256 amountBonusGranted;
        bool hasClaimedBonusTokens;
    }

     
     
     
    enum ContributionPhase {
        PreSaleContribution, PartnerContribution
    }

     
    mapping(address => Allocation) public presaleAllocations;

     
    mapping(address => Allocation) public partnerAllocations;

     
    J8TToken public tokenContract;

     
    Crowdsale public crowdsaleContract;

     
     
    uint256 public totalPrivateAllocation;

     
    bool public canClaimPartnerTokens;

     
    bool public canClaimPresaleTokens;

     
    bool public canClaimPresaleBonusTokensPhase1;
    bool public canClaimPresaleBonusTokensPhase2;

     
    bool public canClaimPartnerBonusTokensPhase1;
    bool public canClaimPartnerBonusTokensPhase2;

     
     
     

     
    event AllocationGranted(address _contributor, uint256 _amount, uint8 _phase);

     
    event AllocationRevoked(address _contributor, uint256 _amount, uint8 _phase);

     
    event AllocationClaimed(address _contributor, uint256 _amount);

     
    event AllocationBonusClaimed(address _contributor, uint256 _amount);

     
    event CrowdsaleContractUpdated(address _who, address _old_address, address _new_address);

     
    event CanClaimTokensUpdated(address _who, string _type, bool _oldCanClaim, bool _newCanClaim);

     
     
     

     
     
    function Ledger(J8TToken _tokenContract) public {
        require(address(_tokenContract) != address(0));
        tokenContract = _tokenContract;
        canClaimPresaleTokens = false;
        canClaimPartnerTokens = false;
        canClaimPresaleBonusTokensPhase1 = false;
        canClaimPresaleBonusTokensPhase2 = false;
        canClaimPartnerBonusTokensPhase1 = false;
        canClaimPartnerBonusTokensPhase2 = false;
    }

    function () external payable {
        claimTokens();
    }

     
     
     
    function revokeAllocation(address _contributor, uint8 _phase) public onlyAdminAndOps payable returns (uint256) {
        require(_contributor != address(0));
        require(_contributor != address(this));

         
        ContributionPhase _contributionPhase = ContributionPhase(_phase);
        require(_contributionPhase == ContributionPhase.PreSaleContribution ||
                _contributionPhase == ContributionPhase.PartnerContribution);

        uint256 grantedAllocation = 0;

         
        if (_contributionPhase == ContributionPhase.PreSaleContribution) {
            grantedAllocation = presaleAllocations[_contributor].amountGranted.add(presaleAllocations[_contributor].amountBonusGranted);
            delete presaleAllocations[_contributor];
        } else if (_contributionPhase == ContributionPhase.PartnerContribution) {
            grantedAllocation = partnerAllocations[_contributor].amountGranted.add(partnerAllocations[_contributor].amountBonusGranted);
            delete partnerAllocations[_contributor];
        }

         
        uint256 currentSupply = tokenContract.balanceOf(address(this));
        require(grantedAllocation <= currentSupply);

         
        require(grantedAllocation <= totalPrivateAllocation);
        totalPrivateAllocation = totalPrivateAllocation.sub(grantedAllocation);
        
         
        require(tokenContract.transfer(address(crowdsaleContract), grantedAllocation));

        AllocationRevoked(_contributor, grantedAllocation, _phase);

        return grantedAllocation;

    }

     
    function addAllocation(address _contributor, uint256 _amount, uint256 _bonus, uint8 _phase) public onlyAdminAndOps returns (bool) {
        require(_contributor != address(0));
        require(_contributor != address(this));

         
        require(_amount > 0);

         
        ContributionPhase _contributionPhase = ContributionPhase(_phase);
        require(_contributionPhase == ContributionPhase.PreSaleContribution ||
                _contributionPhase == ContributionPhase.PartnerContribution);


        uint256 totalAmount = _amount.add(_bonus);
        uint256 totalGrantedAllocation = 0;
        uint256 totalGrantedBonusAllocation = 0;

         
        if (_contributionPhase == ContributionPhase.PreSaleContribution) {
            totalGrantedAllocation = presaleAllocations[_contributor].amountGranted.add(_amount);
            totalGrantedBonusAllocation = presaleAllocations[_contributor].amountBonusGranted.add(_bonus);
            presaleAllocations[_contributor] = Allocation(totalGrantedAllocation, totalGrantedBonusAllocation, false);
        } else if (_contributionPhase == ContributionPhase.PartnerContribution) {
            totalGrantedAllocation = partnerAllocations[_contributor].amountGranted.add(_amount);
            totalGrantedBonusAllocation = partnerAllocations[_contributor].amountBonusGranted.add(_bonus);
            partnerAllocations[_contributor] = Allocation(totalGrantedAllocation, totalGrantedBonusAllocation, false);
        }

         
        totalPrivateAllocation = totalPrivateAllocation.add(totalAmount);

        AllocationGranted(_contributor, totalAmount, _phase);

        return true;
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function claimTokens() public payable returns (bool) {
        require(msg.sender != address(0));
        require(msg.sender != address(this));

        uint256 amountToTransfer = 0;

         
         
        Allocation storage presaleA = presaleAllocations[msg.sender];
        if (presaleA.amountGranted > 0 && canClaimPresaleTokens) {
            amountToTransfer = amountToTransfer.add(presaleA.amountGranted);
            presaleA.amountGranted = 0;
        }

        Allocation storage partnerA = partnerAllocations[msg.sender];
        if (partnerA.amountGranted > 0 && canClaimPartnerTokens) {
            amountToTransfer = amountToTransfer.add(partnerA.amountGranted);
            partnerA.amountGranted = 0;
        }

         
        require(amountToTransfer > 0);

         
        uint256 currentSupply = tokenContract.balanceOf(address(this));
        require(amountToTransfer <= currentSupply);
        
         
        require(tokenContract.transfer(msg.sender, amountToTransfer));
        AllocationClaimed(msg.sender, amountToTransfer);
    
        return true;
    }

    function claimBonus() external payable returns (bool) {
        require(msg.sender != address(0));
        require(msg.sender != address(this));

        uint256 amountToTransfer = 0;

         
        Allocation storage presale = presaleAllocations[msg.sender];
        if (presale.amountBonusGranted > 0 && !presale.hasClaimedBonusTokens && canClaimPresaleBonusTokensPhase1) {
            uint256 amountPresale = presale.amountBonusGranted.div(2);
            amountToTransfer = amountPresale;
            presale.amountBonusGranted = amountPresale;
            presale.hasClaimedBonusTokens = true;
        }

        Allocation storage partner = partnerAllocations[msg.sender];
        if (partner.amountBonusGranted > 0 && !partner.hasClaimedBonusTokens && canClaimPartnerBonusTokensPhase1) {
            uint256 amountPartner = partner.amountBonusGranted.div(2);
            amountToTransfer = amountToTransfer.add(amountPartner);
            partner.amountBonusGranted = amountPartner;
            partner.hasClaimedBonusTokens = true;
        }

         
        if (presale.amountBonusGranted > 0 && canClaimPresaleBonusTokensPhase2) {
            amountToTransfer = amountToTransfer.add(presale.amountBonusGranted);
            presale.amountBonusGranted = 0;
        }

        if (partner.amountBonusGranted > 0 && canClaimPartnerBonusTokensPhase2) {
            amountToTransfer = amountToTransfer.add(partner.amountBonusGranted);
            partner.amountBonusGranted = 0;
        }

         
        require(amountToTransfer > 0);

         
        uint256 currentSupply = tokenContract.balanceOf(address(this));
        require(amountToTransfer <= currentSupply);
        
         
        require(tokenContract.transfer(msg.sender, amountToTransfer));
        AllocationBonusClaimed(msg.sender, amountToTransfer);

        return true;
    }

     
    function setCanClaimPresaleTokens(bool _canClaimTokens) external onlyAdmin returns (bool) {
        bool _oldCanClaim = canClaimPresaleTokens;
        canClaimPresaleTokens = _canClaimTokens;
        CanClaimTokensUpdated(msg.sender, 'canClaimPresaleTokens', _oldCanClaim, _canClaimTokens);
        return true;
    }

     
    function setCanClaimPartnerTokens(bool _canClaimTokens) external onlyAdmin returns (bool) {
        bool _oldCanClaim = canClaimPartnerTokens;
        canClaimPartnerTokens = _canClaimTokens;
        CanClaimTokensUpdated(msg.sender, 'canClaimPartnerTokens', _oldCanClaim, _canClaimTokens);
        return true;
    }

     
    function setCanClaimPresaleBonusTokensPhase1(bool _canClaimTokens) external onlyAdmin returns (bool) {
        bool _oldCanClaim = canClaimPresaleBonusTokensPhase1;
        canClaimPresaleBonusTokensPhase1 = _canClaimTokens;
        CanClaimTokensUpdated(msg.sender, 'canClaimPresaleBonusTokensPhase1', _oldCanClaim, _canClaimTokens);
        return true;
    }

     
    function setCanClaimPresaleBonusTokensPhase2(bool _canClaimTokens) external onlyAdmin returns (bool) {
        bool _oldCanClaim = canClaimPresaleBonusTokensPhase2;
        canClaimPresaleBonusTokensPhase2 = _canClaimTokens;
        CanClaimTokensUpdated(msg.sender, 'canClaimPresaleBonusTokensPhase2', _oldCanClaim, _canClaimTokens);
        return true;
    }

     
    function setCanClaimPartnerBonusTokensPhase1(bool _canClaimTokens) external onlyAdmin returns (bool) {
        bool _oldCanClaim = canClaimPartnerBonusTokensPhase1;
        canClaimPartnerBonusTokensPhase1 = _canClaimTokens;
        CanClaimTokensUpdated(msg.sender, 'canClaimPartnerBonusTokensPhase1', _oldCanClaim, _canClaimTokens);
        return true;
    }

     
    function setCanClaimPartnerBonusTokensPhase2(bool _canClaimTokens) external onlyAdmin returns (bool) {
        bool _oldCanClaim = canClaimPartnerBonusTokensPhase2;
        canClaimPartnerBonusTokensPhase2 = _canClaimTokens;
        CanClaimTokensUpdated(msg.sender, 'canClaimPartnerBonusTokensPhase2', _oldCanClaim, _canClaimTokens);
        return true;
    }

     
    function setCrowdsaleContract(Crowdsale _crowdsaleContract) public onlyOwner returns (bool) {
        address old_crowdsale_address = crowdsaleContract;

        crowdsaleContract = _crowdsaleContract;

        CrowdsaleContractUpdated(msg.sender, old_crowdsale_address, crowdsaleContract);

        return true;
    }
}

contract Crowdsale is ACLManaged, CrowdsaleConfig {

    using SafeMath for uint256;

     
     
     

     
    J8TToken public tokenContract;

     
    Ledger public ledgerContract;

     
    uint256 public startTimestamp;

     
    uint256 public endTimestamp;

     
    uint256 public tokensPerEther;

     
     
    uint256 public weiRaised;

     
    uint256 public totalTokensSold;

     
    uint256 public minContribution;
    uint256 public maxContribution;

     
    address public wallet;

     
    bool public isFinalized = false;

     
     
     
     
     
    mapping(address => WhitelistPermission) public whitelist;

     
    mapping(address => bool) public hasContributed;

    enum WhitelistPermission {
        CannotContribute, PreSaleContributor, PublicSaleContributor 
    }

     
     
     

     
    event TokensPurchased(address _contributor, uint256 _amount);

     
    event WhiteListUpdated(address _who, address _account, WhitelistPermission _phase);

     
    event ContractCreated();

     
     
    event PresaleAdded(address _contributor, uint256 _amount, uint8 _phase);

     
    event TokensPerEtherUpdated(address _who, uint256 _oldValue, uint256 _newValue);

     
    event StartTimestampUpdated(address _who, uint256 _oldValue, uint256 _newValue);

     
    event EndTimestampUpdated(address _who, uint256 _oldValue, uint256 _newValue);

     
    event WalletUpdated(address _who, address _oldWallet, address _newWallet);

     
    event MinContributionUpdated(address _who, uint256 _oldValue, uint256 _newValue);

     
    event MaxContributionUpdated(address _who, uint256 _oldValue, uint256 _newValue);

     
    event Finalized(address _who, uint256 _timestamp);

     
     
    event Burned(address _who, uint256 _amount, uint256 _timestamp);

     
     
     
    

     
     
    function Crowdsale(
        J8TToken _tokenContract,
        Ledger _ledgerContract,
        address _wallet
    ) public
    {
        uint256 _start            = START_TIMESTAMP;
        uint256 _end              = END_TIMESTAMP;
        uint256 _supply           = TOKEN_SALE_SUPPLY;
        uint256 _min_contribution = MIN_CONTRIBUTION_WEIS;
        uint256 _max_contribution = MAX_CONTRIBUTION_WEIS;
        uint256 _tokensPerEther   = INITIAL_TOKENS_PER_ETHER;

        require(_start > currentTime());
        require(_end > _start);
        require(_tokensPerEther > 0);
        require(address(_tokenContract) != address(0));
        require(address(_ledgerContract) != address(0));
        require(_wallet != address(0));

        ledgerContract   = _ledgerContract;
        tokenContract    = _tokenContract;
        startTimestamp   = _start;
        endTimestamp     = _end;
        tokensPerEther   = _tokensPerEther;
        minContribution = _min_contribution;
        maxContribution = _max_contribution;
        wallet           = _wallet;
        totalTokensSold  = 0;
        weiRaised        = 0;
        isFinalized      = false;  

        ContractCreated();
    }

     
    function setTokensPerEther(uint256 _tokensPerEther) external onlyAdmin onlyBeforeSale returns (bool) {
        require(_tokensPerEther > 0);

        uint256 _oldValue = tokensPerEther;
        tokensPerEther = _tokensPerEther;

        TokensPerEtherUpdated(msg.sender, _oldValue, tokensPerEther);
        return true;
    }

     
    function setStartTimestamp(uint256 _start) external onlyAdmin returns (bool) {
        require(_start < endTimestamp);
        require(_start > currentTime());

        uint256 _oldValue = startTimestamp;
        startTimestamp = _start;

        StartTimestampUpdated(msg.sender, _oldValue, startTimestamp);

        return true;
    }

     
    function setEndTimestamp(uint256 _end) external onlyAdmin returns (bool) {
        require(_end > startTimestamp);

        uint256 _oldValue = endTimestamp;
        endTimestamp = _end;

        EndTimestampUpdated(msg.sender, _oldValue, endTimestamp);
        
        return true;
    }

     
    function updateWallet(address _newWallet) external onlyAdmin returns (bool) {
        require(_newWallet != address(0));
        
        address _oldValue = wallet;
        wallet = _newWallet;
        
        WalletUpdated(msg.sender, _oldValue, wallet);
        
        return true;
    }

     
    function setMinContribution(uint256 _newMinContribution) external onlyAdmin returns (bool) {
        require(_newMinContribution <= maxContribution);

        uint256 _oldValue = minContribution;
        minContribution = _newMinContribution;
        
        MinContributionUpdated(msg.sender, _oldValue, minContribution);
        
        return true;
    }

     
    function setMaxContribution(uint256 _newMaxContribution) external onlyAdmin returns (bool) {
        require(_newMaxContribution > minContribution);

        uint256 _oldValue = maxContribution;
        maxContribution = _newMaxContribution;
        
        MaxContributionUpdated(msg.sender, _oldValue, maxContribution);
        
        return true;
    }

     
    function () external payable {
        purchaseTokens();
    }

     
     
    function revokePresale(address _contributor, uint8 _contributorPhase) external onlyAdmin returns (bool) {
        require(_contributor != address(0));

         
         
        require(_contributorPhase == 0 || _contributorPhase == 1);

        uint256 luckys = ledgerContract.revokeAllocation(_contributor, _contributorPhase);
        
        require(luckys > 0);
        require(luckys <= totalTokensSold);
        
        totalTokensSold = totalTokensSold.sub(luckys);
        
        return true;
    }

     
     
    function addPresale(address _contributor, uint256 _tokens, uint256 _bonus, uint8 _contributorPhase) external onlyAdminAndOps onlyBeforeSale returns (bool) {
        require(_tokens > 0);
        require(_bonus > 0);

         
        uint256 luckys = _tokens.mul(J8T_DECIMALS_FACTOR);
        uint256 bonusLuckys = _bonus.mul(J8T_DECIMALS_FACTOR);
        uint256 totalTokens = luckys.add(bonusLuckys);

        uint256 availableTokensToPurchase = tokenContract.balanceOf(address(this));
        
        require(totalTokens <= availableTokensToPurchase);

         
        require(ledgerContract.addAllocation(_contributor, luckys, bonusLuckys, _contributorPhase));
         
        require(tokenContract.transfer(address(ledgerContract), totalTokens));

         
        totalTokensSold = totalTokensSold.add(totalTokens);

         
        availableTokensToPurchase = tokenContract.balanceOf(address(this));
        if (availableTokensToPurchase == 0) {
            finalization();
        }

         
        PresaleAdded(_contributor, totalTokens, _contributorPhase);
    }

     
    function purchaseTokens() public payable onlyDuringSale returns (bool) {
        address contributor = msg.sender;
        uint256 weiAmount = msg.value;

         
        require(hasContributed[contributor] == false);
         
        require(contributorCanContribute(contributor));
         
        require(weiAmount >= minContribution);
         
        require(weiAmount <= maxContribution);
         
        require(totalTokensSold < TOKEN_SALE_SUPPLY);
        uint256 availableTokensToPurchase = TOKEN_SALE_SUPPLY.sub(totalTokensSold);

         
        uint256 luckyPerEther = tokensPerEther.mul(J8T_DECIMALS_FACTOR);

         
         
         
        uint256 tokensAmount = weiAmount.mul(luckyPerEther).div(ETH_DECIMALS_FACTOR);
        

        uint256 refund = 0;
        uint256 tokensToPurchase = tokensAmount;
        
         
         
        if (availableTokensToPurchase < tokensAmount) {
            tokensToPurchase = availableTokensToPurchase;
            weiAmount = tokensToPurchase.mul(ETH_DECIMALS_FACTOR).div(luckyPerEther);
            refund = msg.value.sub(weiAmount);
        }

         
        totalTokensSold = totalTokensSold.add(tokensToPurchase);
        uint256 weiToPurchase = tokensToPurchase.div(tokensPerEther);
        weiRaised = weiRaised.add(weiToPurchase);

         
        require(tokenContract.transfer(contributor, tokensToPurchase));

         
        if (refund > 0) {
            contributor.transfer(refund);
        }

         
        wallet.transfer(weiAmount);

         
        hasContributed[contributor] = true;

        TokensPurchased(contributor, tokensToPurchase);

         
        if (totalTokensSold == TOKEN_SALE_SUPPLY) {
            finalization();
        }

        return true;
    }

     
    function updateWhitelist(address _account, WhitelistPermission _permission) external onlyAdminAndOps returns (bool) {
        require(_account != address(0));
        require(_permission == WhitelistPermission.PreSaleContributor || _permission == WhitelistPermission.PublicSaleContributor || _permission == WhitelistPermission.CannotContribute);
        require(!saleHasFinished());

        whitelist[_account] = _permission;

        address _who = msg.sender;
        WhiteListUpdated(_who, _account, _permission);

        return true;
    }

    function updateWhitelist_batch(address[] _accounts, WhitelistPermission _permission) external onlyAdminAndOps returns (bool) {
        require(_permission == WhitelistPermission.PreSaleContributor || _permission == WhitelistPermission.PublicSaleContributor || _permission == WhitelistPermission.CannotContribute);
        require(!saleHasFinished());

        for(uint i = 0; i < _accounts.length; ++i) {
            require(_accounts[i] != address(0));
            whitelist[_accounts[i]] = _permission;
            WhiteListUpdated(msg.sender, _accounts[i], _permission);
        }

        return true;
    }

     
     
     
     
     
    function contributorCanContribute(address _contributorAddress) private view returns (bool) {
        WhitelistPermission _contributorPhase = whitelist[_contributorAddress];

        if (_contributorPhase == WhitelistPermission.CannotContribute) {
            return false;
        }

        if (_contributorPhase == WhitelistPermission.PreSaleContributor || 
            _contributorPhase == WhitelistPermission.PublicSaleContributor) {
            return true;
        }

        return false;
    }

     
    function currentTime() public view returns (uint256) {
        return now;
    }

     
    function saleHasFinished() public view returns (bool) {
        if (isFinalized) {
            return true;
        }

        if (endTimestamp < currentTime()) {
            return true;
        }

        if (totalTokensSold == TOKEN_SALE_SUPPLY) {
            return true;
        }

        return false;
    }

    modifier onlyBeforeSale() {
        require(currentTime() < startTimestamp);
        _;
    }

    modifier onlyDuringSale() {
        uint256 _currentTime = currentTime();
        require(startTimestamp < _currentTime);
        require(_currentTime < endTimestamp);
        _;
    }

    modifier onlyPostSale() {
        require(endTimestamp < currentTime());
        _;
    }

     
     
     

     
    function finalize() external onlyAdmin returns (bool) {
        return finalization();
    }

     
     
     
     
    function finalization() private returns (bool) {
        require(!isFinalized);

        isFinalized = true;

        
        if (totalTokensSold < TOKEN_SALE_SUPPLY) {
            uint256 toBurn = TOKEN_SALE_SUPPLY.sub(totalTokensSold);
            tokenContract.burn(toBurn);
            Burned(msg.sender, toBurn, currentTime());
        }

        Finalized(msg.sender, currentTime());

        return true;
    }

    function saleSupply() public view returns (uint256) {
        return tokenContract.balanceOf(address(this));
    }
}