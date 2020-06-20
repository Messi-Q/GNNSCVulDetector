 
 
 pragma solidity ^0.4.18;

 

 

 

 


 


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
 
 




 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}
 


 
contract LetsbetToken is PausableToken, BurnableToken {

    string public constant name = "Letsbet Token";
    string public constant symbol = "XBET";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 100000000 * 10**uint256(decimals);  
    uint256 public constant TEAM_TOKENS = 18000000 * 10**uint256(decimals);  
    uint256 public constant BOUNTY_TOKENS = 5000000 * 10**uint256(decimals);  
    uint256 public constant AUCTION_TOKENS = 77000000 * 10**uint256(decimals);  

    event Deployed(uint indexed _totalSupply);

     
    function LetsbetToken(
        address auctionAddress,
        address walletAddress,
        address bountyAddress)
        public
    {

        require(auctionAddress != 0x0);
        require(walletAddress != 0x0);
        require(bountyAddress != 0x0);
        
        totalSupply_ = INITIAL_SUPPLY;

        balances[auctionAddress] = AUCTION_TOKENS;
        balances[walletAddress] = TEAM_TOKENS;
        balances[bountyAddress] = BOUNTY_TOKENS;

        Transfer(0x0, auctionAddress, balances[auctionAddress]);
        Transfer(0x0, walletAddress, balances[walletAddress]);
        Transfer(0x0, bountyAddress, balances[bountyAddress]);

        Deployed(totalSupply_);
        assert(totalSupply_ == balances[auctionAddress] + balances[walletAddress] + balances[bountyAddress]);
    }
} 

 
 
 
contract DutchAuction {
    
	 
     
    uint constant public TOKEN_CLAIM_WAITING_PERIOD = 7 days;

    LetsbetToken public token;
    address public ownerAddress;
    address public walletAddress;

     
    uint public startPrice;

     
    uint public priceDecreaseRate;

     
    uint public startTime;

    uint public endTimeOfBids;

     
    uint public finalizedTime;
    uint public startBlock;

     
    uint public receivedWei;

     
    uint public fundsClaimed;

    uint public tokenMultiplier;

     
    uint public tokensAuctioned;

     
    uint public finalPrice;

     
    mapping (address => uint) public bids;


    Stages public stage;

     
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TokensDistributed
    }

     
    modifier atStage(Stages _stage) {
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        require(msg.sender == ownerAddress);
        _;
    }
	
     
    event Deployed(
        uint indexed _startPrice,
        uint indexed _priceDecreaseRate
    );
    
	event Setup();
    
	event AuctionStarted(uint indexed _startTime, uint indexed _blockNumber);
    
	event BidSubmission(
        address indexed sender,
        uint amount,
        uint missingFunds,
        uint timestamp
    );
    
	event ClaimedTokens(address indexed _recipient, uint _sentAmount);
    
	event AuctionEnded(uint _finalPrice);
    
	event TokensDistributed();

     
     
     
     
     
     
    function DutchAuction(
        address _walletAddress,
        uint _startPrice,
        uint _priceDecreaseRate,
        uint _endTimeOfBids) 
    public
    {
        require(_walletAddress != 0x0);
        walletAddress = _walletAddress;

        ownerAddress = msg.sender;
        stage = Stages.AuctionDeployed;
        changeSettings(_startPrice, _priceDecreaseRate,_endTimeOfBids);
        Deployed(_startPrice, _priceDecreaseRate);
    }

    function () public payable atStage(Stages.AuctionStarted) {
        bid();
    }

     
     
     
    function setup(address _tokenAddress) public isOwner atStage(Stages.AuctionDeployed) {
        require(_tokenAddress != 0x0);
        token = LetsbetToken(_tokenAddress);

         
        tokensAuctioned = token.balanceOf(address(this));

         
        tokenMultiplier = 10 ** uint(token.decimals());

        stage = Stages.AuctionSetUp;
        Setup();
    }

     
     
     
    function changeSettings(
        uint _startPrice,
        uint _priceDecreaseRate,
        uint _endTimeOfBids
        )
        internal
    {
        require(stage == Stages.AuctionDeployed || stage == Stages.AuctionSetUp);
        require(_startPrice > 0);
        require(_priceDecreaseRate > 0);
        require(_endTimeOfBids > now);
        
        endTimeOfBids = _endTimeOfBids;
        startPrice = _startPrice;
        priceDecreaseRate = _priceDecreaseRate;
    }


     
     
    function startAuction() public isOwner atStage(Stages.AuctionSetUp) {
        stage = Stages.AuctionStarted;
        startTime = now;
        startBlock = block.number;
        AuctionStarted(startTime, startBlock);
    }

     
     
     
    function finalizeAuction() public isOwner atStage(Stages.AuctionStarted) {
         
        uint missingFunds = missingFundsToEndAuction();
        require(missingFunds == 0 || now > endTimeOfBids);

         
         
        finalPrice = tokenMultiplier * receivedWei / tokensAuctioned;

        finalizedTime = now;
        stage = Stages.AuctionEnded;
        AuctionEnded(finalPrice);

        assert(finalPrice > 0);
    }

     


     
     
    function bid()
        public
        payable
        atStage(Stages.AuctionStarted)
    {
        require(msg.value > 0);
        assert(bids[msg.sender] + msg.value >= msg.value);

         
        uint missingFunds = missingFundsToEndAuction();

         
         
        require(msg.value <= missingFunds);

        bids[msg.sender] += msg.value;
        receivedWei += msg.value;

         
        walletAddress.transfer(msg.value);

        BidSubmission(msg.sender, msg.value, missingFunds,block.timestamp);

        assert(receivedWei >= msg.value);
    }

     
     
     
    function claimTokens() public atStage(Stages.AuctionEnded) returns (bool) {
        return proxyClaimTokens(msg.sender);
    }

     
     
     
    function proxyClaimTokens(address receiverAddress)
        public
        atStage(Stages.AuctionEnded)
        returns (bool)
    {
         
         
         
        require(now > finalizedTime + TOKEN_CLAIM_WAITING_PERIOD);
        require(receiverAddress != 0x0);

        if (bids[receiverAddress] == 0) {
            return false;
        }

        uint num = (tokenMultiplier * bids[receiverAddress]) / finalPrice;

         
         
         
        uint auctionTokensBalance = token.balanceOf(address(this));
        if (num > auctionTokensBalance) {
            num = auctionTokensBalance;
        }

         
        fundsClaimed += bids[receiverAddress];

         
        bids[receiverAddress] = 0;

        require(token.transfer(receiverAddress, num));

        ClaimedTokens(receiverAddress, num);

         
         
        if (fundsClaimed == receivedWei) {
            stage = Stages.TokensDistributed;
            TokensDistributed();
        }

        assert(token.balanceOf(receiverAddress) >= num);
        assert(bids[receiverAddress] == 0);
        return true;
    }

     
     
     
     
     
    function price() public constant returns (uint) {
        if (stage == Stages.AuctionEnded ||
            stage == Stages.TokensDistributed) {
            return finalPrice;
        }
        return calcTokenPrice();
    }

     
     
     
     
    function missingFundsToEndAuction() constant public returns (uint) {

        uint requiredWei = tokensAuctioned * price() / tokenMultiplier;
        if (requiredWei <= receivedWei) {
            return 0;
        }

        return requiredWei - receivedWei;
    }

     
     
     
     
    function calcTokenPrice() constant private returns (uint) {
        uint currentPrice;
        if (stage == Stages.AuctionStarted) {
            currentPrice = startPrice - priceDecreaseRate * (block.number - startBlock);
        }else {
            currentPrice = startPrice;
        }

        return currentPrice;
    }
}