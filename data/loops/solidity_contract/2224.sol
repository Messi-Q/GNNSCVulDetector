pragma solidity ^0.4.18;
 

contract Token {
 
    uint256 public totalSupply;

 
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _who, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _who) public constant returns (uint256 remaining);

 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


 
contract StandardToken is Token {

 
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

 

     
     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        Transfer(msg.sender, _to, _value);

        return true;
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
         
        require(_from != 0x0);
        require(_to != 0x0);
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);

        return true;
    }

     
     
     
     
     
    function approve(address _who, uint256 _value) public returns (bool) {

         
        require(_who != 0x0);

         
         
         
         
        require(_value == 0 || allowed[msg.sender][_who] == 0);

        allowed[msg.sender][_who] = _value;
        Approval(msg.sender, _who, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _who) constant public returns (uint256)
    {
        return allowed[_owner][_who];
    }

     
     
     
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }
}


 
contract GoToken is StandardToken {
 

 
    string constant public name = "GoToken";
    string constant public symbol = "GOT";
    uint256 constant public decimals = 18;
    uint256 constant multiplier = 10 ** (decimals);

 
    event Deployed(uint256 indexed _total_supply);
     

 

     
     
     
     
     
    function GoToken(address auction_address, address wallet_address, uint256 initial_supply) public
    {
         
        require(auction_address != 0x0);
        require(wallet_address != 0x0);

         
        require(initial_supply > multiplier);

         
        totalSupply = initial_supply;

         
        balances[auction_address] = initial_supply / 2;
        balances[wallet_address] = initial_supply / 2;

         
        Transfer(0x0, auction_address, balances[auction_address]);
        Transfer(0x0, wallet_address, balances[wallet_address]);

        Deployed(totalSupply);

        assert(totalSupply == balances[auction_address] + balances[wallet_address]);
    }

}


 
 
 
 
contract GoTokenDutchAuction {
 

 

    GoToken public token;
    address public owner_address;
    address public wallet_address;
    address public whitelister_address;
    address public distributor_address;

     
    uint256 constant public bid_threshold = 10 finney;

     
     

     
    uint256 public token_multiplier;

     
    uint256 public num_tokens_auctioned;

 

     
    uint256 public price_start;

    uint256 constant public CURVE_CUTOFF_DURATION = 8 days;

     
    uint256 public price_constant1;

     
    uint256 public price_exponent1;

     
    uint256 public price_constant2;

     
    uint256 public price_exponent2;

     
    uint256 public privatesale_start_time;

     
    uint256 public auction_start_time;
    uint256 public end_time;
    uint256 public start_block;

     
    uint256 public received_wei;
    uint256 public received_wei_with_bonus;

     
    uint256 public funds_claimed;

     
    uint256 public final_price;

    struct Account {
  		uint256 accounted;	 
  		uint256 received;	 
  	}

     
    mapping (address => Account) public bids;

     
    mapping (address => bool) public privatesalewhitelist;

     
    mapping (address => bool) public publicsalewhitelist;

 
     
  	uint256 constant public BONUS_DAY1_DURATION = 24 hours;  

  	 
  	uint256 constant public BONUS_DAY2_DURATION = 48 hours;  

  	 
  	uint256 constant public BONUS_DAY3_DURATION = 72 hours;  

     
  	uint256 public currentBonus = 0;

     
    uint256 constant public TOKEN_CLAIM_WAIT_PERIOD = 0 days;

     
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
        require(msg.sender == owner_address);
        _;
    }

     
     
    modifier isWhitelister() {
        require(msg.sender == whitelister_address);
        _;
    }

     
     
    modifier isDistributor() {
        require(msg.sender == distributor_address);
        _;
    }
 

    event Deployed(uint256 indexed _price_start, uint256 _price_constant1, uint256 _price_exponent1, uint256  _price_constant2, uint256 _price_exponent2);
    event Setup();
    event AuctionStarted(uint256 indexed _auction_start_time, uint256 indexed _block_number);
    event BidSubmission(address indexed _sender,uint256 _amount, uint256 _amount_with_bonus, uint256 _remaining_funds_to_end_auction);
    event ClaimedTokens(address indexed _recipient, uint256 _sent_amount);
    event AuctionEnded(uint256 _final_price);
    event TokensDistributed();

     
  	event PrivateSaleWhitelisted(address indexed who);
    event RemovedFromPrivateSaleWhitelist(address indexed who);
    event PublicSaleWhitelisted(address indexed who);
    event RemovedFromPublicSaleWhitelist(address indexed who);

 

     
     
     
    function GoTokenDutchAuction(
        address _wallet_address,
        address _whitelister_address,
        address _distributor_address,
        uint256 _price_start,
        uint256 _price_constant1,
        uint256 _price_exponent1,
        uint256 _price_constant2,
        uint256 _price_exponent2)
        public
    {
         
        require(_wallet_address != 0x0);
        require(_whitelister_address != 0x0);
        require(_distributor_address != 0x0);
        wallet_address = _wallet_address;
        whitelister_address = _whitelister_address;
        distributor_address = _distributor_address;

        owner_address = msg.sender;
        stage = Stages.AuctionDeployed;
        changePriceCurveSettings(_price_start, _price_constant1, _price_exponent1, _price_constant2, _price_exponent2);
        Deployed(_price_start, _price_constant1, _price_exponent1, _price_constant2, _price_exponent2);
    }

     
    function () public payable {
        bid();
    }

     
     
     
    function setup(address _token_address) public isOwner atStage(Stages.AuctionDeployed) {
        require(_token_address != 0x0);
        token = GoToken(_token_address);

         
         
        num_tokens_auctioned = token.balanceOf(address(this));

         
        token_multiplier = 10 ** (token.decimals());

         
        stage = Stages.AuctionSetUp;
        Setup();
    }

     
     
     
     
     
     
     
     
     
    function changePriceCurveSettings(
        uint256 _price_start,
        uint256 _price_constant1,
        uint256 _price_exponent1,
        uint256 _price_constant2,
        uint256 _price_exponent2)
        internal
    {
         
         
        require(stage == Stages.AuctionDeployed || stage == Stages.AuctionSetUp);
        require(_price_start > 0);
        require(_price_constant1 > 0);
        require(_price_constant2 > 0);

        price_start = _price_start;
        price_constant1 = _price_constant1;
        price_exponent1 = _price_exponent1;
        price_constant2 = _price_constant2;
        price_exponent2 = _price_exponent2;
    }

 
     
     
     
    function addToPublicSaleWhitelist(address[] _bidder_addresses) public isWhitelister {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
            require(!privatesalewhitelist[_bidder_addresses[i]]);  
            publicsalewhitelist[_bidder_addresses[i]] = true;
            PublicSaleWhitelisted(_bidder_addresses[i]);
        }
    }

     
     
     
    function removeFromPublicSaleWhitelist(address[] _bidder_addresses) public isWhitelister {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
            publicsalewhitelist[_bidder_addresses[i]] = false;
            RemovedFromPublicSaleWhitelist(_bidder_addresses[i]);
        }
    }

     

  	 
     
     
    function addToPrivateSaleWhitelist(address[] _bidder_addresses) public isOwner {
        for (uint32 i = 0; i < _bidder_addresses.length; i++) {
              privatesalewhitelist[_bidder_addresses[i]] = true;
  						PrivateSaleWhitelisted(_bidder_addresses[i]);
          }
      }

       
       
       
      function removeFromPrivateSaleWhitelist(address[] _bidder_addresses) public isOwner {
          for (uint32 i = 0; i < _bidder_addresses.length; i++) {
              privatesalewhitelist[_bidder_addresses[i]] = false;
  						RemovedFromPrivateSaleWhitelist(_bidder_addresses[i]);
          }
      }

     
     
    function startAuction() public isOwner atStage(Stages.AuctionSetUp) {
        stage = Stages.AuctionStarted;
        auction_start_time = now;
        start_block = block.number;
        AuctionStarted(auction_start_time, start_block);
    }

     
     
    function bid() public payable
    {
         
         
         
        require(stage == Stages.AuctionSetUp || stage == Stages.AuctionStarted);
        require(privatesalewhitelist[msg.sender] || publicsalewhitelist[msg.sender]);
        if (stage == Stages.AuctionSetUp){
          require(privatesalewhitelist[msg.sender]);
        }
        require(msg.value > 0);
        require(bids[msg.sender].received + msg.value >= bid_threshold);
        assert(bids[msg.sender].received + msg.value >= msg.value);

         
         
         
         

         
        uint256 remaining_funds_to_end_auction = remainingFundsToEndAuction();

         
         
        require(msg.value <= remaining_funds_to_end_auction);

 
         
        if (stage == Stages.AuctionSetUp){
          require(privatesalewhitelist[msg.sender]);
          currentBonus = 25;  
        }
        else if (stage == Stages.AuctionStarted) {
           
      		if (privatesalewhitelist[msg.sender] && now >= auction_start_time  && now < auction_start_time + BONUS_DAY1_DURATION) {
      				currentBonus = 25;  
      		}
          else if (privatesalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY1_DURATION && now < auction_start_time + BONUS_DAY2_DURATION ) {
      				currentBonus = 25;  
      		}
      		else if (privatesalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY2_DURATION && now < auction_start_time + BONUS_DAY3_DURATION) {
      				currentBonus = 25;  
      		}
          else if (privatesalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY3_DURATION) {
              currentBonus = 25;  
          }
          else if (publicsalewhitelist[msg.sender] && now >= auction_start_time  && now < auction_start_time + BONUS_DAY1_DURATION) {
      				currentBonus = 15;  
      		}
          else if (publicsalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY1_DURATION && now < auction_start_time + BONUS_DAY2_DURATION ) {
      				currentBonus = 10;  
      		}
      		else if (publicsalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY2_DURATION && now < auction_start_time + BONUS_DAY3_DURATION) {
      				currentBonus = 5;  
      		}
          else if (publicsalewhitelist[msg.sender] && now >= auction_start_time + BONUS_DAY3_DURATION) {
              currentBonus = 0;  
          }
      		else {
      				currentBonus = 0;
      		}
        }
        else {
          currentBonus = 0;
        }

         
        uint256 accounted = msg.value + msg.value * (currentBonus) / 100;

         
    		bids[msg.sender].accounted += accounted;  
    		bids[msg.sender].received += msg.value;

         
        received_wei += msg.value;
        received_wei_with_bonus += accounted;

         
        wallet_address.transfer(msg.value);

         
        BidSubmission(msg.sender, msg.value, accounted, remaining_funds_to_end_auction);

        assert(received_wei >= msg.value);
        assert(received_wei_with_bonus >= accounted);
    }

     
     
     
     
    function finalizeAuction() public isOwner
    {
         
         
        require(stage == Stages.AuctionSetUp || stage == Stages.AuctionStarted);

         
        final_price = token_multiplier * received_wei_with_bonus / num_tokens_auctioned;

         
        end_time = now;
        stage = Stages.AuctionEnded;
        AuctionEnded(final_price);

        assert(final_price > 0);
    }

     
     
     
    function distributeGoTokens(address receiver_address)
        public isDistributor atStage(Stages.AuctionEnded) returns (bool)
    {
         
         
         
        require(now > end_time + TOKEN_CLAIM_WAIT_PERIOD);
        require(receiver_address != 0x0);
        require(bids[receiver_address].received > 0);

        if (bids[receiver_address].received == 0 || bids[receiver_address].accounted == 0) {
            return false;
        }

         
         
        uint256 num = (token_multiplier * bids[receiver_address].accounted) / final_price;

         
         
         
        uint256 auction_tokens_balance = token.balanceOf(address(this));
        if (num > auction_tokens_balance) {
            num = auction_tokens_balance;
        }

         
        funds_claimed += bids[receiver_address].received;

         
        bids[receiver_address].accounted = 0;
        bids[receiver_address].received = 0;

         
        require(token.transfer(receiver_address, num));

         
        ClaimedTokens(receiver_address, num);

         
         
        if (funds_claimed == received_wei) {
            stage = Stages.TokensDistributed;
            TokensDistributed();
        }

        assert(token.balanceOf(receiver_address) >= num);
        assert(bids[receiver_address].accounted == 0);
        assert(bids[receiver_address].received == 0);
        return true;
    }

     
     
     
     
     
    function price() public constant returns (uint256) {
        if (stage == Stages.AuctionEnded ||
            stage == Stages.TokensDistributed) {
            return 0;
        }
        return calcTokenPrice();
    }

     
     
     
     
    function remainingFundsToEndAuction() constant public returns (uint256) {

         
        uint256 required_wei_at_price = num_tokens_auctioned * price() / token_multiplier;
        if (required_wei_at_price <= received_wei) {
            return 0;
        }

        return required_wei_at_price - received_wei;
    }

 

     
     
     
     
     
     
     
     
     
     
     
     
     

    function calcTokenPrice() constant private returns (uint256) {
        uint256 elapsed;
        uint256 decay_rate1;
        uint256 decay_rate2;
        if (stage == Stages.AuctionDeployed || stage == Stages.AuctionSetUp){
          return price_start;
        }
        if (stage == Stages.AuctionStarted) {
            elapsed = now - auction_start_time;
             
            if (now >= auction_start_time && now < auction_start_time + CURVE_CUTOFF_DURATION){
              decay_rate1 = elapsed ** price_exponent1 / price_constant1;
              return price_start * (1 + elapsed) / (1 + elapsed + decay_rate1);
            }
             
            else if (now >= auction_start_time && now >= auction_start_time + CURVE_CUTOFF_DURATION){
              decay_rate2 = elapsed ** price_exponent2 / price_constant2;
              return price_start * (1 + elapsed) / (1 + elapsed + decay_rate2);
            }
            else {
              return price_start;
            }

        }
    }

}