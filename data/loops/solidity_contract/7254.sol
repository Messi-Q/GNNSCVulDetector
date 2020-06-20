 

 

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) {
         
        _from;
        _value;
        _data;
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

contract ERC223Interface {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}


contract BethereumERC223 is ERC223Interface {
    using SafeMath for uint256;

     
    string public constant _name = "Bethereum";
    string public constant _symbol = "BETHER";
    uint8 public constant _decimals = 18;

     
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;

     
    function BethereumERC223() {
        owner = msg.sender;
    }

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed to, uint256 value);

     
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

     
    function balanceOf(address _address) constant returns (uint256 balance) {
        return balances[_address];
    }

     
    function transfer(address _to, uint _value) returns (bool success) {
        if (balances[msg.sender] >= _value
        && _value > 0
        && balances[_to] + _value > balances[_to]) {
            bytes memory empty;
            if(isContract(_to)) {
                return transferToContract(_to, _value, empty);
            } else {
                return transferToAddress(_to, _value, empty);
            }
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value
        && allowed[_from][msg.sender] >= _value
        && _value > 0
        && balances[_to] + _value > balances[_to]) {
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function approve(address _spender, uint256 _allowance) returns (bool success) {
        allowed[msg.sender][_spender] = _allowance;
        Approval(msg.sender, _spender, _allowance);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
     
    function name() constant returns (string name) {
        return _name;
    }

     
    function symbol() constant returns (string symbol) {
        return _symbol;
    }

     
    function decimals() constant returns (uint8 decimals) {
        return _decimals;
    }

     
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if (balances[msg.sender] >= _value
        && _value > 0
        && balances[_to] + _value > balances[_to]) {
            if(isContract(_to)) {
                return transferToContract(_to, _value, _data);
            } else {
                return transferToAddress(_to, _value, _data);
            }
        } else {
            return false;
        }
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

     
    function isContract(address _address) internal returns (bool is_contract) {
        uint length;
        if (_address == 0) return false;
        assembly {
        length := extcodesize(_address)
        }
        if(length > 0) {
            return true;
        } else {
            return false;
        }
    }

     
    function () {
        throw;
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

 
contract PausableToken is BethereumERC223, Pausable {

    function transfer(address _to, uint256 _value, bytes _data) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value, _data);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

}

 
contract MintableToken is BethereumERC223, Ownable {
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

contract BethereumToken is MintableToken, PausableToken {

    function BethereumToken(){
        pause();
    }

}

 
contract Crowdsale {
    using SafeMath for uint256;

     
    MintableToken public token;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Crowdsale(uint256 _endTime, address _wallet) {

        require(_endTime >= now);
        require(_wallet != 0x0);

        token = createTokenContract();
        endTime = _endTime;
        wallet = _wallet;
    }

     
     
    function createTokenContract() internal returns (BethereumToken) {
        return new BethereumToken();
    }


     
    function () payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {  }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

     
    function hasEnded() public constant returns (bool) {
        return now > endTime;
    }
}

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    bool public weiCapReached = false;

    event Finalized();

     
    function finalize() onlyOwner public {
        require(!isFinalized);

        finalization();
        Finalized();

        isFinalized = true;
    }

     
    function finalization() internal {
    }
}

contract BETHERTokenSale is FinalizableCrowdsale {
    using SafeMath for uint256;

     
    uint public constant RATE = 17500;
    uint public constant TOKEN_SALE_LIMIT = 25000 * 1000000000000000000;

    uint256 public constant TOKENS_FOR_OPERATIONS = 400000000*(10**18);
    uint256 public constant TOKENS_FOR_SALE = 600000000*(10**18);

    uint public constant TOKENS_FOR_PRESALE = 315000000*(1 ether / 1 wei);

    uint public BONUS_PERCENTAGE;

    enum Phase {
    Created,
    CrowdsaleRunning,
    Paused
    }

    Phase public currentPhase = Phase.Created;

    event LogPhaseSwitch(Phase phase);

     
    function BETHERTokenSale(
    uint256 _end,
    address _wallet
    )
    FinalizableCrowdsale()
    Crowdsale(_end, _wallet) {
    }

    function setNewBonusScheme(uint _bonusPercentage) {
        BONUS_PERCENTAGE = _bonusPercentage;
    }

    function mintRawTokens(address _buyer, uint256 _newTokens) public onlyOwner {
        token.mint(_buyer, _newTokens);
    }

     
    function buyTokens(address _buyer) public payable {
         
        require(currentPhase == Phase.CrowdsaleRunning);
        require(_buyer != address(0));
        require(msg.value > 0);
        require(validPurchase());

        uint tokensWouldAddTo = 0;
        uint weiWouldAddTo = 0;

        uint256 weiAmount = msg.value;

        uint newTokens = msg.value.mul(RATE);

        weiWouldAddTo = weiRaised.add(weiAmount);

        require(weiWouldAddTo <= TOKEN_SALE_LIMIT);

        newTokens = addBonusTokens(token.totalSupply(), newTokens);

        tokensWouldAddTo = newTokens.add(token.totalSupply());
        require(tokensWouldAddTo <= TOKENS_FOR_SALE);

        token.mint(_buyer, newTokens);
        TokenPurchase(msg.sender, _buyer, weiAmount, newTokens);

        weiRaised = weiWouldAddTo;
        forwardFunds();
        if (weiRaised == TOKENS_FOR_SALE){
            weiCapReached = true;
        }
    }

     
     
     
    function addBonusTokens(uint256 _totalSupply, uint256 _newTokens) internal view returns (uint256) {
        uint returnTokens;
        uint tokens = _newTokens;
        returnTokens = tokens.add(tokens.mul(BONUS_PERCENTAGE).div(100));

        return returnTokens;
    }

    function setSalePhase(Phase _nextPhase) public onlyOwner {
        currentPhase = _nextPhase;
        LogPhaseSwitch(_nextPhase);
    }

    function transferTokenOwnership(address _newOwner) {
        token.transferOwnership(_newOwner);
    }

     
    function finalization() internal {
        uint256 toMint = TOKENS_FOR_OPERATIONS;
        token.mint(wallet, toMint);
        token.finishMinting();
        token.transferOwnership(wallet);
    }
}