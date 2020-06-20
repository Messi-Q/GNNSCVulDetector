pragma solidity ^0.4.18;

 
 
 

 
 
contract CrowdsaleL{

	 
	 
    
    using SafeMath for uint256;

    enum TokenSaleType {round1, round2}
    enum Roles {beneficiary, accountant, manager, observer, bounty, team, company}
    
     
    address constant TaxCollector = 0x0;
	 
    uint256[2] TaxValues = [0 finney, 0 finney];
    uint8 vaultNum;

    TokenL public token;

    bool public isFinalized;
    bool public isInitialized;
    bool public isPausedCrowdsale;


     
     
     
     
     
     
    address[7] public wallets = [
        
         
         
        0x9a1Fc7173086412A10dE27A9d1d543af3AB68262,
        
         
         
        0x9a1Fc7173086412A10dE27A9d1d543af3AB68262,
        
         
         
         
         
         
         
        msg.sender,
        
         
         
        0x8a91aC199440Da0B45B2E278f3fE616b1bCcC494,

         
        0x9a1Fc7173086412A10dE27A9d1d543af3AB68262,

         
         
         
         
         
        0x9a1Fc7173086412A10dE27A9d1d543af3AB68262,
        
         
        0x9a1Fc7173086412A10dE27A9d1d543af3AB68262
        ];

    struct Profit{
	    uint256 min;     
	    uint256 max;     
	    uint256 step;    
	    uint256 maxAllProfit; 
    }
    struct Bonus {
	    uint256 value;
	    uint256 procent;
	    uint256 freezeTime;
    }

    Bonus[] public bonuses;

    Profit public profit = Profit(0, 20, 4, 50);
    
    uint256 public startTime= 1518912000;  
    uint256 public endDiscountTime = 1521936000;  
    uint256 public endTime = 1522800000;  

     
     
     
    uint256 public rate = 18000000;

     
     
     
    uint256 public softCap = 0 ether;

     
     
    uint256 public hardCap = 19444 ether;

     
     
     
     
     
     
     
    uint256 public overLimit = 20 ether;

     
     
    uint256 public minPay = 10 finney;

    uint256 public ethWeiRaised;
    uint256 public nonEthWeiRaised;
    uint256 public weiRound1;
    uint256 public tokenReserved;

    RefundVault public vault;
     

    TokenSaleType TokenSale = TokenSaleType.round2;

    uint256 public allToken;

    bool public bounty;
    bool public team;
    bool public company;
     

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event Finalized();
    event Initialized();

    function CrowdsaleL(TokenL _token, uint256 firstMint) public
    {

        token = _token;
        token.setOwner();

        token.pause();  

        token.addUnpausedWallet(wallets[uint8(Roles.accountant)]);
        token.addUnpausedWallet(msg.sender);
         
         
        
        token.setFreezingManager(wallets[uint8(Roles.accountant)]);
        
        bonuses.push(Bonus(11111 finney,30,60 days));
        bonuses.push(Bonus(55556 finney,40,90 days));
        bonuses.push(Bonus(111111 finney,50,180 days));

        if (firstMint > 0) {
            token.mint(msg.sender, firstMint);
        }

    }

     
    function getTokenSaleType()  public constant returns(string){
        return (TokenSale == TokenSaleType.round1)?'round1':'round2';
    }

     
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

     
    function validPurchase() internal constant returns (bool) {

         
        bool withinPeriod = (now > startTime && now < endTime);

         
        bool nonZeroPurchase = msg.value >= minPay;

         
        bool withinCap = msg.value <= hardCap.sub(weiRaised()).add(overLimit);

         
        return withinPeriod && nonZeroPurchase && withinCap && isInitialized && !isPausedCrowdsale;
    }

     
    function hasEnded() public constant returns (bool) {

        bool timeReached = now > endTime;

        bool capReached = weiRaised() >= hardCap;

        return (timeReached || capReached) && isInitialized;
    }
    
    function finalizeAll() external {
        finalize();
        finalize1();
        finalize2();
        finalize3();
    }

     
     
     
    function finalize() public {

        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender || !goalReached());
        require(!isFinalized);
        require(hasEnded());

        isFinalized = true;
        finalization();
        Finalized();
    }

     
    function finalization() internal {

         
        if (goalReached()) {

             
            vault.close(wallets[uint8(Roles.beneficiary)]);

             
            if (tokenReserved > 0) {

                 
                token.mint(wallets[uint8(Roles.accountant)],tokenReserved);

                 
                tokenReserved = 0;
            }

             
            if (TokenSale == TokenSaleType.round1) {

                 
                isInitialized = false;
                isFinalized = false;

                 
                TokenSale = TokenSaleType.round2;

                 
                weiRound1 = weiRaised();
                ethWeiRaised = 0;
                nonEthWeiRaised = 0;


            }
            else  
            {

                 
                allToken = token.totalSupply();

                 
                bounty = true;
                team = true;
                company = true;
                 

            }

        }
        else  
        {
             
            vault.enableRefunds();
        }
    }

     
     
    function finalize1() public {
        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender);
        require(team);
        team = false;
         
         
 
 
 

		 
        token.mint(wallets[uint8(Roles.team)],allToken.mul(14).div(80));
    }

     
     
    function finalize2() public {
        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender);
        require(bounty);
        bounty = false;
         
         
        token.mint(wallets[uint8(Roles.bounty)],allToken.mul(3).div(80));
    }

     
     
    function finalize3() public {
        require(wallets[uint8(Roles.manager)] == msg.sender || wallets[uint8(Roles.beneficiary)] == msg.sender);
        require(company);
        company = false;
         
         
        token.mint(wallets[uint8(Roles.company)],allToken.mul(3).div(80));
    }


     
     
     
     
    function initialize() public {

         
        require(wallets[uint8(Roles.manager)] == msg.sender);

         
        require(!isInitialized);

         
         
        require(now <= startTime);

        initialization();

        Initialized();

        isInitialized = true;
    }

    function initialization() internal {
        uint256 taxValue = TaxValues[vaultNum];
        vaultNum++;
        uint256 arrear;
        if (address(vault) != 0x0){
            arrear = DistributorRefundVault(vault).taxValue();
            vault.del(wallets[uint8(Roles.beneficiary)]);
        }
        vault = new DistributorRefundVault(TaxCollector, taxValue.add(arrear));
    }

     
    function claimRefund() public{
        vault.refund(msg.sender);
    }

     
    function goalReached() public constant returns (bool) {
        return weiRaised() >= softCap;
    }

     
    function setup(uint256 _startTime, uint256 _endDiscountTime, uint256 _endTime, uint256 _softCap, uint256 _hardCap, uint256 _rate, uint256 _overLimit, uint256 _minPay, uint256 _minProfit, uint256 _maxProfit, uint256 _stepProfit, uint256 _maxAllProfit, uint256[] _value, uint256[] _procent, uint256[] _freezeTime) public{
        changePeriod(_startTime, _endDiscountTime, _endTime);
        changeTargets(_softCap, _hardCap);
        changeRate(_rate, _overLimit, _minPay);
        changeDiscount(_minProfit, _maxProfit, _stepProfit, _maxAllProfit);
        setBonuses(_value, _procent, _freezeTime);
    }

     
     
    function changePeriod(uint256 _startTime, uint256 _endDiscountTime, uint256 _endTime) public{

        require(wallets[uint8(Roles.manager)] == msg.sender);

        require(!isInitialized);

         
        require(now <= _startTime);
        require(_endDiscountTime > _startTime && _endDiscountTime <= _endTime);

        startTime = _startTime;
        endTime = _endTime;
        endDiscountTime = _endDiscountTime;

    }

     
     
    function changeTargets(uint256 _softCap, uint256 _hardCap) public {

        require(wallets[uint8(Roles.manager)] == msg.sender);

        require(!isInitialized);

         
        require(_softCap <= _hardCap);

        softCap = _softCap;
        hardCap = _hardCap;
    }

     
     
     
    function changeRate(uint256 _rate, uint256 _overLimit, uint256 _minPay) public {

        require(wallets[uint8(Roles.manager)] == msg.sender);

        require(!isInitialized);

        require(_rate > 0);

        rate = _rate;
        overLimit = _overLimit;
        minPay = _minPay;
    }

     
     
    function changeDiscount(uint256 _minProfit, uint256 _maxProfit, uint256 _stepProfit, uint256 _maxAllProfit) public {

        require(wallets[uint8(Roles.manager)] == msg.sender);

        require(!isInitialized);
        
        require(_maxProfit <= _maxAllProfit);

         
        require(_stepProfit <= _maxProfit.sub(_minProfit));

         
        if(_stepProfit > 0){
             
             
            profit.max = _maxProfit.sub(_minProfit).div(_stepProfit).mul(_stepProfit).add(_minProfit);
        }else{
             
            profit.max = _minProfit;
        }

        profit.min = _minProfit;
        profit.step = _stepProfit;
        profit.maxAllProfit = _maxAllProfit;
    }

    function setBonuses(uint256[] _value, uint256[] _procent, uint256[] _dateUnfreeze) public {

        require(wallets[uint8(Roles.manager)] == msg.sender);
        require(!isInitialized);

        require(_value.length == _procent.length && _value.length == _dateUnfreeze.length);
        bonuses.length = _value.length;
        for(uint256 i = 0; i < _value.length; i++){
            bonuses[i] = Bonus(_value[i],_procent[i],_dateUnfreeze[i]);
        }
    }

     
    function weiRaised() public constant returns(uint256){
        return ethWeiRaised.add(nonEthWeiRaised);
    }

     
    function weiTotalRaised() public constant returns(uint256){
        return weiRound1.add(weiRaised());
    }

     
    function getProfitPercent() public constant returns (uint256){
        return getProfitPercentForData(now);
    }

     
    function getProfitPercentForData(uint256 timeNow) public constant returns (uint256){
         
        if (profit.max == 0 || profit.step == 0 || timeNow > endDiscountTime){
            return profit.min;
        }

         
        if (timeNow<=startTime){
            return profit.max;
        }

         
        uint256 range = endDiscountTime.sub(startTime);

         
        uint256 profitRange = profit.max.sub(profit.min);

         
        uint256 timeRest = endDiscountTime.sub(timeNow);

         
        uint256 profitProcent = profitRange.div(profit.step).mul(timeRest.mul(profit.step.add(1)).div(range));
        return profitProcent.add(profit.min);
    }

    function getBonuses(uint256 _value) public constant returns(uint256 procent, uint256 _dateUnfreeze){
        if(bonuses.length == 0 || bonuses[0].value > _value){
            return (0,0);
        }
        uint16 i = 1;
        for(i; i < bonuses.length; i++){
            if(bonuses[i].value > _value){
                break;
            }
        }
        return (bonuses[i-1].procent,bonuses[i-1].freezeTime);
    }

     
     
     
     
     
     
    function fastTokenSale(uint256 _totalSupply) public {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        require(TokenSale == TokenSaleType.round1 && !isInitialized);
        token.mint(wallets[uint8(Roles.accountant)], _totalSupply);
        TokenSale = TokenSaleType.round2;
    }

     
     
     
     
     
    function tokenUnpause() public {
        require(wallets[uint8(Roles.manager)] == msg.sender
            || (now > endTime + 30 days && TokenSale == TokenSaleType.round2 && isFinalized && goalReached()));
        token.unpause();
    }

     
     
    function tokenPause() public {
        require(wallets[uint8(Roles.manager)] == msg.sender && !isFinalized);
        token.pause();
    }

     
    function crowdsalePause() public {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        require(isPausedCrowdsale == false);
        isPausedCrowdsale = true;
    }

     
    function crowdsaleUnpause() public {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        require(isPausedCrowdsale == true);
        isPausedCrowdsale = false;
    }

     
     
     
     
     
     
    function unpausedWallet(address _wallet) internal constant returns(bool) {
        bool _accountant = wallets[uint8(Roles.accountant)] == _wallet;
        bool _manager = wallets[uint8(Roles.manager)] == _wallet;
        bool _bounty = wallets[uint8(Roles.bounty)] == _wallet;
        bool _company = wallets[uint8(Roles.company)] == _wallet;
        return _accountant || _manager || _bounty || _company;
    }

     
     
     
     
     
     
     
     
    function moveTokens(address _migrationAgent) public {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        token.setMigrationAgent(_migrationAgent);
    }

    function migrateAll(address[] _holders) public {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        token.migrateAll(_holders);
    }

     
     
     
     
    function changeWallet(Roles _role, address _wallet) public
    {
        require(
        (msg.sender == wallets[uint8(_role)] && _role != Roles.observer)
        ||
        (msg.sender == wallets[uint8(Roles.manager)] && (!isInitialized || _role == Roles.observer))
        );
        address oldWallet = wallets[uint8(_role)];
        wallets[uint8(_role)] = _wallet;
        if(token.unpausedWallet(oldWallet))
            token.delUnpausedWallet(oldWallet);
        if(unpausedWallet(_wallet))
            token.addUnpausedWallet(_wallet);
        
        if(_role == Roles.accountant)
            token.setFreezingManager(wallets[uint8(Roles.accountant)]);
    }
    
    
     
     
     
    function resetAllWallets() public{
        address _beneficiary = wallets[uint8(Roles.beneficiary)];
        require(msg.sender == _beneficiary);
        for(uint8 i = 0; i < wallets.length; i++){
            if(token.unpausedWallet(wallets[i]))
                token.delUnpausedWallet(wallets[i]);
            wallets[i] = _beneficiary;
        }
        token.addUnpausedWallet(_beneficiary);
    }
    

     
     
     
     
     
     
     

     
     

     
     

     

     
     
    function distructVault() public {
 		if (wallets[uint8(Roles.beneficiary)] == msg.sender && (now > startTime + 400 days)) {
 			vault.del(wallets[uint8(Roles.beneficiary)]);
 		}
 		if (wallets[uint8(Roles.manager)] == msg.sender && (now > startTime + 600 days)) {
 			vault.del(wallets[uint8(Roles.manager)]);
 		}    
    }


     
     

     
     

     
     
     
     
     

     
     
     

     
     
     
     
     
     

     
     
     
     
     

     
     
     
     
     

     

     
     

     
    function paymentsInOtherCurrency(uint256 _token, uint256 _value) public {
        require(wallets[uint8(Roles.observer)] == msg.sender || wallets[uint8(Roles.manager)] == msg.sender);
        bool withinPeriod = (now >= startTime && now <= endTime);

        bool withinCap = _value.add(ethWeiRaised) <= hardCap.add(overLimit);
        require(withinPeriod && withinCap && isInitialized);

        nonEthWeiRaised = _value;
        tokenReserved = _token;

    }
    
    function changeLock(address _owner, uint256 _value, uint256 _date) external {
        require(wallets[uint8(Roles.manager)] == msg.sender);
        token.changeLock(_owner, _value, _date);
    }

    function lokedMint(address _beneficiary, uint256 _value, uint256 _freezeTime) internal {
        if(_freezeTime > 0){
            
            uint256 totalBloked = token.valueBlocked(_beneficiary).add(_value);
            uint256 pastDateUnfreeze = token.blikedUntil(_beneficiary);
            uint256 newDateUnfreeze = _freezeTime + now; 
            newDateUnfreeze = (pastDateUnfreeze > newDateUnfreeze ) ? pastDateUnfreeze : newDateUnfreeze;

            token.changeLock(_beneficiary,totalBloked,newDateUnfreeze);
        }
        token.mint(_beneficiary,_value);
    }


     
     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        uint256 ProfitProcent = getProfitPercent();

        var (bonus, dateUnfreeze) = getBonuses(weiAmount);
        
         
        uint256 totalProfit = ProfitProcent;
        totalProfit = (totalProfit < bonus) ? bonus : totalProfit;
        totalProfit = (totalProfit > profit.maxAllProfit) ? profit.maxAllProfit : totalProfit;
        
         
         
         
        
         
        uint256 tokens = weiAmount.mul(rate).mul(totalProfit + 100).div(100000);

         
        ethWeiRaised = ethWeiRaised.add(weiAmount);

        lokedMint(beneficiary, tokens, dateUnfreeze);

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

     
    function () public payable {
        buyTokens(msg.sender);
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

 
contract Ownable {
    address public owner;


     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner public{
        require(newOwner != address(0));
        owner = newOwner;
    }

}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool _paused = false;

    function paused() public constant returns(bool)
    {
        return _paused;
    }


     
    modifier whenNotPaused() {
        require(!paused());
        _;
    }

     
    function pause() onlyOwner public {
        require(!_paused);
        _paused = true;
        Pause();
    }

     
    function unpause() onlyOwner public {
        require(_paused);
        _paused = false;
        Unpause();
    }
}


 
contract MigrationAgent
{
    function migrateFrom(address _from, uint256 _value) public;
}

contract BlockedToken is Ownable {
    using SafeMath for uint256;

    struct locked {uint256 value; uint256 date;}

    mapping (address => locked) locks;

    function blikedUntil(address _owner) external constant returns (uint256) {
        if(now < locks[_owner].date)
        {
            return locks[_owner].date;
        }else{
            return 0;
        }
    }

    function valueBlocked(address _owner) public constant returns (uint256) {
        if(now < locks[_owner].date)
        {
            return locks[_owner].value;
        }else{
            return 0;
        }
    }

    function changeLock(address _owner, uint256 _value, uint256 _date) external onlyOwner {
        locks[_owner] = locked(_value,_date);
    }
}


 
 
contract TokenL is Pausable, BlockedToken {
    using SafeMath for uint256;

    string public constant name = "Crypt2Pos";
    string public constant symbol = "CRPOS";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    mapping (address => bool) public unpausedWallet;

    bool public mintingFinished = false;

    uint256 public totalMigrated;
    address public migrationAgent;
    
    address public freezingManager;
    mapping (address => bool) public freezingAgent;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    event Migrate(address indexed _from, address indexed _to, uint256 _value);

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function TokenL() public{
        owner = 0x0;
    }

    function setOwner() public{
        require(owner == 0x0);
        owner = msg.sender;
    }
    
    function setFreezingManager(address _newAddress) external {
        require(msg.sender == owner || msg.sender == freezingManager);
        freezingAgent[freezingManager] = false;
        freezingManager = _newAddress;
        freezingAgent[freezingManager] = true;
    }
    
    function changeFreezingAgent(address _agent, bool _right) external {
        require(msg.sender == freezingManager);
        freezingAgent[_agent] = _right;
    }
    
    function transferAndFreeze(address _to, uint256 _value, uint256 _when) external {
        require(freezingAgent[msg.sender]);
        if(_when > 0){
            locked storage _locked = locks[_to];
            _locked.value = valueBlocked(_to).add(_value);
            _locked.date = (_locked.date > _when)? _locked.date: _when;
        }
        transfer(_to,_value);
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }


     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!paused()||unpausedWallet[msg.sender]||unpausedWallet[_to]);
        uint256 available = balances[msg.sender].sub(valueBlocked(msg.sender));
        require(_value <= available);
        require (_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!paused()||unpausedWallet[msg.sender]||unpausedWallet[_to]);
        uint256 available = balances[_from].sub(valueBlocked(_from));
        require(_value <= available);

        var _allowance = allowed[_from][msg.sender];

         
         

        require (_value > 0);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

     
    function finishMinting() public onlyOwner returns (bool) {
    	mintingFinished = true;
        MintFinished();
        return true;
    }

     
     
    function paused() public constant returns(bool) {
        return super.paused();
    }

     
    function addUnpausedWallet(address _wallet) public onlyOwner {
        unpausedWallet[_wallet] = true;
    }

     
    function delUnpausedWallet(address _wallet) public onlyOwner {
        unpausedWallet[_wallet] = false;
    }

     
     
    function setMigrationAgent(address _migrationAgent) public onlyOwner {
        require(migrationAgent == 0x0);
        migrationAgent = _migrationAgent;
    }

    function migrateAll(address[] _holders) public onlyOwner {
        require(migrationAgent != 0x0);
        uint256 total = 0;
        uint256 value;
        for(uint i = 0; i < _holders.length; i++){
            value = balances[_holders[i]];
            if(value > 0){
                balances[_holders[i]] = 0;
                total = total.add(value);
                MigrationAgent(migrationAgent).migrateFrom(_holders[i], value);
                Migrate(_holders[i],migrationAgent,value);
            }
            totalSupply = totalSupply.sub(total);
            totalMigrated = totalMigrated.add(total);
        }
    }

    function migration(address _holder) internal {
        require(migrationAgent != 0x0);
        uint256 value = balances[_holder];
        require(value > 0);
        balances[_holder] = 0;
        totalSupply = totalSupply.sub(value);
        totalMigrated = totalMigrated.add(value);
        MigrationAgent(migrationAgent).migrateFrom(_holder, value);
        Migrate(_holder,migrationAgent,value);

    }

     
    function migrate() public
    {
        migration(msg.sender);
    }
}


 
 
 
 
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    event Deposited(address indexed beneficiary, uint256 weiAmount);

    function RefundVault() public {
        state = State.Active;
    }

     
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
        Deposited(investor,msg.value);
    }

     
    function close(address _wallet) onlyOwner public {
        require(state == State.Active);
        require(_wallet != 0x0);
        state = State.Closed;
        Closed();
        _wallet.transfer(this.balance);
    }

     
    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

     
     
     
     
    function refund(address investor) public {
        require(state == State.Refunding);
        require(deposited[investor] > 0);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
    }

     
     
    function del(address _wallet) external onlyOwner {
        selfdestruct(_wallet);
    }
}

contract DistributorRefundVault is RefundVault{
 
    address public taxCollector;
    uint256 public taxValue;
    
    function DistributorRefundVault(address _taxCollector, uint256 _taxValue) RefundVault() public{
        taxCollector = _taxCollector;
        taxValue = _taxValue;
    }
   
    function close(address _wallet) onlyOwner public {
    
        require(state == State.Active);
        require(_wallet != 0x0);
        
        state = State.Closed;
        Closed();
        uint256 allPay = this.balance;
        uint256 forTarget1;
        uint256 forTarget2;
        if(taxValue <= allPay){
           forTarget1 = taxValue;
           forTarget2 = allPay.sub(taxValue);
           taxValue = 0;
        }else {
            taxValue = taxValue.sub(allPay);
            forTarget1 = allPay;
            forTarget2 = 0;
        }
        if(forTarget1 != 0){
            taxCollector.transfer(forTarget1);
        }
       
        if(forTarget2 != 0){
            _wallet.transfer(forTarget2);
        }

    }

}


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 