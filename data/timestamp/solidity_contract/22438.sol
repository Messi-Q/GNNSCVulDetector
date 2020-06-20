 

pragma solidity ^0.4.21;

 

contract LimitedSetup {

    uint constructionTime;
    uint setupDuration;

    function LimitedSetup(uint _setupDuration)
        public
    {
        constructionTime = now;
        setupDuration = _setupDuration;
    }

    modifier setupFunction
    {
        require(now < constructionTime + setupDuration);
        _;
    }
}
 

contract Owned {
    address public owner;
    address public nominatedOwner;

    function Owned(address _owner)
        public
    {
        owner = _owner;
    }

    function nominateOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership()
        external
    {
        require(msg.sender == nominatedOwner);
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner);
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

 

contract Proxy is Owned {
    Proxyable target;

    function Proxy(Proxyable _target, address _owner)
        Owned(_owner)
        public
    {
        target = _target;
        emit TargetChanged(_target);
    }

    function _setTarget(address _target) 
        external
        onlyOwner
    {
        require(_target != address(0));
        target = Proxyable(_target);
        emit TargetChanged(_target);
    }

    function () 
        public
        payable
    {
        target.setMessageSender(msg.sender);
        assembly {
             
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize)

             
            let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize)

             
            if iszero(result) { revert(free_ptr, calldatasize) }
            return(free_ptr, returndatasize)
        } 
    }

    event TargetChanged(address targetAddress);
}

 

contract Proxyable is Owned {
     
    Proxy public proxy;

     
     
     
    address messageSender;

    function Proxyable(address _owner)
        Owned(_owner)
        public { }

    function setProxy(Proxy _proxy)
        external
        onlyOwner
    {
        proxy = _proxy;
        emit ProxyChanged(_proxy);
    }

    function setMessageSender(address sender)
        external
        onlyProxy
    {
        messageSender = sender;
    }

    modifier onlyProxy
    {
        require(Proxy(msg.sender) == proxy);
        _;
    }

    modifier onlyOwner_Proxy
    {
        require(messageSender == owner);
        _;
    }

    modifier optionalProxy
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        _;
    }

     
     
    modifier optionalProxy_onlyOwner
    {
        if (Proxy(msg.sender) != proxy) {
            messageSender = msg.sender;
        }
        require(messageSender == owner);
        _;
    }

    event ProxyChanged(address proxyAddress);

}

 

contract SafeDecimalMath {

     
    uint8 public constant decimals = 18;

     
    uint public constant UNIT = 10 ** uint(decimals);

     
    function addIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return x + y >= y;
    }

     
    function safeAdd(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(x + y >= y);
        return x + y;
    }

     
    function subIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y <= x;
    }

     
    function safeSub(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        require(y <= x);
        return x - y;
    }

     
    function mulIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        if (x == 0) {
            return true;
        }
        return (x * y) / x == y;
    }

     
    function safeMul(uint x, uint y)
        pure
        internal
        returns (uint)
    {
        if (x == 0) {
            return 0;
        }
        uint p = x * y;
        require(p / x == y);
        return p;
    }

     
    function safeMul_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
         
         
        return safeMul(x, y) / UNIT;

    }

     
    function divIsSafe(uint x, uint y)
        pure
        internal
        returns (bool)
    {
        return y != 0;
    }

     
    function safeDiv(uint x, uint y)
        pure
        internal
        returns (uint)
    {
         
         
         
        require(y != 0);
        return x / y;
    }

     
    function safeDiv_dec(uint x, uint y)
        pure
        internal
        returns (uint)
    {
         
        return safeDiv(safeMul(x, UNIT), y);
    }

     
    function intToDec(uint i)
        pure
        internal
        returns (uint)
    {
        return safeMul(i, UNIT);
    }
}

 

contract Court is Owned, SafeDecimalMath {

     

     
    Havven public havven;
    EtherNomin public nomin;

     
     
    uint public minStandingBalance = 100 * UNIT;

     
     
    uint public votingPeriod = 1 weeks;
    uint constant MIN_VOTING_PERIOD = 3 days;
    uint constant MAX_VOTING_PERIOD = 4 weeks;

     
     
     
    uint public confirmationPeriod = 1 weeks;
    uint constant MIN_CONFIRMATION_PERIOD = 1 days;
    uint constant MAX_CONFIRMATION_PERIOD = 2 weeks;

     
     
     
    uint public requiredParticipation = 3 * UNIT / 10;
    uint constant MIN_REQUIRED_PARTICIPATION = UNIT / 10;

     
     
     
    uint public requiredMajority = (2 * UNIT) / 3;
    uint constant MIN_REQUIRED_MAJORITY = UNIT / 2;

     
    uint nextMotionID = 1;

     
    mapping(uint => address) public motionTarget;

     
     
    mapping(address => uint) public targetMotionID;

     
     
     
     
     
     
    mapping(uint => uint) public motionStartTime;

     
     
     
    mapping(uint => uint) public votesFor;
    mapping(uint => uint) public votesAgainst;

     
     
     
     
     
     
    mapping(address => mapping(uint => uint)) voteWeight;

     
     
     
     
    enum Vote {Abstention, Yea, Nay}

     
     
    mapping(address => mapping(uint => Vote)) public vote;

     

    function Court(Havven _havven, EtherNomin _nomin, address _owner)
        Owned(_owner)
        public
    {
        havven = _havven;
        nomin = _nomin;
    }


     

    function setMinStandingBalance(uint balance)
        external
        onlyOwner
    {
         
         
         
        minStandingBalance = balance;
    }

    function setVotingPeriod(uint duration)
        external
        onlyOwner
    {
        require(MIN_VOTING_PERIOD <= duration &&
                duration <= MAX_VOTING_PERIOD);
         
         
        require(duration <= havven.targetFeePeriodDurationSeconds());
        votingPeriod = duration;
    }

    function setConfirmationPeriod(uint duration)
        external
        onlyOwner
    {
        require(MIN_CONFIRMATION_PERIOD <= duration &&
                duration <= MAX_CONFIRMATION_PERIOD);
        confirmationPeriod = duration;
    }

    function setRequiredParticipation(uint fraction)
        external
        onlyOwner
    {
        require(MIN_REQUIRED_PARTICIPATION <= fraction);
        requiredParticipation = fraction;
    }

    function setRequiredMajority(uint fraction)
        external
        onlyOwner
    {
        require(MIN_REQUIRED_MAJORITY <= fraction);
        requiredMajority = fraction;
    }


     

     
    function motionVoting(uint motionID)
        public
        view
        returns (bool)
    {
         
         
         
         
        return now < motionStartTime[motionID] + votingPeriod;
    }

     
    function motionConfirming(uint motionID)
        public
        view
        returns (bool)
    {
         
         
        uint startTime = motionStartTime[motionID];
        return startTime + votingPeriod <= now &&
               now < startTime + votingPeriod + confirmationPeriod;
    }

     
    function motionWaiting(uint motionID)
        public
        view
        returns (bool)
    {
         
         
        return motionStartTime[motionID] + votingPeriod + confirmationPeriod <= now;
    }

     
    function motionPasses(uint motionID)
        public
        view
        returns (bool)
    {
        uint yeas = votesFor[motionID];
        uint nays = votesAgainst[motionID];
        uint totalVotes = safeAdd(yeas, nays);

        if (totalVotes == 0) {
            return false;
        }

        uint participation = safeDiv_dec(totalVotes, havven.totalSupply());
        uint fractionInFavour = safeDiv_dec(yeas, totalVotes);

         
         
        return participation > requiredParticipation &&
               fractionInFavour > requiredMajority;
    }

    function hasVoted(address account, uint motionID)
        public
        view
        returns (bool)
    {
        return vote[account][motionID] != Vote.Abstention;
    }


     

     
    function beginMotion(address target)
        external
        returns (uint)
    {
         
        require((havven.balanceOf(msg.sender) >= minStandingBalance) ||
                msg.sender == owner);

         
         
        require(votingPeriod <= havven.targetFeePeriodDurationSeconds());

         
        require(targetMotionID[target] == 0);

         
        require(!nomin.frozen(target));

        uint motionID = nextMotionID++;
        motionTarget[motionID] = target;
        targetMotionID[target] = motionID;

        motionStartTime[motionID] = now;
        emit MotionBegun(msg.sender, msg.sender, target, target, motionID, motionID);

        return motionID;
    }

     
    function setupVote(uint motionID)
        internal
        returns (uint)
    {
         
         
        require(motionVoting(motionID));

         
        require(!hasVoted(msg.sender, motionID));

         
        require(msg.sender != motionTarget[motionID]);

         
        havven.recomputeAccountLastAverageBalance(msg.sender);

        uint weight;
         
         
         
        if (motionStartTime[motionID] < havven.feePeriodStartTime()) {
            weight = havven.penultimateAverageBalance(msg.sender);
        } else {
            weight = havven.lastAverageBalance(msg.sender);
        }

         
        require(weight > 0);

        voteWeight[msg.sender][motionID] = weight;

        return weight;
    }

     
    function voteFor(uint motionID)
        external
    {
        uint weight = setupVote(motionID);
        vote[msg.sender][motionID] = Vote.Yea;
        votesFor[motionID] = safeAdd(votesFor[motionID], weight);
        emit VotedFor(msg.sender, msg.sender, motionID, motionID, weight);
    }

     
    function voteAgainst(uint motionID)
        external
    {
        uint weight = setupVote(motionID);
        vote[msg.sender][motionID] = Vote.Nay;
        votesAgainst[motionID] = safeAdd(votesAgainst[motionID], weight);
        emit VotedAgainst(msg.sender, msg.sender, motionID, motionID, weight);
    }

     
    function cancelVote(uint motionID)
        external
    {
         
         
         
         
        require(!motionConfirming(motionID));

        Vote senderVote = vote[msg.sender][motionID];

         
        require(senderVote != Vote.Abstention);

         
        if (motionVoting(motionID)) {
            if (senderVote == Vote.Yea) {
                votesFor[motionID] = safeSub(votesFor[motionID], voteWeight[msg.sender][motionID]);
            } else {
                 
                 
                votesAgainst[motionID] = safeSub(votesAgainst[motionID], voteWeight[msg.sender][motionID]);
            }
             
            emit VoteCancelled(msg.sender, msg.sender, motionID, motionID);
        }

        delete voteWeight[msg.sender][motionID];
        delete vote[msg.sender][motionID];
    }

    function _closeMotion(uint motionID)
        internal
    {
        delete targetMotionID[motionTarget[motionID]];
        delete motionTarget[motionID];
        delete motionStartTime[motionID];
        delete votesFor[motionID];
        delete votesAgainst[motionID];
        emit MotionClosed(motionID, motionID);
    }

     
    function closeMotion(uint motionID)
        external
    {
        require((motionConfirming(motionID) && !motionPasses(motionID)) || motionWaiting(motionID));
        _closeMotion(motionID);
    }

     
    function approveMotion(uint motionID)
        external
        onlyOwner
    {
        require(motionConfirming(motionID) && motionPasses(motionID));
        address target = motionTarget[motionID];
        nomin.confiscateBalance(target);
        _closeMotion(motionID);
        emit MotionApproved(motionID, motionID);
    }

     
    function vetoMotion(uint motionID)
        external
        onlyOwner
    {
        require(!motionWaiting(motionID));
        _closeMotion(motionID);
        emit MotionVetoed(motionID, motionID);
    }


     

    event MotionBegun(address initiator, address indexed initiatorIndex, address target, address indexed targetIndex, uint motionID, uint indexed motionIDIndex);

    event VotedFor(address voter, address indexed voterIndex, uint motionID, uint indexed motionIDIndex, uint weight);

    event VotedAgainst(address voter, address indexed voterIndex, uint motionID, uint indexed motionIDIndex, uint weight);

    event VoteCancelled(address voter, address indexed voterIndex, uint motionID, uint indexed motionIDIndex);

    event MotionClosed(uint motionID, uint indexed motionIDIndex);

    event MotionVetoed(uint motionID, uint indexed motionIDIndex);

    event MotionApproved(uint motionID, uint indexed motionIDIndex);
}

 

contract ExternStateProxyFeeToken is Proxyable, SafeDecimalMath {

     

     
    TokenState public state;

     
    string public name;
    string public symbol;
    uint public totalSupply;

     
    uint public transferFeeRate;
     
    uint constant MAX_TRANSFER_FEE_RATE = UNIT / 10;
     
    address public feeAuthority;


     

    function ExternStateProxyFeeToken(string _name, string _symbol,
                                      uint _transferFeeRate, address _feeAuthority,
                                      TokenState _state, address _owner)
        Proxyable(_owner)
        public
    {
        if (_state == TokenState(0)) {
            state = new TokenState(_owner, address(this));
        } else {
            state = _state;
        }

        name = _name;
        symbol = _symbol;
        transferFeeRate = _transferFeeRate;
        feeAuthority = _feeAuthority;
    }

     

    function setTransferFeeRate(uint _transferFeeRate)
        external
        optionalProxy_onlyOwner
    {
        require(_transferFeeRate <= MAX_TRANSFER_FEE_RATE);
        transferFeeRate = _transferFeeRate;
        emit TransferFeeRateUpdated(_transferFeeRate);
    }

    function setFeeAuthority(address _feeAuthority)
        external
        optionalProxy_onlyOwner
    {
        feeAuthority = _feeAuthority;
        emit FeeAuthorityUpdated(_feeAuthority);
    }

    function setState(TokenState _state)
        external
        optionalProxy_onlyOwner
    {
        state = _state;
        emit StateUpdated(_state);
    }

     

    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return state.balanceOf(account);
    }

    function allowance(address from, address to)
        public
        view
        returns (uint)
    {
        return state.allowance(from, to);
    }

     
    function transferFeeIncurred(uint value)
        public
        view
        returns (uint)
    {
        return safeMul_dec(value, transferFeeRate);
         
         
         
         
         
         
         
    }

     
     
    function transferPlusFee(uint value)
        external
        view
        returns (uint)
    {
        return safeAdd(value, transferFeeIncurred(value));
    }

     
    function priceToSpend(uint value)
        external
        view
        returns (uint)
    {
        return safeDiv_dec(value, safeAdd(UNIT, transferFeeRate));
    }

     
     
    function feePool()
        external
        view
        returns (uint)
    {
        return state.balanceOf(address(this));
    }


     

     
    function _transfer_byProxy(address sender, address to, uint value)
        internal
        returns (bool)
    {
        require(to != address(0));

         
         
        uint fee = transferFeeIncurred(value);
        uint totalCharge = safeAdd(value, fee);

         
        state.setBalanceOf(sender, safeSub(state.balanceOf(sender), totalCharge));
        state.setBalanceOf(to, safeAdd(state.balanceOf(to), value));
        state.setBalanceOf(address(this), safeAdd(state.balanceOf(address(this)), fee));

        emit Transfer(sender, to, value);
        emit TransferFeePaid(sender, fee);
        emit Transfer(sender, address(this), fee);

        return true;
    }

     
    function _transferFrom_byProxy(address sender, address from, address to, uint value)
        internal
        returns (bool)
    {
        require(to != address(0));

         
         
        uint fee = transferFeeIncurred(value);
        uint totalCharge = safeAdd(value, fee);

         
        state.setBalanceOf(from, safeSub(state.balanceOf(from), totalCharge));
        state.setAllowance(from, sender, safeSub(state.allowance(from, sender), totalCharge));
        state.setBalanceOf(to, safeAdd(state.balanceOf(to), value));
        state.setBalanceOf(address(this), safeAdd(state.balanceOf(address(this)), fee));

        emit Transfer(from, to, value);
        emit TransferFeePaid(sender, fee);
        emit Transfer(from, address(this), fee);

        return true;
    }

    function approve(address spender, uint value)
        external
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;
        state.setAllowance(sender, spender, value);

        emit Approval(sender, spender, value);

        return true;
    }

     
    function withdrawFee(address account, uint value)
        external
        returns (bool)
    {
        require(msg.sender == feeAuthority && account != address(0));
        
         
        if (value == 0) {
            return false;
        }

         
        state.setBalanceOf(address(this), safeSub(state.balanceOf(address(this)), value));
        state.setBalanceOf(account, safeAdd(state.balanceOf(account), value));

        emit FeesWithdrawn(account, account, value);
        emit Transfer(address(this), account, value);

        return true;
    }

     
    function donateToFeePool(uint n)
        external
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;

         
        uint balance = state.balanceOf(sender);
        require(balance != 0);

         
        state.setBalanceOf(sender, safeSub(balance, n));
        state.setBalanceOf(address(this), safeAdd(state.balanceOf(address(this)), n));

        emit FeesDonated(sender, sender, n);
        emit Transfer(sender, address(this), n);

        return true;
    }

     

    event Transfer(address indexed from, address indexed to, uint value);

    event TransferFeePaid(address indexed account, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

    event TransferFeeRateUpdated(uint newFeeRate);

    event FeeAuthorityUpdated(address feeAuthority);

    event StateUpdated(address newState);

    event FeesWithdrawn(address account, address indexed accountIndex, uint value);

    event FeesDonated(address donor, address indexed donorIndex, uint value);
}

 

contract EtherNomin is ExternStateProxyFeeToken {

     

     
     
    address public oracle;

     
    Court public court;

     
    address public beneficiary;

     
    uint public nominPool;

     
    uint public poolFeeRate = UNIT / 200;

     
    uint constant MINIMUM_PURCHASE = UNIT / 100;

     
    uint constant MINIMUM_ISSUANCE_RATIO =  2 * UNIT;

     
     
    uint constant AUTO_LIQUIDATION_RATIO = UNIT;

     
     
    uint constant DEFAULT_LIQUIDATION_PERIOD = 90 days;
    uint constant MAX_LIQUIDATION_PERIOD = 180 days;
    uint public liquidationPeriod = DEFAULT_LIQUIDATION_PERIOD;

     
     
     
    uint public liquidationTimestamp = ~uint(0);

     
    uint public etherPrice;

     
    uint public lastPriceUpdate;

     
     
    uint public stalePeriod = 2 days;

     
    mapping(address => bool) public frozen;


     

    function EtherNomin(address _havven, address _oracle,
                        address _beneficiary,
                        uint initialEtherPrice,
                        address _owner, TokenState initialState)
        ExternStateProxyFeeToken("Ether-Backed USD Nomins", "eUSD",
                                 15 * UNIT / 10000,  
                                 _havven,  
                                 initialState,
                                 _owner)
        public
    {
        oracle = _oracle;
        beneficiary = _beneficiary;

        etherPrice = initialEtherPrice;
        lastPriceUpdate = now;
        emit PriceUpdated(etherPrice);

         
        frozen[this] = true;
    }


     

    function setOracle(address _oracle)
        external
        optionalProxy_onlyOwner
    {
        oracle = _oracle;
        emit OracleUpdated(_oracle);
    }

    function setCourt(Court _court)
        external
        optionalProxy_onlyOwner
    {
        court = _court;
        emit CourtUpdated(_court);
    }

    function setBeneficiary(address _beneficiary)
        external
        optionalProxy_onlyOwner
    {
        beneficiary = _beneficiary;
        emit BeneficiaryUpdated(_beneficiary);
    }

    function setPoolFeeRate(uint _poolFeeRate)
        external
        optionalProxy_onlyOwner
    {
        require(_poolFeeRate <= UNIT);
        poolFeeRate = _poolFeeRate;
        emit PoolFeeRateUpdated(_poolFeeRate);
    }

    function setStalePeriod(uint _stalePeriod)
        external
        optionalProxy_onlyOwner
    {
        stalePeriod = _stalePeriod;
        emit StalePeriodUpdated(_stalePeriod);
    }
 

      

     
    function fiatValue(uint eth)
        public
        view
        priceNotStale
        returns (uint)
    {
        return safeMul_dec(eth, etherPrice);
    }

     
    function fiatBalance()
        public
        view
        returns (uint)
    {
         
        return fiatValue(address(this).balance);
    }

     
    function etherValue(uint fiat)
        public
        view
        priceNotStale
        returns (uint)
    {
        return safeDiv_dec(fiat, etherPrice);
    }

     
    function etherValueAllowStale(uint fiat) 
        internal
        view
        returns (uint)
    {
        return safeDiv_dec(fiat, etherPrice);
    }

     
    function collateralisationRatio()
        public
        view
        returns (uint)
    {
        return safeDiv_dec(fiatBalance(), _nominCap());
    }

     
    function _nominCap()
        internal
        view
        returns (uint)
    {
        return safeAdd(nominPool, totalSupply);
    }

     
    function poolFeeIncurred(uint n)
        public
        view
        returns (uint)
    {
        return safeMul_dec(n, poolFeeRate);
    }

     
    function purchaseCostFiat(uint n)
        public
        view
        returns (uint)
    {
        return safeAdd(n, poolFeeIncurred(n));
    }

     
    function purchaseCostEther(uint n)
        public
        view
        returns (uint)
    {
         
        return etherValue(purchaseCostFiat(n));
    }

     
    function saleProceedsFiat(uint n)
        public
        view
        returns (uint)
    {
        return safeSub(n, poolFeeIncurred(n));
    }

     
    function saleProceedsEther(uint n)
        public
        view
        returns (uint)
    {
         
        return etherValue(saleProceedsFiat(n));
    }

     
    function saleProceedsEtherAllowStale(uint n)
        internal
        view
        returns (uint)
    {
        return etherValueAllowStale(saleProceedsFiat(n));
    }

     
    function priceIsStale()
        public
        view
        returns (bool)
    {
        return safeAdd(lastPriceUpdate, stalePeriod) < now;
    }

    function isLiquidating()
        public
        view
        returns (bool)
    {
        return liquidationTimestamp <= now;
    }

     
    function canSelfDestruct()
        public
        view
        returns (bool)
    {
         
         
        if (isLiquidating()) {
             
             
            bool totalPeriodElapsed = liquidationTimestamp + liquidationPeriod < now;
             
            bool allTokensReturned = (liquidationTimestamp + 1 weeks < now) && (totalSupply == 0);
            return totalPeriodElapsed || allTokensReturned;
        }
        return false;
    }


     

     
    function transfer(address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to]);
        return _transfer_byProxy(messageSender, to, value);
    }

     
    function transferFrom(address from, address to, uint value)
        public
        optionalProxy
        returns (bool)
    {
        require(!frozen[to]);
        return _transferFrom_byProxy(messageSender, from, to, value);
    }

     
    function updatePrice(uint price, uint timeSent)
        external
        postCheckAutoLiquidate
    {
         
        require(msg.sender == oracle);
         
         
        require(lastPriceUpdate < timeSent && timeSent < now + 10 minutes);

        etherPrice = price;
        lastPriceUpdate = timeSent;
        emit PriceUpdated(price);
    }

     
    function replenishPool(uint n)
        external
        payable
        notLiquidating
        optionalProxy_onlyOwner
    {
         
         
         
        require(fiatBalance() >= safeMul_dec(safeAdd(_nominCap(), n), MINIMUM_ISSUANCE_RATIO));
        nominPool = safeAdd(nominPool, n);
        emit PoolReplenished(n, msg.value);
    }

     
    function diminishPool(uint n)
        external
        optionalProxy_onlyOwner
    {
         
        require(nominPool >= n);
        nominPool = safeSub(nominPool, n);
        emit PoolDiminished(n);
    }

     
    function buy(uint n)
        external
        payable
        notLiquidating
        optionalProxy
    {
         
        require(n >= MINIMUM_PURCHASE &&
                msg.value == purchaseCostEther(n));
        address sender = messageSender;
         
        nominPool = safeSub(nominPool, n);
        state.setBalanceOf(sender, safeAdd(state.balanceOf(sender), n));
        emit Purchased(sender, sender, n, msg.value);
        emit Transfer(0, sender, n);
        totalSupply = safeAdd(totalSupply, n);
    }

     
    function sell(uint n)
        external
        optionalProxy
    {

         
         
         
        uint proceeds;
        if (isLiquidating()) {
            proceeds = saleProceedsEtherAllowStale(n);
        } else {
            proceeds = saleProceedsEther(n);
        }

        require(address(this).balance >= proceeds);

        address sender = messageSender;
         
        state.setBalanceOf(sender, safeSub(state.balanceOf(sender), n));
        nominPool = safeAdd(nominPool, n);
        emit Sold(sender, sender, n, proceeds);
        emit Transfer(sender, 0, n);
        totalSupply = safeSub(totalSupply, n);
        sender.transfer(proceeds);
    }

     
    function forceLiquidation()
        external
        notLiquidating
        optionalProxy_onlyOwner
    {
        beginLiquidation();
    }

    function beginLiquidation()
        internal
    {
        liquidationTimestamp = now;
        emit LiquidationBegun(liquidationPeriod);
    }

     
    function extendLiquidationPeriod(uint extension)
        external
        optionalProxy_onlyOwner
    {
        require(isLiquidating());
        uint sum = safeAdd(liquidationPeriod, extension);
        require(sum <= MAX_LIQUIDATION_PERIOD);
        liquidationPeriod = sum;
        emit LiquidationExtended(extension);
    }

     
    function terminateLiquidation()
        external
        payable
        priceNotStale
        optionalProxy_onlyOwner
    {
        require(isLiquidating());
        require(_nominCap() == 0 || collateralisationRatio() >= AUTO_LIQUIDATION_RATIO);
        liquidationTimestamp = ~uint(0);
        liquidationPeriod = DEFAULT_LIQUIDATION_PERIOD;
        emit LiquidationTerminated();
    }

     
    function selfDestruct()
        external
        optionalProxy_onlyOwner
    {
        require(canSelfDestruct());
        emit SelfDestructed(beneficiary);
        selfdestruct(beneficiary);
    }

     
    function confiscateBalance(address target)
        external
    {
         
        require(Court(msg.sender) == court);
        
         
        uint motionID = court.targetMotionID(target);
        require(motionID != 0);

         
         
         
        require(court.motionConfirming(motionID));
        require(court.motionPasses(motionID));
        require(!frozen[target]);

         
        uint balance = state.balanceOf(target);
        state.setBalanceOf(address(this), safeAdd(state.balanceOf(address(this)), balance));
        state.setBalanceOf(target, 0);
        frozen[target] = true;
        emit AccountFrozen(target, target, balance);
        emit Transfer(target, address(this), balance);
    }

     
    function unfreezeAccount(address target)
        external
        optionalProxy_onlyOwner
    {
        if (frozen[target] && EtherNomin(target) != this) {
            frozen[target] = false;
            emit AccountUnfrozen(target, target);
        }
    }

     
    function() public payable {}


     

    modifier notLiquidating
    {
        require(!isLiquidating());
        _;
    }

    modifier priceNotStale
    {
        require(!priceIsStale());
        _;
    }

     
    modifier postCheckAutoLiquidate
    {
        _;
        if (!isLiquidating() && _nominCap() != 0 && collateralisationRatio() < AUTO_LIQUIDATION_RATIO) {
            beginLiquidation();
        }
    }


     

    event PoolReplenished(uint nominsCreated, uint collateralDeposited);

    event PoolDiminished(uint nominsDestroyed);

    event Purchased(address buyer, address indexed buyerIndex, uint nomins, uint eth);

    event Sold(address seller, address indexed sellerIndex, uint nomins, uint eth);

    event PriceUpdated(uint newPrice);

    event StalePeriodUpdated(uint newPeriod);

    event OracleUpdated(address newOracle);

    event CourtUpdated(address newCourt);

    event BeneficiaryUpdated(address newBeneficiary);

    event LiquidationBegun(uint duration);

    event LiquidationTerminated();

    event LiquidationExtended(uint extension);

    event PoolFeeRateUpdated(uint newFeeRate);

    event SelfDestructed(address beneficiary);

    event AccountFrozen(address target, address indexed targetIndex, uint balance);

    event AccountUnfrozen(address target, address indexed targetIndex);
}

 

contract ExternStateProxyToken is SafeDecimalMath, Proxyable {

     

     
    TokenState public state;

     
    string public name;
    string public symbol;
    uint public totalSupply;


     

    function ExternStateProxyToken(string _name, string _symbol,
                                   uint initialSupply, address initialBeneficiary,
                                   TokenState _state, address _owner)
        Proxyable(_owner)
        public
    {
        name = _name;
        symbol = _symbol;
        totalSupply = initialSupply;

         
        if (_state == TokenState(0)) {
            state = new TokenState(_owner, address(this));
            state.setBalanceOf(initialBeneficiary, totalSupply);
            emit Transfer(address(0), initialBeneficiary, initialSupply);
        } else {
            state = _state;
        }
   }

     

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint)
    {
        return state.allowance(tokenOwner, spender);
    }

    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return state.balanceOf(account);
    }

     

    function setState(TokenState _state)
        external
        optionalProxy_onlyOwner
    {
        state = _state;
        emit StateUpdated(_state);
    } 

     
    function _transfer_byProxy(address sender, address to, uint value)
        internal
        returns (bool)
    {
        require(to != address(0));

         
        state.setBalanceOf(sender, safeSub(state.balanceOf(sender), value));
        state.setBalanceOf(to, safeAdd(state.balanceOf(to), value));

        emit Transfer(sender, to, value);

        return true;
    }

     
    function _transferFrom_byProxy(address sender, address from, address to, uint value)
        internal
        returns (bool)
    {
        require(from != address(0) && to != address(0));

         
        state.setBalanceOf(from, safeSub(state.balanceOf(from), value));
        state.setAllowance(from, sender, safeSub(state.allowance(from, sender), value));
        state.setBalanceOf(to, safeAdd(state.balanceOf(to), value));

        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint value)
        external
        optionalProxy
        returns (bool)
    {
        address sender = messageSender;
        state.setAllowance(sender, spender, value);
        emit Approval(sender, spender, value);
        return true;
    }

     

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);

    event StateUpdated(address newState);
}

 

contract HavvenEscrow is Owned, LimitedSetup(8 weeks), SafeDecimalMath {    
     
    Havven public havven;

     
     
    mapping(address => uint[2][]) public vestingSchedules;

     
    mapping(address => uint) public totalVestedAccountBalance;

     
    uint public totalVestedBalance;


     

    function HavvenEscrow(address _owner, Havven _havven)
        Owned(_owner)
        public
    {
        havven = _havven;
    }


     

    function setHavven(Havven _havven)
        external
        onlyOwner
    {
        havven = _havven;
        emit HavvenUpdated(_havven);
    }


     

     
    function balanceOf(address account)
        public
        view
        returns (uint)
    {
        return totalVestedAccountBalance[account];
    }

     
    function numVestingEntries(address account)
        public
        view
        returns (uint)
    {
        return vestingSchedules[account].length;
    }

     
    function getVestingScheduleEntry(address account, uint index)
        public
        view
        returns (uint[2])
    {
        return vestingSchedules[account][index];
    }

     
    function getVestingTime(address account, uint index)
        public
        view
        returns (uint)
    {
        return vestingSchedules[account][index][0];
    }

     
    function getVestingQuantity(address account, uint index)
        public
        view
        returns (uint)
    {
        return vestingSchedules[account][index][1];
    }

     
    function getNextVestingIndex(address account)
        public
        view
        returns (uint)
    {
        uint len = numVestingEntries(account);
        for (uint i = 0; i < len; i++) {
            if (getVestingTime(account, i) != 0) {
                return i;
            }
        }
        return len;
    }

     
    function getNextVestingEntry(address account)
        external
        view
        returns (uint[2])
    {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
            return [uint(0), 0];
        }
        return getVestingScheduleEntry(account, index);
    }

     
    function getNextVestingTime(address account)
        external
        view
        returns (uint)
    {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
            return 0;
        }
        return getVestingTime(account, index);
    }

     
    function getNextVestingQuantity(address account)
        external
        view
        returns (uint)
    {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
            return 0;
        }
        return getVestingQuantity(account, index);
    }


     

     
    function withdrawHavvens(uint quantity)
        external
        onlyOwner
        setupFunction
    {
        havven.transfer(havven, quantity);
    }

     
    function purgeAccount(address account)
        external
        onlyOwner
        setupFunction
    {
        delete vestingSchedules[account];
        totalVestedBalance = safeSub(totalVestedBalance, totalVestedAccountBalance[account]);
        delete totalVestedAccountBalance[account];
    }

     
    function appendVestingEntry(address account, uint time, uint quantity)
        public
        onlyOwner
        setupFunction
    {
         
        require(now < time);
        require(quantity != 0);
        totalVestedBalance = safeAdd(totalVestedBalance, quantity);
        require(totalVestedBalance <= havven.balanceOf(this));

        if (vestingSchedules[account].length == 0) {
            totalVestedAccountBalance[account] = quantity;
        } else {
             
             
            require(getVestingTime(account, numVestingEntries(account) - 1) < time);
            totalVestedAccountBalance[account] = safeAdd(totalVestedAccountBalance[account], quantity);
        }

        vestingSchedules[account].push([time, quantity]);
    }

     
    function addVestingSchedule(address account, uint[] times, uint[] quantities)
        external
        onlyOwner
        setupFunction
    {
        for (uint i = 0; i < times.length; i++) {
            appendVestingEntry(account, times[i], quantities[i]);
        }

    }

     
    function vest() 
        external
    {
        uint total;
        for (uint i = 0; i < numVestingEntries(msg.sender); i++) {
            uint time = getVestingTime(msg.sender, i);
             
            if (time > now) {
                break;
            }
            uint qty = getVestingQuantity(msg.sender, i);
            if (qty == 0) {
                continue;
            }

            vestingSchedules[msg.sender][i] = [0, 0];
            total = safeAdd(total, qty);
            totalVestedAccountBalance[msg.sender] = safeSub(totalVestedAccountBalance[msg.sender], qty);
        }

        if (total != 0) {
            totalVestedBalance = safeSub(totalVestedBalance, total);
            havven.transfer(msg.sender, total);
            emit Vested(msg.sender, msg.sender,
                   now, total);
        }
    }


     

    event HavvenUpdated(address newHavven);

    event Vested(address beneficiary, address indexed beneficiaryIndex, uint time, uint value);
}

 

contract SelfDestructible is Owned {
	
	uint public initiationTime = ~uint(0);
	uint constant SD_DURATION = 3 days;
	address public beneficiary;

	function SelfDestructible(address _owner, address _beneficiary)
		public
		Owned(_owner)
	{
		beneficiary = _beneficiary;
	}

	function setBeneficiary(address _beneficiary)
		external
		onlyOwner
	{
		beneficiary = _beneficiary;
		emit SelfDestructBeneficiaryUpdated(_beneficiary);
	}

	function initiateSelfDestruct()
		external
		onlyOwner
	{
		initiationTime = now;
		emit SelfDestructInitiated(SD_DURATION);
	}

	function terminateSelfDestruct()
		external
		onlyOwner
	{
		initiationTime = ~uint(0);
		emit SelfDestructTerminated();
	}

	function selfDestruct()
		external
		onlyOwner
	{
		require(initiationTime + SD_DURATION < now);
		emit SelfDestructed(beneficiary);
		selfdestruct(beneficiary);
	}

	event SelfDestructBeneficiaryUpdated(address newBeneficiary);

	event SelfDestructInitiated(uint duration);

	event SelfDestructTerminated();

	event SelfDestructed(address beneficiary);
}

 

contract Havven is ExternStateProxyToken, SelfDestructible {

     

     
     
    mapping(address => uint) public currentBalanceSum;

     
     
     
     
     
     
    mapping(address => uint) public lastAverageBalance;

     
     
     
     
     
     
     
    mapping(address => uint) public penultimateAverageBalance;

     
     
    mapping(address => uint) public lastTransferTimestamp;

     
    uint public feePeriodStartTime = 3;
     
     
     
     
     
    uint public lastFeePeriodStartTime = 2;
     
    uint public penultimateFeePeriodStartTime = 1;

     
    uint public targetFeePeriodDurationSeconds = 4 weeks;
     
    uint constant MIN_FEE_PERIOD_DURATION_SECONDS = 1 days;
     
    uint constant MAX_FEE_PERIOD_DURATION_SECONDS = 26 weeks;

     
     
    uint public lastFeesCollected;

    mapping(address => bool) public hasWithdrawnLastPeriodFees;

    EtherNomin public nomin;
    HavvenEscrow public escrow;


     

    function Havven(TokenState initialState, address _owner)
        ExternStateProxyToken("Havven", "HAV", 1e8 * UNIT, address(this), initialState, _owner)
        SelfDestructible(_owner, _owner)
         
        public
    {
        lastTransferTimestamp[this] = now;
        feePeriodStartTime = now;
        lastFeePeriodStartTime = now - targetFeePeriodDurationSeconds;
        penultimateFeePeriodStartTime = now - 2*targetFeePeriodDurationSeconds;
    }


     

    function setNomin(EtherNomin _nomin) 
        external
        optionalProxy_onlyOwner
    {
        nomin = _nomin;
    }

    function setEscrow(HavvenEscrow _escrow)
        external
        optionalProxy_onlyOwner
    {
        escrow = _escrow;
    }

    function setTargetFeePeriodDuration(uint duration)
        external
        postCheckFeePeriodRollover
        optionalProxy_onlyOwner
    {
        require(MIN_FEE_PERIOD_DURATION_SECONDS <= duration &&
                duration <= MAX_FEE_PERIOD_DURATION_SECONDS);
        targetFeePeriodDurationSeconds = duration;
        emit FeePeriodDurationUpdated(duration);
    }


     

     
    function endow(address account, uint value)
        external
        optionalProxy_onlyOwner
        returns (bool)
    {

         
         
        return _transfer(this, account, value);
    }

     
    function emitTransferEvents(address sender, address[] recipients, uint[] values)
        external
        onlyOwner
    {
        for (uint i = 0; i < recipients.length; ++i) {
            emit Transfer(sender, recipients[i], values[i]);
        }
    }

     
    function transfer(address to, uint value)
        external
        optionalProxy
        returns (bool)
    {
        return _transfer(messageSender, to, value);
    }

     
    function _transfer(address sender, address to, uint value)
        internal
        preCheckFeePeriodRollover
        returns (bool)
    {

        uint senderPreBalance = state.balanceOf(sender);
        uint recipientPreBalance = state.balanceOf(to);

         
         
        _transfer_byProxy(sender, to, value);

         
         
        adjustFeeEntitlement(sender, senderPreBalance);
        adjustFeeEntitlement(to, recipientPreBalance);

        return true;
    }

     
    function transferFrom(address from, address to, uint value)
        external
        preCheckFeePeriodRollover
        optionalProxy
        returns (bool)
    {
        uint senderPreBalance = state.balanceOf(from);
        uint recipientPreBalance = state.balanceOf(to);

         
         
        _transferFrom_byProxy(messageSender, from, to, value);

         
         
        adjustFeeEntitlement(from, senderPreBalance);
        adjustFeeEntitlement(to, recipientPreBalance);

        return true;
    }

     
    function withdrawFeeEntitlement()
        public
        preCheckFeePeriodRollover
        optionalProxy
    {
        address sender = messageSender;

         
        require(!nomin.frozen(sender));

         
        rolloverFee(sender, lastTransferTimestamp[sender], state.balanceOf(sender));

         
        require(!hasWithdrawnLastPeriodFees[sender]);

        uint feesOwed;

        if (escrow != HavvenEscrow(0)) {
            feesOwed = escrow.totalVestedAccountBalance(sender);
        }

        feesOwed = safeDiv_dec(safeMul_dec(safeAdd(feesOwed, lastAverageBalance[sender]),
                                           lastFeesCollected),
                               totalSupply);

        hasWithdrawnLastPeriodFees[sender] = true;
        if (feesOwed != 0) {
            nomin.withdrawFee(sender, feesOwed);
            emit FeesWithdrawn(sender, sender, feesOwed);
        }
    }

     
    function adjustFeeEntitlement(address account, uint preBalance)
        internal
    {
         
         
        rolloverFee(account, lastTransferTimestamp[account], preBalance);

        currentBalanceSum[account] = safeAdd(
            currentBalanceSum[account],
            safeMul(preBalance, now - lastTransferTimestamp[account])
        );

         
        lastTransferTimestamp[account] = now;
    }

     
    function rolloverFee(address account, uint lastTransferTime, uint preBalance)
        internal
    {
        if (lastTransferTime < feePeriodStartTime) {
            if (lastTransferTime < lastFeePeriodStartTime) {
                 
                if (lastTransferTime < penultimateFeePeriodStartTime) {
                     
                     
                    penultimateAverageBalance[account] = preBalance;
                 
                } else {
                     
                    penultimateAverageBalance[account] = safeDiv(
                        safeAdd(currentBalanceSum[account], safeMul(preBalance, (lastFeePeriodStartTime - lastTransferTime))),
                        (lastFeePeriodStartTime - penultimateFeePeriodStartTime)
                    );
                }

                 
                 
                lastAverageBalance[account] = preBalance;

             
            } else {
                 
                penultimateAverageBalance[account] = lastAverageBalance[account];

                 
                lastAverageBalance[account] = safeDiv(
                    safeAdd(currentBalanceSum[account], safeMul(preBalance, (feePeriodStartTime - lastTransferTime))),
                    (feePeriodStartTime - lastFeePeriodStartTime)
                );
            }

             
            currentBalanceSum[account] = 0;
            hasWithdrawnLastPeriodFees[account] = false;
            lastTransferTimestamp[account] = feePeriodStartTime;
        }
    }

     
    function _recomputeAccountLastAverageBalance(address account)
        internal
        preCheckFeePeriodRollover
        returns (uint)
    {
        adjustFeeEntitlement(account, state.balanceOf(account));
        return lastAverageBalance[account];
    }

     
    function recomputeLastAverageBalance()
        external
        optionalProxy
        returns (uint)
    {
        return _recomputeAccountLastAverageBalance(messageSender);
    }

     
    function recomputeAccountLastAverageBalance(address account)
        external
        returns (uint)
    {
        return _recomputeAccountLastAverageBalance(account);
    }

    function rolloverFeePeriod()
        public
    {
        checkFeePeriodRollover();
    }


     

     
    function checkFeePeriodRollover()
        internal
    {
         
        if (feePeriodStartTime + targetFeePeriodDurationSeconds <= now) {
            lastFeesCollected = nomin.feePool();

             
            penultimateFeePeriodStartTime = lastFeePeriodStartTime;
            lastFeePeriodStartTime = feePeriodStartTime;
            feePeriodStartTime = now;
            
            emit FeePeriodRollover(now);
        }
    }

    modifier postCheckFeePeriodRollover
    {
        _;
        checkFeePeriodRollover();
    }

    modifier preCheckFeePeriodRollover
    {
        checkFeePeriodRollover();
        _;
    }


     

    event FeePeriodRollover(uint timestamp);

    event FeePeriodDurationUpdated(uint duration);

    event FeesWithdrawn(address account, address indexed accountIndex, uint value);
}

 

contract TokenState is Owned {

     
     
    address public associatedContract;

     
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function TokenState(address _owner, address _associatedContract)
        Owned(_owner)
        public
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

     

     
    function setAssociatedContract(address _associatedContract)
        external
        onlyOwner
    {
        associatedContract = _associatedContract;
        emit AssociatedContractUpdated(_associatedContract);
    }

    function setAllowance(address tokenOwner, address spender, uint value)
        external
        onlyAssociatedContract
    {
        allowance[tokenOwner][spender] = value;
    }

    function setBalanceOf(address account, uint value)
        external
        onlyAssociatedContract
    {
        balanceOf[account] = value;
    }


     

    modifier onlyAssociatedContract
    {
        require(msg.sender == associatedContract);
        _;
    }

     

    event AssociatedContractUpdated(address _associatedContract);
}

 