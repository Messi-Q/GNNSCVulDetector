pragma solidity ^0.4.18;


 
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


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}



 
contract CrowdsaleConfig {
    uint256 public constant TOKEN_DECIMALS = 18;
    uint256 public constant MIN_TOKEN_UNIT = 10 ** uint256(TOKEN_DECIMALS);

     
    uint256 public constant TOTAL_SUPPLY_CAP = 6000000000 * MIN_TOKEN_UNIT;

     
    uint256 public constant SALE_CAP = 1980000000 * MIN_TOKEN_UNIT;

     
    uint256 public constant PURCHASER_MIN_TOKEN_CAP = 6666 * MIN_TOKEN_UNIT;

     
    uint256 public constant PURCHASER_MAX_TOKEN_CAP_DAY1 = 200000 * MIN_TOKEN_UNIT;

     
    uint256 public constant PURCHASER_MAX_TOKEN_CAP = 1200000 * MIN_TOKEN_UNIT;

     
    uint256 public constant FOUNDATION_POOL_TOKENS = 876666666 * MIN_TOKEN_UNIT;
    uint256 public constant FOUNDATION_POOL_TOKENS_VESTED = 113333334 * MIN_TOKEN_UNIT;

     
    uint256 public constant COMMUNITY_POOL_TOKENS = 1980000000 * MIN_TOKEN_UNIT;

     
    uint256 public constant FOUNDERS_TOKENS = 330000000 * MIN_TOKEN_UNIT;
    uint256 public constant FOUNDERS_TOKENS_VESTED_1 = 330000000 * MIN_TOKEN_UNIT;
    uint256 public constant FOUNDERS_TOKENS_VESTED_2 = 330000000 * MIN_TOKEN_UNIT;

     
    uint256 public constant LEGAL_EXPENSES_1_TOKENS = 54000000 * MIN_TOKEN_UNIT;
    uint256 public constant LEGAL_EXPENSES_2_TOKENS = 6000000 * MIN_TOKEN_UNIT;

     
    uint256 public constant TOKEN_PRICE_THOUSANDTH = 15;   

     
    address public constant CROWDSALE_WALLET_ADDR = 0xE0831b1687c9faD3447a517F9371E66672505dB0;
    address public constant FOUNDATION_POOL_ADDR = 0xD68947892Ef4D94Cdef7165b109Cf6Cd3f58A8e8;
    address public constant FOUNDATION_POOL_ADDR_VEST = 0xd0C24Bb82e71A44eA770e84A3c79979F9233308D;
    address public constant COMMUNITY_POOL_ADDR = 0x0506c5485AE54aB14C598Ef16C459409E5d8Fc03;
    address public constant FOUNDERS_POOL_ADDR = 0x4452d6454e777743a5Ee233fbe873055008fF528;
    address public constant LEGAL_EXPENSES_ADDR_1 = 0xb57911380F13A0a9a6Ba6562248674B5f56D7BFE;
    address public constant LEGAL_EXPENSES_ADDR_2 = 0x9be281CdcF34B3A01468Ad1008139410Ba5BB2fB;

     
    uint64 public constant PRECOMMITMENT_VESTING_SECONDS = 15552000;
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

 









 
contract SelfKeyToken is MintableToken {
    string public constant name = 'SelfKey';  
    string public constant symbol = 'KEY';  
    uint256 public constant decimals = 18;  

    uint256 public cap;
    bool private transfersEnabled = false;

    event Burned(address indexed burner, uint256 value);

     
    modifier canTransfer(address _sender, uint256 _value) {
        require(transfersEnabled || _sender == owner);
        _;
    }

     
    function SelfKeyToken(uint256 _cap) public {
        cap = _cap;
    }

     
    function mint(address _to, uint256 _value) public onlyOwner canMint returns (bool) {
        require(totalSupply.add(_value) <= cap);
        return super.mint(_to, _value);
    }

     
    function transfer(address _to, uint256 _value)
        public canTransfer(msg.sender, _value) returns (bool)
    {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public canTransfer(_from, _value) returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

     
    function enableTransfers() public onlyOwner {
        transfersEnabled = true;
    }

     
    function burn(uint256 _value) public onlyOwner {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burned(burner, _value);
    }
}












 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}






 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}



 
 
contract SelfKeyCrowdsale is Ownable, CrowdsaleConfig {
    using SafeMath for uint256;
    using SafeERC20 for SelfKeyToken;

     
    mapping(address => bool) public isVerifier;

     
    SelfKeyToken public token;

    uint64 public startTime;
    uint64 public endTime;

     
    uint256 public goal;

     
    uint256 public rate = 51800;

     
    uint256 public ethPrice = 777;

     
    uint256 public totalPurchased = 0;

    mapping(address => bool) public kycVerified;
    mapping(address => uint256) public tokensPurchased;

     
    mapping(address => address) public vestedTokens;

    bool public isFinalized = false;

     
    TokenTimelock public foundersTimelock1;
    TokenTimelock public foundersTimelock2;
    TokenTimelock public foundationTimelock;

     
    RefundVault public vault;

     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    event VerifiedKYC(address indexed participant);

    event AddedPrecommitment(
        address indexed participant,
        uint256 tokensAllocated
    );

    event Finalized();

    modifier verifierOnly() {
        require(isVerifier[msg.sender]);
        _;
    }

     
    function SelfKeyCrowdsale(
        uint64 _startTime,
        uint64 _endTime,
        uint256 _goal
    ) public
    {
        require(_endTime > _startTime);

         
        isVerifier[msg.sender] = true;

        token = new SelfKeyToken(TOTAL_SUPPLY_CAP);

         
        token.mint(address(this), TOTAL_SUPPLY_CAP);
        token.finishMinting();

        startTime = _startTime;
        endTime = _endTime;
        goal = _goal;

        vault = new RefundVault(CROWDSALE_WALLET_ADDR);

         
        uint64 sixMonthLock = uint64(startTime + 15552000);
        uint64 yearLock = uint64(startTime + 31104000);

         
        foundersTimelock1 = new TokenTimelock(token, FOUNDERS_POOL_ADDR, sixMonthLock);
        foundersTimelock2 = new TokenTimelock(token, FOUNDERS_POOL_ADDR, yearLock);
        foundationTimelock = new TokenTimelock(token, FOUNDATION_POOL_ADDR_VEST, yearLock);

         
        token.safeTransfer(FOUNDATION_POOL_ADDR, FOUNDATION_POOL_TOKENS);
        token.safeTransfer(COMMUNITY_POOL_ADDR, COMMUNITY_POOL_TOKENS);
        token.safeTransfer(FOUNDERS_POOL_ADDR, FOUNDERS_TOKENS);
        token.safeTransfer(LEGAL_EXPENSES_ADDR_1, LEGAL_EXPENSES_1_TOKENS);
        token.safeTransfer(LEGAL_EXPENSES_ADDR_2, LEGAL_EXPENSES_2_TOKENS);

         
        token.safeTransfer(foundersTimelock1, FOUNDERS_TOKENS_VESTED_1);
        token.safeTransfer(foundersTimelock2, FOUNDERS_TOKENS_VESTED_2);
        token.safeTransfer(foundationTimelock, FOUNDATION_POOL_TOKENS_VESTED);
    }

     
    function () public payable {
        buyTokens(msg.sender);
    }

     
    function addVerifier (address _address) public onlyOwner {
        isVerifier[_address] = true;
    }

     
    function removeVerifier (address _address) public onlyOwner {
        isVerifier[_address] = false;
    }

     
    function setStartTime (uint64 _startTime) public onlyOwner {
        require(now < startTime);
        require(_startTime > now);
        require(_startTime < endTime);

        startTime = _startTime;
    }

     
    function setEndTime (uint64 _endTime) public onlyOwner {
        require(now < endTime);
        require(_endTime > now);
        require(_endTime > startTime);

        endTime = _endTime;
    }

     
    function setEthPrice(uint256 _ethPrice) public onlyOwner {
        require(now < startTime);
        require(_ethPrice > 0);

        ethPrice = _ethPrice;
        rate = ethPrice.mul(1000).div(TOKEN_PRICE_THOUSANDTH);
    }

     
    function finalize() public onlyOwner {
        require(now > startTime);
        require(!isFinalized);

        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function claimRefund(address participant) public {
         
        require(isFinalized);
        require(!goalReached());

        vault.refund(participant);
    }

     
    function goalReached() public constant returns (bool) {
        return totalPurchased >= goal;
    }

     
    function releaseLockFounders1() public {
        foundersTimelock1.release();
    }

    function releaseLockFounders2() public {
        foundersTimelock2.release();
    }

    function releaseLockFoundation() public {
        foundationTimelock.release();
    }

     
    function releaseLock(address participant) public {
        require(vestedTokens[participant] != 0x0);

        TokenTimelock timelock = TokenTimelock(vestedTokens[participant]);
        timelock.release();
    }

     
    function verifyKYC(address participant) public verifierOnly {
        kycVerified[participant] = true;

        VerifiedKYC(participant);
    }

     
    function addPrecommitment(
        address beneficiary,
        uint256 tokensAllocated,
        bool halfVesting
    ) public verifierOnly
    {
         
        require(now < startTime);  

        kycVerified[beneficiary] = true;

        uint256 tokens = tokensAllocated;
        totalPurchased = totalPurchased.add(tokens);
        tokensPurchased[beneficiary] = tokensPurchased[beneficiary].add(tokens);

        if (halfVesting) {
             
            uint64 endTimeLock = uint64(startTime + PRECOMMITMENT_VESTING_SECONDS);

             
            uint256 half = tokens.div(2);
            TokenTimelock timelock;

            if (vestedTokens[beneficiary] == 0x0) {
                timelock = new TokenTimelock(token, beneficiary, endTimeLock);
                vestedTokens[beneficiary] = address(timelock);
            } else {
                timelock = TokenTimelock(vestedTokens[beneficiary]);
            }

            token.safeTransfer(beneficiary, half);
            token.safeTransfer(timelock, tokens.sub(half));
        } else {
             
            token.safeTransfer(beneficiary, tokens);
        }

        AddedPrecommitment(
            beneficiary,
            tokens
        );
    }

     
    function finalization() internal {
        if (goalReached()) {
            burnUnsold();
            vault.close();
            token.enableTransfers();
        } else {
            vault.enableRefunds();
        }
    }

     
    function buyTokens(address participant) internal {
        require(kycVerified[participant]);
        require(now >= startTime);
        require(now < endTime);
        require(!isFinalized);
        require(msg.value != 0);

         
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);

         
        tokensPurchased[participant] = tokensPurchased[participant].add(tokens);
        totalPurchased = totalPurchased.add(tokens);

        require(totalPurchased <= SALE_CAP);
        require(tokensPurchased[participant] >= PURCHASER_MIN_TOKEN_CAP);

        if (now < startTime + 86400) {
             
            require(tokensPurchased[participant] <= PURCHASER_MAX_TOKEN_CAP_DAY1);
        } else {
            require(tokensPurchased[participant] <= PURCHASER_MAX_TOKEN_CAP);
        }

         
        vault.deposit.value(msg.value)(participant);
        token.safeTransfer(participant, tokens);

        TokenPurchase(
            msg.sender,
            participant,
            weiAmount,
            tokens
        );
    }

     
    function burnUnsold() internal {
         
        token.burn(token.balanceOf(this));
    }
}