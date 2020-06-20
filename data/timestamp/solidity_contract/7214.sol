pragma solidity ^0.4.13;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

contract DSExec {
    function tryExec( address target, bytes calldata, uint value)
             internal
             returns (bool call_ret)
    {
        return target.call.value(value)(calldata);
    }
    function exec( address target, bytes calldata, uint value)
             internal
    {
        if(!tryExec(target, calldata, value)) {
            revert();
        }
    }

     
    function exec( address t, bytes c )
        internal
    {
        exec(t, c, 0);
    }
    function exec( address t, uint256 v )
        internal
    {
        bytes memory c; exec(t, c, v);
    }
    function tryExec( address t, bytes c )
        internal
        returns (bool)
    {
        return tryExec(t, c, 0);
    }
    function tryExec( address t, uint256 v )
        internal
        returns (bool)
    {
        bytes memory c; return tryExec(t, c, v);
    }
}

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

contract DSGroup is DSExec, DSNote {
    address[]  public  members;
    uint       public  quorum;
    uint       public  window;
    uint       public  actionCount;

    mapping (uint => Action)                     public  actions;
    mapping (uint => mapping (address => bool))  public  confirmedBy;
    mapping (address => bool)                    public  isMember;

     
    event Proposed   (uint id, bytes calldata);
    event Confirmed  (uint id, address member);
    event Triggered  (uint id);

    struct Action {
        address  target;
        bytes    calldata;
        uint     value;

        uint     confirmations;
        uint     deadline;
        bool     triggered;
    }

    function DSGroup(
        address[]  members_,
        uint       quorum_,
        uint       window_
    ) {
        members  = members_;
        quorum   = quorum_;
        window   = window_;

        for (uint i = 0; i < members.length; i++) {
            isMember[members[i]] = true;
        }
    }

    function memberCount() constant returns (uint) {
        return members.length;
    }

    function target(uint id) constant returns (address) {
        return actions[id].target;
    }
    function calldata(uint id) constant returns (bytes) {
        return actions[id].calldata;
    }
    function value(uint id) constant returns (uint) {
        return actions[id].value;
    }

    function confirmations(uint id) constant returns (uint) {
        return actions[id].confirmations;
    }
    function deadline(uint id) constant returns (uint) {
        return actions[id].deadline;
    }
    function triggered(uint id) constant returns (bool) {
        return actions[id].triggered;
    }

    function confirmed(uint id) constant returns (bool) {
        return confirmations(id) >= quorum;
    }
    function expired(uint id) constant returns (bool) {
        return now > deadline(id);
    }

    function deposit() note payable {
    }

    function propose(
        address  target,
        bytes    calldata,
        uint     value
    ) onlyMembers note returns (uint id) {
        id = ++actionCount;

        actions[id].target    = target;
        actions[id].calldata  = calldata;
        actions[id].value     = value;
        actions[id].deadline  = now + window;

        Proposed(id, calldata);
    }

    function confirm(uint id) onlyMembers onlyActive(id) note {
        assert(!confirmedBy[id][msg.sender]);

        confirmedBy[id][msg.sender] = true;
        actions[id].confirmations++;

        Confirmed(id, msg.sender);
    }

    function trigger(uint id) onlyMembers onlyActive(id) note {
        assert(confirmed(id));

        actions[id].triggered = true;
        exec(actions[id].target, actions[id].calldata, actions[id].value);

        Triggered(id);
    }

    modifier onlyMembers {
        assert(isMember[msg.sender]);
        _;
    }

    modifier onlyActive(uint id) {
        assert(!expired(id));
        assert(!triggered(id));
        _;
    }

     
     
     

    function getInfo() constant returns (
        uint  quorum_,
        uint  memberCount,
        uint  window_,
        uint  actionCount_
    ) {
        return (quorum, members.length, window, actionCount);
    }

    function getActionStatus(uint id) constant returns (
        uint     confirmations,
        uint     deadline,
        bool     triggered,
        address  target,
        uint     value
    ) {
        return (
            actions[id].confirmations,
            actions[id].deadline,
            actions[id].triggered,
            actions[id].target,
            actions[id].value
        );
    }
}

contract DSGroupFactory is DSNote {
    mapping (address => bool)  public  isGroup;

    function newGroup(
        address[]  members,
        uint       quorum,
        uint       window
    ) note returns (DSGroup group) {
        group = new DSGroup(members, quorum, window);
        isGroup[group] = true;
    }
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract DSThing is DSAuth, DSNote, DSMath {

    function S(string s) internal pure returns (bytes4) {
        return bytes4(keccak256(s));
    }

}

contract WETH9_ {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function() public payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        msg.sender.transfer(wad);
        Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return this.balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }
}

interface FundInterface {

     

    event PortfolioContent(address[] assets, uint[] holdings, uint[] prices);
    event RequestUpdated(uint id);
    event Redeemed(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);
    event FeesConverted(uint atTimestamp, uint shareQuantityConverted, uint unclaimed);
    event CalculationUpdate(uint atTimestamp, uint managementFee, uint performanceFee, uint nav, uint sharePrice, uint totalSupply);
    event ErrorMessage(string errorMessage);

     
     
    function requestInvestment(uint giveQuantity, uint shareQuantity, address investmentAsset) external;
    function executeRequest(uint requestId) external;
    function cancelRequest(uint requestId) external;
    function redeemAllOwnedAssets(uint shareQuantity) external returns (bool);
     
    function enableInvestment(address[] ofAssets) external;
    function disableInvestment(address[] ofAssets) external;
    function shutDown() external;

     
    function emergencyRedeem(uint shareQuantity, address[] requestedAssets) public returns (bool success);
    function calcSharePriceAndAllocateFees() public returns (uint);


     
     
    function getModules() view returns (address, address, address);
    function getLastRequestId() view returns (uint);
    function getManager() view returns (address);

     
    function performCalculations() view returns (uint, uint, uint, uint, uint, uint, uint);
    function calcSharePrice() view returns (uint);
}

interface AssetInterface {
     

     
    event Approval(address indexed _owner, address indexed _spender, uint _value);

     

     
     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success);

     
     
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
     
    function balanceOf(address _owner) view public returns (uint balance);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Asset is DSMath, ERC20Interface {

     

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint public _totalSupply;

     

     
    function transfer(address _to, uint _value)
        public
        returns (bool success)
    {
        require(balances[msg.sender] >= _value);  
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value)
        public
        returns (bool)
    {
        require(_from != address(0));
        require(_to != address(0));
        require(_to != address(this));
        require(balances[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
         

        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
     
    function approve(address _spender, uint _value) public returns (bool) {
        require(_spender != address(0));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     

     
     
     
     
     
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

     
     
     
    function balanceOf(address _owner) constant public returns (uint) {
        return balances[_owner];
    }

    function totalSupply() view public returns (uint) {
        return _totalSupply;
    }
}

interface SharesInterface {

    event Created(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);
    event Annihilated(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);

     

    function getName() view returns (bytes32);
    function getSymbol() view returns (bytes8);
    function getDecimals() view returns (uint);
    function getCreationTime() view returns (uint);
    function toSmallestShareUnit(uint quantity) view returns (uint);
    function toWholeShareUnit(uint quantity) view returns (uint);

}

contract Shares is SharesInterface, Asset {

     

     
    bytes32 public name;
    bytes8 public symbol;
    uint public decimal;
    uint public creationTime;

     

     

     
     
     
     
    function Shares(bytes32 _name, bytes8 _symbol, uint _decimal, uint _creationTime) {
        name = _name;
        symbol = _symbol;
        decimal = _decimal;
        creationTime = _creationTime;
    }

     

     
    function transfer(address _to, uint _value)
        public
        returns (bool success)
    {
        require(balances[msg.sender] >= _value);  
        require(balances[_to] + _value >= balances[_to]);

        balances[msg.sender] = sub(balances[msg.sender], _value);
        balances[_to] = add(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     

    function getName() view returns (bytes32) { return name; }
    function getSymbol() view returns (bytes8) { return symbol; }
    function getDecimals() view returns (uint) { return decimal; }
    function getCreationTime() view returns (uint) { return creationTime; }
    function toSmallestShareUnit(uint quantity) view returns (uint) { return mul(quantity, 10 ** getDecimals()); }
    function toWholeShareUnit(uint quantity) view returns (uint) { return quantity / (10 ** getDecimals()); }

     

     
     
    function createShares(address recipient, uint shareQuantity) internal {
        _totalSupply = add(_totalSupply, shareQuantity);
        balances[recipient] = add(balances[recipient], shareQuantity);
        emit Created(msg.sender, now, shareQuantity);
        emit Transfer(address(0), recipient, shareQuantity);
    }

     
     
    function annihilateShares(address recipient, uint shareQuantity) internal {
        _totalSupply = sub(_totalSupply, shareQuantity);
        balances[recipient] = sub(balances[recipient], shareQuantity);
        emit Annihilated(msg.sender, now, shareQuantity);
        emit Transfer(recipient, address(0), shareQuantity);
    }
}

interface CompetitionInterface {

     

    event Register(uint withId, address fund, address manager);
    event ClaimReward(address registrant, address fund, uint shares);

     

    function termsAndConditionsAreSigned(address byManager, uint8 v, bytes32 r, bytes32 s) view returns (bool);
    function isWhitelisted(address x) view returns (bool);
    function isCompetitionActive() view returns (bool);

     

    function getMelonAsset() view returns (address);
    function getRegistrantId(address x) view returns (uint);
    function getRegistrantFund(address x) view returns (address);
    function getCompetitionStatusOfRegistrants() view returns (address[], address[], bool[]);
    function getTimeTillEnd() view returns (uint);
    function getEtherValue(uint amount) view returns (uint);
    function calculatePayout(uint payin) view returns (uint);

     

    function registerForCompetition(address fund, uint8 v, bytes32 r, bytes32 s) payable;
    function batchAddToWhitelist(uint maxBuyinQuantity, address[] whitelistants);
    function withdrawMln(address to, uint amount);
    function claimReward();

}

interface ComplianceInterface {

     

     
     
     
     
     
    function isInvestmentPermitted(
        address ofParticipant,
        uint256 giveQuantity,
        uint256 shareQuantity
    ) view returns (bool);

     
     
     
     
     
    function isRedemptionPermitted(
        address ofParticipant,
        uint256 shareQuantity,
        uint256 receiveQuantity
    ) view returns (bool);
}

contract DBC {

     

    modifier pre_cond(bool condition) {
        require(condition);
        _;
    }

    modifier post_cond(bool condition) {
        _;
        assert(condition);
    }

    modifier invariant(bool condition) {
        require(condition);
        _;
        assert(condition);
    }
}

contract Owned is DBC {

     

    address public owner;

     

    function Owned() { owner = msg.sender; }

    function changeOwner(address ofNewOwner) pre_cond(isOwner()) { owner = ofNewOwner; }

     

    function isOwner() internal returns (bool) { return msg.sender == owner; }

}

contract Fund is DSMath, DBC, Owned, Shares, FundInterface {

    event OrderUpdated(address exchange, bytes32 orderId, UpdateType updateType);

     

    struct Modules {  
        CanonicalPriceFeed pricefeed;  
        ComplianceInterface compliance;  
        RiskMgmtInterface riskmgmt;  
    }

    struct Calculations {  
        uint gav;  
        uint managementFee;  
        uint performanceFee;  
        uint unclaimedFees;  
        uint nav;  
        uint highWaterMark;  
        uint totalSupply;  
        uint timestamp;  
    }

    enum UpdateType { make, take, cancel }
    enum RequestStatus { active, cancelled, executed }
    struct Request {  
        address participant;  
        RequestStatus status;  
        address requestAsset;  
        uint shareQuantity;  
        uint giveQuantity;  
        uint receiveQuantity;  
        uint timestamp;      
        uint atUpdateId;     
    }

    struct Exchange {
        address exchange;
        address exchangeAdapter;
        bool takesCustody;   
    }

    struct OpenMakeOrder {
        uint id;  
        uint expiresAt;  
    }

    struct Order {  
        address exchangeAddress;  
        bytes32 orderId;  
        UpdateType updateType;  
        address makerAsset;  
        address takerAsset;  
        uint makerQuantity;  
        uint takerQuantity;  
        uint timestamp;  
        uint fillTakerQuantity;  
    }

     

     
    uint public constant MAX_FUND_ASSETS = 20;  
    uint public constant ORDER_EXPIRATION_TIME = 86400;  
     
    uint public MANAGEMENT_FEE_RATE;  
    uint public PERFORMANCE_FEE_RATE;  
    address public VERSION;  
    Asset public QUOTE_ASSET;  
     
    Modules public modules;  
    Exchange[] public exchanges;  
    Calculations public atLastUnclaimedFeeAllocation;  
    Order[] public orders;   
    mapping (address => mapping(address => OpenMakeOrder)) public exchangesToOpenMakeOrders;  
    bool public isShutDown;  
    Request[] public requests;  
    mapping (address => bool) public isInvestAllowed;  
    address[] public ownedAssets;  
    mapping (address => bool) public isInAssetList;  
    mapping (address => bool) public isInOpenMakeOrder;  

     

     

     
     
     
     
     
     
     
     
     
     
     
    function Fund(
        address ofManager,
        bytes32 withName,
        address ofQuoteAsset,
        uint ofManagementFee,
        uint ofPerformanceFee,
        address ofCompliance,
        address ofRiskMgmt,
        address ofPriceFeed,
        address[] ofExchanges,
        address[] ofDefaultAssets
    )
        Shares(withName, "MLNF", 18, now)
    {
        require(ofManagementFee < 10 ** 18);  
        require(ofPerformanceFee < 10 ** 18);  
        isInvestAllowed[ofQuoteAsset] = true;
        owner = ofManager;
        MANAGEMENT_FEE_RATE = ofManagementFee;  
        PERFORMANCE_FEE_RATE = ofPerformanceFee;  
        VERSION = msg.sender;
        modules.compliance = ComplianceInterface(ofCompliance);
        modules.riskmgmt = RiskMgmtInterface(ofRiskMgmt);
        modules.pricefeed = CanonicalPriceFeed(ofPriceFeed);
         
        for (uint i = 0; i < ofExchanges.length; ++i) {
            require(modules.pricefeed.exchangeIsRegistered(ofExchanges[i]));
            var (ofExchangeAdapter, takesCustody, ) = modules.pricefeed.getExchangeInformation(ofExchanges[i]);
            exchanges.push(Exchange({
                exchange: ofExchanges[i],
                exchangeAdapter: ofExchangeAdapter,
                takesCustody: takesCustody
            }));
        }
        QUOTE_ASSET = Asset(ofQuoteAsset);
         
        ownedAssets.push(ofQuoteAsset);
        isInAssetList[ofQuoteAsset] = true;
        require(address(QUOTE_ASSET) == modules.pricefeed.getQuoteAsset());  
        for (uint j = 0; j < ofDefaultAssets.length; j++) {
            require(modules.pricefeed.assetIsRegistered(ofDefaultAssets[j]));
            isInvestAllowed[ofDefaultAssets[j]] = true;
        }
        atLastUnclaimedFeeAllocation = Calculations({
            gav: 0,
            managementFee: 0,
            performanceFee: 0,
            unclaimedFees: 0,
            nav: 0,
            highWaterMark: 10 ** getDecimals(),
            totalSupply: _totalSupply,
            timestamp: now
        });
    }

     

     

     
     
    function enableInvestment(address[] ofAssets)
        external
        pre_cond(isOwner())
    {
        for (uint i = 0; i < ofAssets.length; ++i) {
            require(modules.pricefeed.assetIsRegistered(ofAssets[i]));
            isInvestAllowed[ofAssets[i]] = true;
        }
    }

     
     
    function disableInvestment(address[] ofAssets)
        external
        pre_cond(isOwner())
    {
        for (uint i = 0; i < ofAssets.length; ++i) {
            isInvestAllowed[ofAssets[i]] = false;
        }
    }

    function shutDown() external pre_cond(msg.sender == VERSION) { isShutDown = true; }

     

     
     
     
     
     
    function requestInvestment(
        uint giveQuantity,
        uint shareQuantity,
        address investmentAsset
    )
        external
        pre_cond(!isShutDown)
        pre_cond(isInvestAllowed[investmentAsset])  
        pre_cond(modules.compliance.isInvestmentPermitted(msg.sender, giveQuantity, shareQuantity))     
    {
        requests.push(Request({
            participant: msg.sender,
            status: RequestStatus.active,
            requestAsset: investmentAsset,
            shareQuantity: shareQuantity,
            giveQuantity: giveQuantity,
            receiveQuantity: shareQuantity,
            timestamp: now,
            atUpdateId: modules.pricefeed.getLastUpdateId()
        }));

        emit RequestUpdated(getLastRequestId());
    }

     
     
     
     
    function executeRequest(uint id)
        external
        pre_cond(!isShutDown)
        pre_cond(requests[id].status == RequestStatus.active)
        pre_cond(
            _totalSupply == 0 ||
            (
                now >= add(requests[id].timestamp, modules.pricefeed.getInterval()) &&
                modules.pricefeed.getLastUpdateId() >= add(requests[id].atUpdateId, 2)
            )
        )    

    {
        Request request = requests[id];
        var (isRecent, , ) =
            modules.pricefeed.getPriceInfo(address(request.requestAsset));
        require(isRecent);

         
        uint costQuantity = toWholeShareUnit(mul(request.shareQuantity, calcSharePriceAndAllocateFees()));  
        if (request.requestAsset != address(QUOTE_ASSET)) {
            var (isPriceRecent, invertedRequestAssetPrice, requestAssetDecimal) = modules.pricefeed.getInvertedPriceInfo(request.requestAsset);
            if (!isPriceRecent) {
                revert();
            }
            costQuantity = mul(costQuantity, invertedRequestAssetPrice) / 10 ** requestAssetDecimal;
        }

        if (
            isInvestAllowed[request.requestAsset] &&
            costQuantity <= request.giveQuantity
        ) {
            request.status = RequestStatus.executed;
            require(AssetInterface(request.requestAsset).transferFrom(request.participant, address(this), costQuantity));  
            createShares(request.participant, request.shareQuantity);  
            if (!isInAssetList[request.requestAsset]) {
                ownedAssets.push(request.requestAsset);
                isInAssetList[request.requestAsset] = true;
            }
        } else {
            revert();  
        }
    }

     
     
    function cancelRequest(uint id)
        external
        pre_cond(requests[id].status == RequestStatus.active)  
        pre_cond(requests[id].participant == msg.sender || isShutDown)  
    {
        requests[id].status = RequestStatus.cancelled;
    }

     
     
     
     
    function redeemAllOwnedAssets(uint shareQuantity)
        external
        returns (bool success)
    {
        return emergencyRedeem(shareQuantity, ownedAssets);
    }

     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function callOnExchange(
        uint exchangeIndex,
        bytes4 method,
        address[5] orderAddresses,
        uint[8] orderValues,
        bytes32 identifier,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        require(modules.pricefeed.exchangeMethodIsAllowed(
            exchanges[exchangeIndex].exchange, method
        ));
        require((exchanges[exchangeIndex].exchangeAdapter).delegatecall(
            method, exchanges[exchangeIndex].exchange,
            orderAddresses, orderValues, identifier, v, r, s
        ));
    }

    function addOpenMakeOrder(
        address ofExchange,
        address ofSellAsset,
        uint orderId
    )
        pre_cond(msg.sender == address(this))
    {
        isInOpenMakeOrder[ofSellAsset] = true;
        exchangesToOpenMakeOrders[ofExchange][ofSellAsset].id = orderId;
        exchangesToOpenMakeOrders[ofExchange][ofSellAsset].expiresAt = add(now, ORDER_EXPIRATION_TIME);
    }

    function removeOpenMakeOrder(
        address ofExchange,
        address ofSellAsset
    )
        pre_cond(msg.sender == address(this))
    {
        delete exchangesToOpenMakeOrders[ofExchange][ofSellAsset];
    }

    function orderUpdateHook(
        address ofExchange,
        bytes32 orderId,
        UpdateType updateType,
        address[2] orderAddresses,  
        uint[3] orderValues         
    )
        pre_cond(msg.sender == address(this))
    {
         
        if (updateType == UpdateType.make || updateType == UpdateType.take) {
            orders.push(Order({
                exchangeAddress: ofExchange,
                orderId: orderId,
                updateType: updateType,
                makerAsset: orderAddresses[0],
                takerAsset: orderAddresses[1],
                makerQuantity: orderValues[0],
                takerQuantity: orderValues[1],
                timestamp: block.timestamp,
                fillTakerQuantity: orderValues[2]
            }));
        }
        emit OrderUpdated(ofExchange, orderId, updateType);
    }

     

     

     
     
     
     
    function calcGav() returns (uint gav) {
         
        uint[] memory allAssetHoldings = new uint[](ownedAssets.length);
        uint[] memory allAssetPrices = new uint[](ownedAssets.length);
        address[] memory tempOwnedAssets;
        tempOwnedAssets = ownedAssets;
        delete ownedAssets;
        for (uint i = 0; i < tempOwnedAssets.length; ++i) {
            address ofAsset = tempOwnedAssets[i];
             
            uint assetHoldings = add(
                uint(AssetInterface(ofAsset).balanceOf(address(this))),  
                quantityHeldInCustodyOfExchange(ofAsset)
            );
             
            var (isRecent, assetPrice, assetDecimals) = modules.pricefeed.getPriceInfo(ofAsset);
            if (!isRecent) {
                revert();
            }
            allAssetHoldings[i] = assetHoldings;
            allAssetPrices[i] = assetPrice;
             
            gav = add(gav, mul(assetHoldings, assetPrice) / (10 ** uint256(assetDecimals)));    
            if (assetHoldings != 0 || ofAsset == address(QUOTE_ASSET) || isInOpenMakeOrder[ofAsset]) {  
                ownedAssets.push(ofAsset);
            } else {
                isInAssetList[ofAsset] = false;  
            }
        }
        emit PortfolioContent(tempOwnedAssets, allAssetHoldings, allAssetPrices);
    }

     
    function addAssetToOwnedAssets (address ofAsset)
        public
        pre_cond(isOwner() || msg.sender == address(this))
    {
        isInOpenMakeOrder[ofAsset] = true;
        if (!isInAssetList[ofAsset]) {
            ownedAssets.push(ofAsset);
            isInAssetList[ofAsset] = true;
        }
    }

     
    function calcUnclaimedFees(uint gav)
        view
        returns (
            uint managementFee,
            uint performanceFee,
            uint unclaimedFees)
    {
         
        uint timePassed = sub(now, atLastUnclaimedFeeAllocation.timestamp);
        uint gavPercentage = mul(timePassed, gav) / (1 years);
        managementFee = wmul(gavPercentage, MANAGEMENT_FEE_RATE);

         
         
        uint valuePerShareExclMgmtFees = _totalSupply > 0 ? calcValuePerShare(sub(gav, managementFee), _totalSupply) : toSmallestShareUnit(1);
        if (valuePerShareExclMgmtFees > atLastUnclaimedFeeAllocation.highWaterMark) {
            uint gainInSharePrice = sub(valuePerShareExclMgmtFees, atLastUnclaimedFeeAllocation.highWaterMark);
            uint investmentProfits = wmul(gainInSharePrice, _totalSupply);
            performanceFee = wmul(investmentProfits, PERFORMANCE_FEE_RATE);
        }

         
        unclaimedFees = add(managementFee, performanceFee);
    }

     
     
     
     
    function calcNav(uint gav, uint unclaimedFees)
        view
        returns (uint nav)
    {
        nav = sub(gav, unclaimedFees);
    }

     
     
     
     
     
     
    function calcValuePerShare(uint totalValue, uint numShares)
        view
        pre_cond(numShares > 0)
        returns (uint valuePerShare)
    {
        valuePerShare = toSmallestShareUnit(totalValue) / numShares;
    }

     
    function performCalculations()
        view
        returns (
            uint gav,
            uint managementFee,
            uint performanceFee,
            uint unclaimedFees,
            uint feesShareQuantity,
            uint nav,
            uint sharePrice
        )
    {
        gav = calcGav();  
        (managementFee, performanceFee, unclaimedFees) = calcUnclaimedFees(gav);
        nav = calcNav(gav, unclaimedFees);

         
        feesShareQuantity = (gav == 0) ? 0 : mul(_totalSupply, unclaimedFees) / gav;
         
        uint totalSupplyAccountingForFees = add(_totalSupply, feesShareQuantity);
        sharePrice = _totalSupply > 0 ? calcValuePerShare(gav, totalSupplyAccountingForFees) : toSmallestShareUnit(1);  
    }

     
     
    function calcSharePriceAndAllocateFees() public returns (uint)
    {
        var (
            gav,
            managementFee,
            performanceFee,
            unclaimedFees,
            feesShareQuantity,
            nav,
            sharePrice
        ) = performCalculations();

        createShares(owner, feesShareQuantity);  

         
        uint highWaterMark = atLastUnclaimedFeeAllocation.highWaterMark >= sharePrice ? atLastUnclaimedFeeAllocation.highWaterMark : sharePrice;
        atLastUnclaimedFeeAllocation = Calculations({
            gav: gav,
            managementFee: managementFee,
            performanceFee: performanceFee,
            unclaimedFees: unclaimedFees,
            nav: nav,
            highWaterMark: highWaterMark,
            totalSupply: _totalSupply,
            timestamp: now
        });

        emit FeesConverted(now, feesShareQuantity, unclaimedFees);
        emit CalculationUpdate(now, managementFee, performanceFee, nav, sharePrice, _totalSupply);

        return sharePrice;
    }

     

     
     
     
     
     
     
    function emergencyRedeem(uint shareQuantity, address[] requestedAssets)
        public
        pre_cond(balances[msg.sender] >= shareQuantity)   
        returns (bool)
    {
        address ofAsset;
        uint[] memory ownershipQuantities = new uint[](requestedAssets.length);
        address[] memory redeemedAssets = new address[](requestedAssets.length);

         
        for (uint i = 0; i < requestedAssets.length; ++i) {
            ofAsset = requestedAssets[i];
            require(isInAssetList[ofAsset]);
            for (uint j = 0; j < redeemedAssets.length; j++) {
                if (ofAsset == redeemedAssets[j]) {
                    revert();
                }
            }
            redeemedAssets[i] = ofAsset;
            uint assetHoldings = add(
                uint(AssetInterface(ofAsset).balanceOf(address(this))),
                quantityHeldInCustodyOfExchange(ofAsset)
            );

            if (assetHoldings == 0) continue;

             
            ownershipQuantities[i] = mul(assetHoldings, shareQuantity) / _totalSupply;

             
            if (uint(AssetInterface(ofAsset).balanceOf(address(this))) < ownershipQuantities[i]) {
                isShutDown = true;
                emit ErrorMessage("CRITICAL ERR: Not enough assetHoldings for owed ownershipQuantitiy");
                return false;
            }
        }

         
        annihilateShares(msg.sender, shareQuantity);

         
        for (uint k = 0; k < requestedAssets.length; ++k) {
             
            ofAsset = requestedAssets[k];
            if (ownershipQuantities[k] == 0) {
                continue;
            } else if (!AssetInterface(ofAsset).transfer(msg.sender, ownershipQuantities[k])) {
                revert();
            }
        }
        emit Redeemed(msg.sender, now, shareQuantity);
        return true;
    }

     

     
     
     
    function quantityHeldInCustodyOfExchange(address ofAsset) returns (uint) {
        uint totalSellQuantity;      
        uint totalSellQuantityInApprove;  
        for (uint i; i < exchanges.length; i++) {
            if (exchangesToOpenMakeOrders[exchanges[i].exchange][ofAsset].id == 0) {
                continue;
            }
            var (sellAsset, , sellQuantity, ) = GenericExchangeInterface(exchanges[i].exchangeAdapter).getOrder(exchanges[i].exchange, exchangesToOpenMakeOrders[exchanges[i].exchange][ofAsset].id);
            if (sellQuantity == 0) {     
                delete exchangesToOpenMakeOrders[exchanges[i].exchange][ofAsset];
            }
            totalSellQuantity = add(totalSellQuantity, sellQuantity);
            if (!exchanges[i].takesCustody) {
                totalSellQuantityInApprove += sellQuantity;
            }
        }
        if (totalSellQuantity == 0) {
            isInOpenMakeOrder[sellAsset] = false;
        }
        return sub(totalSellQuantity, totalSellQuantityInApprove);  
    }

     

     
     
    function calcSharePrice() view returns (uint sharePrice) {
        (, , , , , sharePrice) = performCalculations();
        return sharePrice;
    }

    function getModules() view returns (address, address, address) {
        return (
            address(modules.pricefeed),
            address(modules.compliance),
            address(modules.riskmgmt)
        );
    }

    function getLastRequestId() view returns (uint) { return requests.length - 1; }
    function getLastOrderIndex() view returns (uint) { return orders.length - 1; }
    function getManager() view returns (address) { return owner; }
    function getOwnedAssetsLength() view returns (uint) { return ownedAssets.length; }
    function getExchangeInfo() view returns (address[], address[], bool[]) {
        address[] memory ofExchanges = new address[](exchanges.length);
        address[] memory ofAdapters = new address[](exchanges.length);
        bool[] memory takesCustody = new bool[](exchanges.length);
        for (uint i = 0; i < exchanges.length; i++) {
            ofExchanges[i] = exchanges[i].exchange;
            ofAdapters[i] = exchanges[i].exchangeAdapter;
            takesCustody[i] = exchanges[i].takesCustody;
        }
        return (ofExchanges, ofAdapters, takesCustody);
    }
    function orderExpired(address ofExchange, address ofAsset) view returns (bool) {
        uint expiryTime = exchangesToOpenMakeOrders[ofExchange][ofAsset].expiresAt;
        require(expiryTime > 0);
        return block.timestamp >= expiryTime;
    }
    function getOpenOrderInfo(address ofExchange, address ofAsset) view returns (uint, uint) {
        OpenMakeOrder order = exchangesToOpenMakeOrders[ofExchange][ofAsset];
        return (order.id, order.expiresAt);
    }
}

contract CompetitionCompliance is ComplianceInterface, DBC, Owned {

    address public competitionAddress;

     

     
     
    function CompetitionCompliance(address ofCompetition) public {
        competitionAddress = ofCompetition;
    }

     

     
     
     
     
     
    function isInvestmentPermitted(
        address ofParticipant,
        uint256 giveQuantity,
        uint256 shareQuantity
    )
        view
        returns (bool)
    {
        return competitionAddress == ofParticipant;
    }

     
     
     
     
     
    function isRedemptionPermitted(
        address ofParticipant,
        uint256 shareQuantity,
        uint256 receiveQuantity
    )
        view
        returns (bool)
    {
        return competitionAddress == ofParticipant;
    }

     
     
     
    function isCompetitionAllowed(
        address x
    )
        view
        returns (bool)
    {
        return CompetitionInterface(competitionAddress).isWhitelisted(x) && CompetitionInterface(competitionAddress).isCompetitionActive();
    }


     

     
     
    function changeCompetitionAddress(
        address ofCompetition
    )
        pre_cond(isOwner())
    {
        competitionAddress = ofCompetition;
    }

}

interface GenericExchangeInterface {

     

    event OrderUpdated(uint id);

     
     

    function makeOrder(
        address onExchange,
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    ) external returns (uint);
    function takeOrder(address onExchange, uint id, uint quantity) external returns (bool);
    function cancelOrder(address onExchange, uint id) external returns (bool);


     
     

    function isApproveOnly() view returns (bool);
    function getLastOrderId(address onExchange) view returns (uint);
    function isActive(address onExchange, uint id) view returns (bool);
    function getOwner(address onExchange, uint id) view returns (address);
    function getOrder(address onExchange, uint id) view returns (address, address, uint, uint);
    function getTimestamp(address onExchange, uint id) view returns (uint);

}

contract CanonicalRegistrar is DSThing, DBC {

     

    struct Asset {
        bool exists;  
        bytes32 name;  
        bytes8 symbol;  
        uint decimals;  
        string url;  
        string ipfsHash;  
        address breakIn;  
        address breakOut;  
        uint[] standards;  
        bytes4[] functionSignatures;  
        uint price;  
        uint timestamp;  
    }

    struct Exchange {
        bool exists;
        address adapter;  
         
        bool takesCustody;  
        bytes4[] functionSignatures;  
    }
     
     

     

     
    mapping (address => Asset) public assetInformation;
    address[] public registeredAssets;

    mapping (address => Exchange) public exchangeInformation;
    address[] public registeredExchanges;

     

     

     
     
     
     
     
     
     
     
     
     
     
     
    function registerAsset(
        address ofAsset,
        bytes32 inputName,
        bytes8 inputSymbol,
        uint inputDecimals,
        string inputUrl,
        string inputIpfsHash,
        address[2] breakInBreakOut,
        uint[] inputStandards,
        bytes4[] inputFunctionSignatures
    )
        auth
        pre_cond(!assetInformation[ofAsset].exists)
    {
        assetInformation[ofAsset].exists = true;
        registeredAssets.push(ofAsset);
        updateAsset(
            ofAsset,
            inputName,
            inputSymbol,
            inputDecimals,
            inputUrl,
            inputIpfsHash,
            breakInBreakOut,
            inputStandards,
            inputFunctionSignatures
        );
        assert(assetInformation[ofAsset].exists);
    }

     
     
     
     
     
     
     
    function registerExchange(
        address ofExchange,
        address ofExchangeAdapter,
        bool inputTakesCustody,
        bytes4[] inputFunctionSignatures
    )
        auth
        pre_cond(!exchangeInformation[ofExchange].exists)
    {
        exchangeInformation[ofExchange].exists = true;
        registeredExchanges.push(ofExchange);
        updateExchange(
            ofExchange,
            ofExchangeAdapter,
            inputTakesCustody,
            inputFunctionSignatures
        );
        assert(exchangeInformation[ofExchange].exists);
    }

     
     
     
     
     
     
     
     
    function updateAsset(
        address ofAsset,
        bytes32 inputName,
        bytes8 inputSymbol,
        uint inputDecimals,
        string inputUrl,
        string inputIpfsHash,
        address[2] ofBreakInBreakOut,
        uint[] inputStandards,
        bytes4[] inputFunctionSignatures
    )
        auth
        pre_cond(assetInformation[ofAsset].exists)
    {
        Asset asset = assetInformation[ofAsset];
        asset.name = inputName;
        asset.symbol = inputSymbol;
        asset.decimals = inputDecimals;
        asset.url = inputUrl;
        asset.ipfsHash = inputIpfsHash;
        asset.breakIn = ofBreakInBreakOut[0];
        asset.breakOut = ofBreakInBreakOut[1];
        asset.standards = inputStandards;
        asset.functionSignatures = inputFunctionSignatures;
    }

    function updateExchange(
        address ofExchange,
        address ofExchangeAdapter,
        bool inputTakesCustody,
        bytes4[] inputFunctionSignatures
    )
        auth
        pre_cond(exchangeInformation[ofExchange].exists)
    {
        Exchange exchange = exchangeInformation[ofExchange];
        exchange.adapter = ofExchangeAdapter;
        exchange.takesCustody = inputTakesCustody;
        exchange.functionSignatures = inputFunctionSignatures;
    }

     
     
     
     
    function removeAsset(
        address ofAsset,
        uint assetIndex
    )
        auth
        pre_cond(assetInformation[ofAsset].exists)
    {
        require(registeredAssets[assetIndex] == ofAsset);
        delete assetInformation[ofAsset];  
        delete registeredAssets[assetIndex];
        for (uint i = assetIndex; i < registeredAssets.length-1; i++) {
            registeredAssets[i] = registeredAssets[i+1];
        }
        registeredAssets.length--;
        assert(!assetInformation[ofAsset].exists);
    }

     
     
     
     
    function removeExchange(
        address ofExchange,
        uint exchangeIndex
    )
        auth
        pre_cond(exchangeInformation[ofExchange].exists)
    {
        require(registeredExchanges[exchangeIndex] == ofExchange);
        delete exchangeInformation[ofExchange];
        delete registeredExchanges[exchangeIndex];
        for (uint i = exchangeIndex; i < registeredExchanges.length-1; i++) {
            registeredExchanges[i] = registeredExchanges[i+1];
        }
        registeredExchanges.length--;
        assert(!exchangeInformation[ofExchange].exists);
    }

     

     
    function getName(address ofAsset) view returns (bytes32) { return assetInformation[ofAsset].name; }
    function getSymbol(address ofAsset) view returns (bytes8) { return assetInformation[ofAsset].symbol; }
    function getDecimals(address ofAsset) view returns (uint) { return assetInformation[ofAsset].decimals; }
    function assetIsRegistered(address ofAsset) view returns (bool) { return assetInformation[ofAsset].exists; }
    function getRegisteredAssets() view returns (address[]) { return registeredAssets; }
    function assetMethodIsAllowed(
        address ofAsset, bytes4 querySignature
    )
        returns (bool)
    {
        bytes4[] memory signatures = assetInformation[ofAsset].functionSignatures;
        for (uint i = 0; i < signatures.length; i++) {
            if (signatures[i] == querySignature) {
                return true;
            }
        }
        return false;
    }

     
    function exchangeIsRegistered(address ofExchange) view returns (bool) { return exchangeInformation[ofExchange].exists; }
    function getRegisteredExchanges() view returns (address[]) { return registeredExchanges; }
    function getExchangeInformation(address ofExchange)
        view
        returns (address, bool)
    {
        Exchange exchange = exchangeInformation[ofExchange];
        return (
            exchange.adapter,
            exchange.takesCustody
        );
    }
    function getExchangeFunctionSignatures(address ofExchange)
        view
        returns (bytes4[])
    {
        return exchangeInformation[ofExchange].functionSignatures;
    }
    function exchangeMethodIsAllowed(
        address ofExchange, bytes4 querySignature
    )
        returns (bool)
    {
        bytes4[] memory signatures = exchangeInformation[ofExchange].functionSignatures;
        for (uint i = 0; i < signatures.length; i++) {
            if (signatures[i] == querySignature) {
                return true;
            }
        }
        return false;
    }
}

interface SimplePriceFeedInterface {

     

    event PriceUpdated(bytes32 hash);

     

    function update(address[] ofAssets, uint[] newPrices) external;

     

     
    function getQuoteAsset() view returns (address);
    function getLastUpdateId() view returns (uint);
     
    function getPrice(address ofAsset) view returns (uint price, uint timestamp);
    function getPrices(address[] ofAssets) view returns (uint[] prices, uint[] timestamps);
}

contract SimplePriceFeed is SimplePriceFeedInterface, DSThing, DBC {

     
    struct Data {
        uint price;
        uint timestamp;
    }

     
    mapping(address => Data) public assetsToPrices;

     
    address public QUOTE_ASSET;  

     
    uint public updateId;         
    CanonicalRegistrar public registrar;
    CanonicalPriceFeed public superFeed;

     

     

     
     
     
    function SimplePriceFeed(
        address ofRegistrar,
        address ofQuoteAsset,
        address ofSuperFeed
    ) {
        registrar = CanonicalRegistrar(ofRegistrar);
        QUOTE_ASSET = ofQuoteAsset;
        superFeed = CanonicalPriceFeed(ofSuperFeed);
    }

     

     
     
     
     
     
    function update(address[] ofAssets, uint[] newPrices)
        external
        auth
    {
        _updatePrices(ofAssets, newPrices);
    }

     

     
    function getQuoteAsset() view returns (address) { return QUOTE_ASSET; }
    function getLastUpdateId() view returns (uint) { return updateId; }

     
    function getPrice(address ofAsset)
        view
        returns (uint price, uint timestamp)
    {
        Data data = assetsToPrices[ofAsset];
        return (data.price, data.timestamp);
    }

     
    function getPrices(address[] ofAssets)
        view
        returns (uint[], uint[])
    {
        uint[] memory prices = new uint[](ofAssets.length);
        uint[] memory timestamps = new uint[](ofAssets.length);
        for (uint i; i < ofAssets.length; i++) {
            var (price, timestamp) = getPrice(ofAssets[i]);
            prices[i] = price;
            timestamps[i] = timestamp;
        }
        return (prices, timestamps);
    }

     

     
    function _updatePrices(address[] ofAssets, uint[] newPrices)
        internal
        pre_cond(ofAssets.length == newPrices.length)
    {
        updateId++;
        for (uint i = 0; i < ofAssets.length; ++i) {
            require(registrar.assetIsRegistered(ofAssets[i]));
            require(assetsToPrices[ofAssets[i]].timestamp != now);  
            assetsToPrices[ofAssets[i]].timestamp = now;
            assetsToPrices[ofAssets[i]].price = newPrices[i];
        }
        emit PriceUpdated(keccak256(ofAssets, newPrices));
    }
}

contract StakingPriceFeed is SimplePriceFeed {

    OperatorStaking public stakingContract;
    AssetInterface public stakingToken;

     

     
     
     
    function StakingPriceFeed(
        address ofRegistrar,
        address ofQuoteAsset,
        address ofSuperFeed
    )
        SimplePriceFeed(ofRegistrar, ofQuoteAsset, ofSuperFeed)
    {
        stakingContract = OperatorStaking(ofSuperFeed);  
        stakingToken = AssetInterface(stakingContract.stakingToken());
    }

     

     
     
    function depositStake(uint amount, bytes data)
        external
        auth
    {
        require(stakingToken.transferFrom(msg.sender, address(this), amount));
        require(stakingToken.approve(stakingContract, amount));
        stakingContract.stake(amount, data);
    }

     
     
    function unstake(uint amount, bytes data) {
        stakingContract.unstake(amount, data);
    }

    function withdrawStake()
        external
        auth
    {
        uint amountToWithdraw = stakingContract.stakeToWithdraw(address(this));
        stakingContract.withdrawStake();
        require(stakingToken.transfer(msg.sender, amountToWithdraw));
    }
}

interface RiskMgmtInterface {

     
     

     
     
     
     
     
     
     
     
    function isMakePermitted(
        uint orderPrice,
        uint referencePrice,
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    ) view returns (bool);

     
     
     
     
     
     
     
     
    function isTakePermitted(
        uint orderPrice,
        uint referencePrice,
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    ) view returns (bool);
}

contract OperatorStaking is DBC {

     

    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);
    event StakeBurned(address indexed user, uint256 amount, bytes data);

     

    struct StakeData {
        uint amount;
        address staker;
    }

     
    struct Node {
        StakeData data;
        uint prev;
        uint next;
    }

     

     
    Node[] internal stakeNodes;  

     
    uint public minimumStake;
    uint public numOperators;
    uint public withdrawalDelay;
    mapping (address => bool) public isRanked;
    mapping (address => uint) public latestUnstakeTime;
    mapping (address => uint) public stakeToWithdraw;
    mapping (address => uint) public stakedAmounts;
    uint public numStakers;  
    AssetInterface public stakingToken;

     
     
    function OperatorStaking(
        AssetInterface _stakingToken,
        uint _minimumStake,
        uint _numOperators,
        uint _withdrawalDelay
    )
        public
    {
        require(address(_stakingToken) != address(0));
        stakingToken = _stakingToken;
        minimumStake = _minimumStake;
        numOperators = _numOperators;
        withdrawalDelay = _withdrawalDelay;
        StakeData memory temp = StakeData({ amount: 0, staker: address(0) });
        stakeNodes.push(Node(temp, 0, 0));
    }

     

    function stake(
        uint amount,
        bytes data
    )
        public
        pre_cond(amount >= minimumStake)
    {
        uint tailNodeId = stakeNodes[0].prev;
        stakedAmounts[msg.sender] += amount;
        updateStakerRanking(msg.sender);
        require(stakingToken.transferFrom(msg.sender, address(this), amount));
    }

    function unstake(
        uint amount,
        bytes data
    )
        public
    {
        uint preStake = stakedAmounts[msg.sender];
        uint postStake = preStake - amount;
        require(postStake >= minimumStake || postStake == 0);
        require(stakedAmounts[msg.sender] >= amount);
        latestUnstakeTime[msg.sender] = block.timestamp;
        stakedAmounts[msg.sender] -= amount;
        stakeToWithdraw[msg.sender] += amount;
        updateStakerRanking(msg.sender);
        emit Unstaked(msg.sender, amount, stakedAmounts[msg.sender], data);
    }

    function withdrawStake()
        public
        pre_cond(stakeToWithdraw[msg.sender] > 0)
        pre_cond(block.timestamp >= latestUnstakeTime[msg.sender] + withdrawalDelay)
    {
        uint amount = stakeToWithdraw[msg.sender];
        stakeToWithdraw[msg.sender] = 0;
        require(stakingToken.transfer(msg.sender, amount));
    }

     

    function isValidNode(uint id) view returns (bool) {
         
         
        return id != 0 && (id == stakeNodes[0].next || stakeNodes[id].prev != 0);
    }

    function searchNode(address staker) view returns (uint) {
        uint current = stakeNodes[0].next;
        while (isValidNode(current)) {
            if (staker == stakeNodes[current].data.staker) {
                return current;
            }
            current = stakeNodes[current].next;
        }
        return 0;
    }

    function isOperator(address user) view returns (bool) {
        address[] memory operators = getOperators();
        for (uint i; i < operators.length; i++) {
            if (operators[i] == user) {
                return true;
            }
        }
        return false;
    }

    function getOperators()
        view
        returns (address[])
    {
        uint arrLength = (numOperators > numStakers) ?
            numStakers :
            numOperators;
        address[] memory operators = new address[](arrLength);
        uint current = stakeNodes[0].next;
        for (uint i; i < arrLength; i++) {
            operators[i] = stakeNodes[current].data.staker;
            current = stakeNodes[current].next;
        }
        return operators;
    }

    function getStakersAndAmounts()
        view
        returns (address[], uint[])
    {
        address[] memory stakers = new address[](numStakers);
        uint[] memory amounts = new uint[](numStakers);
        uint current = stakeNodes[0].next;
        for (uint i; i < numStakers; i++) {
            stakers[i] = stakeNodes[current].data.staker;
            amounts[i] = stakeNodes[current].data.amount;
            current = stakeNodes[current].next;
        }
        return (stakers, amounts);
    }

    function totalStakedFor(address user)
        view
        returns (uint)
    {
        return stakedAmounts[user];
    }

     

     

    function insertNodeSorted(uint amount, address staker) internal returns (uint) {
        uint current = stakeNodes[0].next;
        if (current == 0) return insertNodeAfter(0, amount, staker);
        while (isValidNode(current)) {
            if (amount > stakeNodes[current].data.amount) {
                break;
            }
            current = stakeNodes[current].next;
        }
        return insertNodeBefore(current, amount, staker);
    }

    function insertNodeAfter(uint id, uint amount, address staker) internal returns (uint newID) {

         
        require(id == 0 || isValidNode(id));

        Node storage node = stakeNodes[id];

        stakeNodes.push(Node({
            data: StakeData(amount, staker),
            prev: id,
            next: node.next
        }));

        newID = stakeNodes.length - 1;

        stakeNodes[node.next].prev = newID;
        node.next = newID;
        numStakers++;
    }

    function insertNodeBefore(uint id, uint amount, address staker) internal returns (uint) {
        return insertNodeAfter(stakeNodes[id].prev, amount, staker);
    }

    function removeNode(uint id) internal {
        require(isValidNode(id));

        Node storage node = stakeNodes[id];

        stakeNodes[node.next].prev = node.prev;
        stakeNodes[node.prev].next = node.next;

        delete stakeNodes[id];
        numStakers--;
    }

     

    function updateStakerRanking(address _staker) internal {
        uint newStakedAmount = stakedAmounts[_staker];
        if (newStakedAmount == 0) {
            isRanked[_staker] = false;
            removeStakerFromArray(_staker);
        } else if (isRanked[_staker]) {
            removeStakerFromArray(_staker);
            insertNodeSorted(newStakedAmount, _staker);
        } else {
            isRanked[_staker] = true;
            insertNodeSorted(newStakedAmount, _staker);
        }
    }

    function removeStakerFromArray(address _staker) internal {
        uint id = searchNode(_staker);
        require(id > 0);
        removeNode(id);
    }

}

contract CanonicalPriceFeed is OperatorStaking, SimplePriceFeed, CanonicalRegistrar {

     
    event SetupPriceFeed(address ofPriceFeed);

    struct HistoricalPrices {
        address[] assets;
        uint[] prices;
        uint timestamp;
    }

     
    bool public updatesAreAllowed = true;
    uint public minimumPriceCount = 1;
    uint public VALIDITY;
    uint public INTERVAL;
    mapping (address => bool) public isStakingFeed;  
    HistoricalPrices[] public priceHistory;

     

     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function CanonicalPriceFeed(
        address ofStakingAsset,
        address ofQuoteAsset,  
        bytes32 quoteAssetName,
        bytes8 quoteAssetSymbol,
        uint quoteAssetDecimals,
        string quoteAssetUrl,
        string quoteAssetIpfsHash,
        address[2] quoteAssetBreakInBreakOut,
        uint[] quoteAssetStandards,
        bytes4[] quoteAssetFunctionSignatures,
        uint[2] updateInfo,  
        uint[3] stakingInfo,  
        address ofGovernance
    )
        OperatorStaking(
            AssetInterface(ofStakingAsset), stakingInfo[0], stakingInfo[1], stakingInfo[2]
        )
        SimplePriceFeed(address(this), ofQuoteAsset, address(0))
    {
        registerAsset(
            ofQuoteAsset,
            quoteAssetName,
            quoteAssetSymbol,
            quoteAssetDecimals,
            quoteAssetUrl,
            quoteAssetIpfsHash,
            quoteAssetBreakInBreakOut,
            quoteAssetStandards,
            quoteAssetFunctionSignatures
        );
        INTERVAL = updateInfo[0];
        VALIDITY = updateInfo[1];
        setOwner(ofGovernance);
    }

     

     
    function setupStakingPriceFeed() external {
        address ofStakingPriceFeed = new StakingPriceFeed(
            address(this),
            stakingToken,
            address(this)
        );
        isStakingFeed[ofStakingPriceFeed] = true;
        StakingPriceFeed(ofStakingPriceFeed).setOwner(msg.sender);
        emit SetupPriceFeed(ofStakingPriceFeed);
    }

     
    function update() external { revert(); }

     
     
    function burnStake(address user)
        external
        auth
    {
        uint totalToBurn = add(stakedAmounts[user], stakeToWithdraw[user]);
        stakedAmounts[user] = 0;
        stakeToWithdraw[user] = 0;
        updateStakerRanking(user);
        emit StakeBurned(user, totalToBurn, "");
    }

     

     

    function stake(
        uint amount,
        bytes data
    )
        public
        pre_cond(isStakingFeed[msg.sender])
    {
        OperatorStaking.stake(amount, data);
    }

     
     
     
     
     
     
     
     

     
     

     

     
     
     
     
    function collectAndUpdate(address[] ofAssets)
        public
        auth
        pre_cond(updatesAreAllowed)
    {
        uint[] memory newPrices = pricesToCommit(ofAssets);
        priceHistory.push(
            HistoricalPrices({assets: ofAssets, prices: newPrices, timestamp: block.timestamp})
        );
        _updatePrices(ofAssets, newPrices);
    }

    function pricesToCommit(address[] ofAssets)
        view
        returns (uint[])
    {
        address[] memory operators = getOperators();
        uint[] memory newPrices = new uint[](ofAssets.length);
        for (uint i = 0; i < ofAssets.length; i++) {
            uint[] memory assetPrices = new uint[](operators.length);
            for (uint j = 0; j < operators.length; j++) {
                SimplePriceFeed feed = SimplePriceFeed(operators[j]);
                var (price, timestamp) = feed.assetsToPrices(ofAssets[i]);
                if (now > add(timestamp, VALIDITY)) {
                    continue;  
                }
                assetPrices[j] = price;
            }
            newPrices[i] = medianize(assetPrices);
        }
        return newPrices;
    }

     
    function medianize(uint[] unsorted)
        view
        returns (uint)
    {
        uint numValidEntries;
        for (uint i = 0; i < unsorted.length; i++) {
            if (unsorted[i] != 0) {
                numValidEntries++;
            }
        }
        if (numValidEntries < minimumPriceCount) {
            revert();
        }
        uint counter;
        uint[] memory out = new uint[](numValidEntries);
        for (uint j = 0; j < unsorted.length; j++) {
            uint item = unsorted[j];
            if (item != 0) {     
                if (counter == 0 || item >= out[counter - 1]) {
                    out[counter] = item;   
                } else {
                    uint k = 0;
                    while (item >= out[k]) {
                        k++;   
                    }
                    for (uint l = counter; l > k; l--) {
                        out[l] = out[l - 1];     
                    }
                    out[k] = item;
                }
                counter++;
            }
        }

        uint value;
        if (counter % 2 == 0) {
            uint value1 = uint(out[(counter / 2) - 1]);
            uint value2 = uint(out[(counter / 2)]);
            value = add(value1, value2) / 2;
        } else {
            value = out[(counter - 1) / 2];
        }
        return value;
    }

    function setMinimumPriceCount(uint newCount) auth { minimumPriceCount = newCount; }
    function enableUpdates() auth { updatesAreAllowed = true; }
    function disableUpdates() auth { updatesAreAllowed = false; }

     

     

    function getQuoteAsset() view returns (address) { return QUOTE_ASSET; }
    function getInterval() view returns (uint) { return INTERVAL; }
    function getValidity() view returns (uint) { return VALIDITY; }
    function getLastUpdateId() view returns (uint) { return updateId; }

     

     
     
     
    function hasRecentPrice(address ofAsset)
        view
        pre_cond(assetIsRegistered(ofAsset))
        returns (bool isRecent)
    {
        var ( , timestamp) = getPrice(ofAsset);
        return (sub(now, timestamp) <= VALIDITY);
    }

     
     
     
    function hasRecentPrices(address[] ofAssets)
        view
        returns (bool areRecent)
    {
        for (uint i; i < ofAssets.length; i++) {
            if (!hasRecentPrice(ofAssets[i])) {
                return false;
            }
        }
        return true;
    }

    function getPriceInfo(address ofAsset)
        view
        returns (bool isRecent, uint price, uint assetDecimals)
    {
        isRecent = hasRecentPrice(ofAsset);
        (price, ) = getPrice(ofAsset);
        assetDecimals = getDecimals(ofAsset);
    }

     
    function getInvertedPriceInfo(address ofAsset)
        view
        returns (bool isRecent, uint invertedPrice, uint assetDecimals)
    {
        uint inputPrice;
         
        (isRecent, inputPrice, assetDecimals) = getPriceInfo(ofAsset);

         
        uint quoteDecimals = getDecimals(QUOTE_ASSET);

        return (
            isRecent,
            mul(10 ** uint(quoteDecimals), 10 ** uint(assetDecimals)) / inputPrice,
            quoteDecimals    
        );
    }

     
    function getReferencePriceInfo(address ofBase, address ofQuote)
        view
        returns (bool isRecent, uint referencePrice, uint decimal)
    {
        if (getQuoteAsset() == ofQuote) {
            (isRecent, referencePrice, decimal) = getPriceInfo(ofBase);
        } else if (getQuoteAsset() == ofBase) {
            (isRecent, referencePrice, decimal) = getInvertedPriceInfo(ofQuote);
        } else {
            revert();  
        }
    }

     
     
     
     
     
     
    function getOrderPriceInfo(
        address sellAsset,
        address buyAsset,
        uint sellQuantity,
        uint buyQuantity
    )
        view
        returns (uint orderPrice)
    {
        return mul(buyQuantity, 10 ** uint(getDecimals(sellAsset))) / sellQuantity;
    }

     
     
     
     
     
    function existsPriceOnAssetPair(address sellAsset, address buyAsset)
        view
        returns (bool isExistent)
    {
        return
            hasRecentPrice(sellAsset) &&  
            hasRecentPrice(buyAsset) &&  
            (buyAsset == QUOTE_ASSET || sellAsset == QUOTE_ASSET) &&  
            (buyAsset != QUOTE_ASSET || sellAsset != QUOTE_ASSET);  
    }

     
    function getPriceFeedsByOwner(address _owner)
        view
        returns(address[])
    {
        address[] memory ofPriceFeeds = new address[](numStakers);
        if (numStakers == 0) return ofPriceFeeds;
        uint current = stakeNodes[0].next;
        for (uint i; i < numStakers; i++) {
            StakingPriceFeed stakingFeed = StakingPriceFeed(stakeNodes[current].data.staker);
            if (stakingFeed.owner() == _owner) {
                ofPriceFeeds[i] = address(stakingFeed);
            }
            current = stakeNodes[current].next;
        }
        return ofPriceFeeds;
    }

    function getHistoryLength() returns (uint) { return priceHistory.length; }

    function getHistoryAt(uint id) returns (address[], uint[], uint) {
        address[] memory assets = priceHistory[id].assets;
        uint[] memory prices = priceHistory[id].prices;
        uint timestamp = priceHistory[id].timestamp;
        return (assets, prices, timestamp);
    }
}

interface VersionInterface {

     

    event FundUpdated(uint id);

     

    function shutDown() external;

    function setupFund(
        bytes32 ofFundName,
        address ofQuoteAsset,
        uint ofManagementFee,
        uint ofPerformanceFee,
        address ofCompliance,
        address ofRiskMgmt,
        address[] ofExchanges,
        address[] ofDefaultAssets,
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    function shutDownFund(address ofFund);

     

    function getNativeAsset() view returns (address);
    function getFundById(uint withId) view returns (address);
    function getLastFundId() view returns (uint);
    function getFundByManager(address ofManager) view returns (address);
    function termsAndConditionsAreSigned(uint8 v, bytes32 r, bytes32 s) view returns (bool signed);

}

contract Version is DBC, Owned, VersionInterface {
     

    bytes32 public constant TERMS_AND_CONDITIONS = 0xAA9C907B0D6B4890E7225C09CBC16A01CB97288840201AA7CDCB27F4ED7BF159;  

     
    string public VERSION_NUMBER;  
    address public MELON_ASSET;  
    address public NATIVE_ASSET;  
    address public GOVERNANCE;  
    address public CANONICAL_PRICEFEED;  

     
    bool public isShutDown;  
    address public COMPLIANCE;  
    address[] public listOfFunds;  
    mapping (address => address) public managerToFunds;  

     

    event FundUpdated(address ofFund);

     

     

     
     
     
    function Version(
        string versionNumber,
        address ofGovernance,
        address ofMelonAsset,
        address ofNativeAsset,
        address ofCanonicalPriceFeed,
        address ofCompetitionCompliance
    ) {
        VERSION_NUMBER = versionNumber;
        GOVERNANCE = ofGovernance;
        MELON_ASSET = ofMelonAsset;
        NATIVE_ASSET = ofNativeAsset;
        CANONICAL_PRICEFEED = ofCanonicalPriceFeed;
        COMPLIANCE = ofCompetitionCompliance;
    }

     

    function shutDown() external pre_cond(msg.sender == GOVERNANCE) { isShutDown = true; }

     

     
     
     
     
     
     
     
     
     
     
     
    function setupFund(
        bytes32 ofFundName,
        address ofQuoteAsset,
        uint ofManagementFee,
        uint ofPerformanceFee,
        address ofCompliance,
        address ofRiskMgmt,
        address[] ofExchanges,
        address[] ofDefaultAssets,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) {
        require(!isShutDown);
        require(termsAndConditionsAreSigned(v, r, s));
        require(CompetitionCompliance(COMPLIANCE).isCompetitionAllowed(msg.sender));
        require(managerToFunds[msg.sender] == address(0));  
        address[] memory melonAsDefaultAsset = new address[](1);
        melonAsDefaultAsset[0] = MELON_ASSET;  
        address ofFund = new Fund(
            msg.sender,
            ofFundName,
            NATIVE_ASSET,
            0,
            0,
            COMPLIANCE,
            ofRiskMgmt,
            CANONICAL_PRICEFEED,
            ofExchanges,
            melonAsDefaultAsset
        );
        listOfFunds.push(ofFund);
        managerToFunds[msg.sender] = ofFund;
        emit FundUpdated(ofFund);
    }

     
     
    function shutDownFund(address ofFund)
        pre_cond(isShutDown || managerToFunds[msg.sender] == ofFund)
    {
        Fund fund = Fund(ofFund);
        delete managerToFunds[msg.sender];
        fund.shutDown();
        emit FundUpdated(ofFund);
    }

     

     
     
     
     
     
    function termsAndConditionsAreSigned(uint8 v, bytes32 r, bytes32 s) view returns (bool signed) {
        return ecrecover(
             
             
             
             
             
             
             
            keccak256("\x19Ethereum Signed Message:\n32", TERMS_AND_CONDITIONS),
            v,
            r,
            s
        ) == msg.sender;  
    }

    function getNativeAsset() view returns (address) { return NATIVE_ASSET; }
    function getFundById(uint withId) view returns (address) { return listOfFunds[withId]; }
    function getLastFundId() view returns (uint) { return listOfFunds.length - 1; }
    function getFundByManager(address ofManager) view returns (address) { return managerToFunds[ofManager]; }
}