 
pragma solidity ^0.4.18;

 
library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

 
contract SharderToken {
    using SafeMath for uint;
    string public constant NAME = "Sharder Storage";
    string public constant SYMBOL = "SS";
    uint public constant DECIMALS = 18;
    uint public totalSupply;

    mapping (address => mapping (address => uint256))  public allowed;
    mapping (address => uint) public balances;

     
     
     
     
     
    address public owner;

     
    address public admin;

    mapping (address => bool) public accountLockup;
    mapping (address => uint) public accountLockupTime;
    mapping (address => bool) public frozenAccounts;

     
     
     
     
     
     
     
     
     
    uint256 internal constant FIRST_ROUND_ISSUED_SS = 350000000000000000000000000;

     
    uint256 public constant HARD_CAP = 1500 ether;

     
    uint256 public constant SOFT_CAP = 1000 ether;

     
     
    uint256 public constant BASE_RATE = 20719;

     
     
    uint256 public constant CONTRIBUTION_MIN = 100 finney;

     
    uint256 public constant CONTRIBUTION_MAX = 5000 finney;

     
    uint256 public soldSS = 0;

    uint8[2] internal bonusPercentages = [
    0,
    0
    ];

    uint256 internal constant MAX_PROMOTION_SS = 0;
    uint internal constant NUM_OF_PHASE = 2;
    uint internal constant BLOCKS_PER_PHASE = 86400;

     
    uint public saleStartAtBlock = 0;

     
    uint public saleEndAtBlock = 0;

     
    bool internal unsoldTokenIssued = false;

     
    bool internal isGoalAchieved = false;

     
    uint256 internal totalEthReceived = 0;

     
    uint256 internal issueIndex = 0;

     
     
    event SaleStarted();

     
    event SaleEnded();

     
    event InvalidCaller(address caller);

     
     
    event InvalidState(bytes msg);

     
    event Issue(uint issueIndex, address addr, uint ethAmount, uint tokenAmount);

     
    event SaleSucceeded();

     
     
     
    event SaleFailed();

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint value);

     
    event Burn(address indexed from, uint256 value);

     
    function _transfer(address _from, address _to, uint _value) internal isNotFrozen {
         
        require(_to != 0x0);
         
        require(balances[_from] >= _value);
         
        require(balances[_to] + _value > balances[_to]);
         
        uint previousBalances = balances[_from] + balances[_to];
         
        balances[_from] -= _value;
         
        balances[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balances[_from] + balances[_to] == previousBalances);
    }

     
    function transfer(address _to, uint _transferTokensWithDecimal) public {
        _transfer(msg.sender, _to, _transferTokensWithDecimal);
    }

     
    function transferFrom(address _from, address _to, uint _transferTokensWithDecimal) public returns (bool success) {
        require(_transferTokensWithDecimal <= allowed[_from][msg.sender]);      
        allowed[_from][msg.sender] -= _transferTokensWithDecimal;
        _transfer(_from, _to, _transferTokensWithDecimal);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint balance) {
        return balances[_owner];
    }

     
    function approve(address _spender, uint256 _approveTokensWithDecimal) public isNotFrozen returns (bool success) {
        allowed[msg.sender][_spender] = _approveTokensWithDecimal;
        Approval(msg.sender, _spender, _approveTokensWithDecimal);
        return true;
    }

     
    function allowance(address _owner, address _spender) internal constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }

     
    function burn(uint256 _burnedTokensWithDecimal) public returns (bool success) {
        require(balances[msg.sender] >= _burnedTokensWithDecimal);    
        balances[msg.sender] -= _burnedTokensWithDecimal;             
        totalSupply -= _burnedTokensWithDecimal;                       
        Burn(msg.sender, _burnedTokensWithDecimal);
        return true;
    }

     
    function burnFrom(address _from, uint256 _burnedTokensWithDecimal) public returns (bool success) {
        require(balances[_from] >= _burnedTokensWithDecimal);                 
        require(_burnedTokensWithDecimal <= allowed[_from][msg.sender]);     
        balances[_from] -= _burnedTokensWithDecimal;                         
        allowed[_from][msg.sender] -= _burnedTokensWithDecimal;              
        totalSupply -= _burnedTokensWithDecimal;                             
        Burn(_from, _burnedTokensWithDecimal);
        return true;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    modifier beforeStart {
        require(!saleStarted());
        _;
    }

    modifier inProgress {
        require(saleStarted() && !saleEnded());
        _;
    }

    modifier afterEnd {
        require(saleEnded());
        _;
    }

    modifier isNotFrozen {
        require( frozenAccounts[msg.sender] != true && now > accountLockupTime[msg.sender] );
        _;
    }

     
    function SharderToken() public {
        owner = msg.sender;
        admin = msg.sender;
        totalSupply = FIRST_ROUND_ISSUED_SS;
    }

     

     
    function setAdmin(address _address) public onlyOwner {
       admin=_address;
    }

     
    function setAccountFrozenStatus(address _address, bool _frozenStatus) public onlyAdmin {
        require(unsoldTokenIssued);
        frozenAccounts[_address] = _frozenStatus;
    }

     
     
     
    function lockupAccount(address _address, uint _lockupSeconds) public onlyAdmin {
        require((accountLockup[_address] && now > accountLockupTime[_address]) || !accountLockup[_address]);

         
        accountLockupTime[_address] = now + _lockupSeconds;
        accountLockup[_address] = true;
    }

     
    function startCrowdsale(uint _saleStartAtBlock) public onlyOwner beforeStart {
        require(_saleStartAtBlock > block.number);
        saleStartAtBlock = _saleStartAtBlock;
        SaleStarted();
    }

     
    function closeCrowdsale() public onlyOwner afterEnd {
        require(!unsoldTokenIssued);

        if (totalEthReceived >= SOFT_CAP) {
            saleEndAtBlock = block.number;
            issueUnsoldToken();
            SaleSucceeded();
        } else {
            SaleFailed();
        }
    }

     
    function goalAchieved() public onlyOwner {
        require(!isGoalAchieved && softCapReached());
        isGoalAchieved = true;
        closeCrowdsale();
    }

     
    function price() public constant returns (uint tokens) {
        return computeTokenAmount(1 ether);
    }

     
     
    function () public payable {
        issueToken(msg.sender);
    }

     
     
    function issueToken(address recipient) public payable inProgress {
         
        require(balances[recipient].div(BASE_RATE).add(msg.value) <= CONTRIBUTION_MAX);
         
        require(CONTRIBUTION_MIN <= msg.value && msg.value <= CONTRIBUTION_MAX);

        uint tokens = computeTokenAmount(msg.value);

        totalEthReceived = totalEthReceived.add(msg.value);
        soldSS = soldSS.add(tokens);

        balances[recipient] = balances[recipient].add(tokens);
        Issue(issueIndex++,recipient,msg.value,tokens);

        require(owner.send(msg.value));
    }

     
     
     
    function issueReserveToken(address recipient, uint256 _issueTokensWithDecimal) onlyOwner public {
        balances[recipient] = balances[recipient].add(_issueTokensWithDecimal);
        totalSupply = totalSupply.add(_issueTokensWithDecimal);
        Issue(issueIndex++,recipient,0,_issueTokensWithDecimal);
    }

     
     
     
     
    function computeTokenAmount(uint ethAmount) internal constant returns (uint tokens) {
        uint phase = (block.number - saleStartAtBlock).div(BLOCKS_PER_PHASE);

         
        if (phase >= bonusPercentages.length) {
            phase = bonusPercentages.length - 1;
        }

        uint tokenBase = ethAmount.mul(BASE_RATE);

         
        uint tokenBonus = 0;
        if(totalEthReceived * BASE_RATE < MAX_PROMOTION_SS) {
            tokenBonus = tokenBase.mul(bonusPercentages[phase]).div(100);
        }

        tokens = tokenBase.add(tokenBonus);
    }

     
    function issueUnsoldToken() internal {
        if (unsoldTokenIssued) {
            InvalidState("Unsold token has been issued already");
        } else {
             
            require(soldSS > 0);

            uint256 unsoldSS = totalSupply.sub(soldSS);
             
            balances[owner] = balances[owner].add(unsoldSS);
            Issue(issueIndex++,owner,0,unsoldSS);

            unsoldTokenIssued = true;
        }
    }

     
    function saleStarted() public constant returns (bool) {
        return (saleStartAtBlock > 0 && block.number >= saleStartAtBlock);
    }

     
     
    function saleEnded() public constant returns (bool) {
        return saleStartAtBlock > 0 && (saleDue() || hardCapReached() || isGoalAchieved);
    }

     
    function saleDue() internal constant returns (bool) {
        return block.number >= saleStartAtBlock + BLOCKS_PER_PHASE * NUM_OF_PHASE;
    }

     
    function hardCapReached() internal constant returns (bool) {
        return totalEthReceived >= HARD_CAP;
    }

     
    function softCapReached() internal constant returns (bool) {
        return totalEthReceived >= SOFT_CAP;
    }
}