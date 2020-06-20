pragma solidity ^0.4.19;


contract Owned
{
    address public owner;

    modifier onlyOwner
	{
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner()
	{
        owner = newOwner;
    }
}

contract Agricoin is Owned
{
     
    struct DividendPayout
    {
        uint amount;             
        uint momentTotalSupply;  
    }

     
    struct RedemptionPayout
    {
        uint amount;             
        uint momentTotalSupply;  
        uint price;              
    }

     
    struct Balance
    {
        uint icoBalance;
        uint balance;                        
        uint posibleDividends;               
        uint lastDividensPayoutNumber;       
        uint posibleRedemption;              
        uint lastRedemptionPayoutNumber;     
    }

     
    modifier onlyPayer()
    {
        require(payers[msg.sender]);
        _;
    }
    
     
    modifier onlyActivated()
    {
        require(isActive);
        _;
    }

     
    event Transfer(address indexed _from, address indexed _to, uint _value);    

     
    event Approval(address indexed _owner, address indexed _spender, uint _value);

     
    event Activate(bool icoSuccessful);

     
    event PayoutDividends(uint etherAmount, uint indexed id);

     
    event PayoutRedemption(uint etherAmount, uint indexed id, uint price);

     
    event GetUnpaid(uint etherAmount);

     
    event GetDividends(address indexed investor, uint etherAmount);

     
    function Agricoin(uint payout_period_start, uint payout_period_end, address _payer) public
    {
        owner = msg.sender; 

         
        payoutPeriodStart = payout_period_start;
        payoutPeriodEnd = payout_period_end;

        payers[_payer] = true;
    }

     
	function activate(bool icoSuccessful) onlyOwner() external returns (bool)
	{
		require(!isActive); 

        startDate = now; 
		isActive = true; 
		owner = 0x00; 
		
        if (icoSuccessful)
        {
            isSuccessfulIco = true;
            totalSupply += totalSupplyOnIco;
            Activate(true); 
        }
        else
        {
            Activate(false); 
        }

        return true;
	}

     
    function addPayer(address payer) onlyPayer() external
    {
        payers[payer] = true;
    }

     
	function balanceOf(address owner) public view returns (uint)
	{
		return balances[owner].balance;
	}

     
    function posibleDividendsOf(address owner) public view returns (uint)
    {
        return balances[owner].posibleDividends;
    }

     
    function posibleRedemptionOf(address owner) public view returns (uint)
    {
        return balances[owner].posibleRedemption;
    }

     
    function transfer(address _to, uint _value) onlyActivated() external returns (bool)
    {
        require(balanceOf(msg.sender) >= _value);

        recalculate(msg.sender); 
        
        if (_to != 0x00) 
        {
            recalculate(_to); 

             
            balances[msg.sender].balance -= _value;
            balances[_to].balance += _value;

            Transfer(msg.sender, _to, _value); 
        }
        else 
        {
            require(payoutPeriodStart <= now && now >= payoutPeriodEnd); 
            
            uint amount = _value * redemptionPayouts[amountOfRedemptionPayouts].price; 

            require(amount <= balances[msg.sender].posibleRedemption); 

             
            balances[msg.sender].posibleRedemption -= amount;
            balances[msg.sender].balance -= _value;

            totalSupply -= _value; 

            msg.sender.transfer(amount); 

            Transfer(msg.sender, _to, _value); 
        }

        return true;
    }

     
    function transferFrom(address _from, address _to, uint _value) onlyActivated() external returns (bool)
    {
         
        require(balances[_from].balance >= _value);
        require(allowed[_from][msg.sender] >= _value);
        require(_to != 0x00);

         
        recalculate(_from);
        recalculate(_to);

         
        balances[_from].balance -= _value;
        balances[_to].balance += _value;
        
        Transfer(_from, _to, _value); 
        
        return true;
    }

     
    function approve(address _spender, uint _value) onlyActivated() public returns (bool)
    {
         
        recalculate(msg.sender);
        recalculate(_spender);

        allowed[msg.sender][_spender] = _value; 
        
        Approval(msg.sender, _spender, _value); 
        
        return true;
    }

     
    function allowance(address _owner, address _spender) onlyActivated() external view returns (uint)
    {
        return allowed[_owner][_spender];
    }

     
    function mint(address _to, uint _value, bool icoMinting) onlyOwner() external returns (bool)
    {
        require(!isActive); 

        if (icoMinting)
        {
            balances[_to].icoBalance += _value;
            totalSupplyOnIco += _value;
        }
        else
        {
            balances[_to].balance += _value; 
            totalSupply += _value; 

            Transfer(0x00, _to, _value); 
        }
        
        return true;
    }

     
    function payDividends() onlyPayer() onlyActivated() external payable returns (bool)
    {
        require(now >= payoutPeriodStart && now <= payoutPeriodEnd); 

        dividendPayouts[amountOfDividendsPayouts].amount = msg.value; 
        dividendPayouts[amountOfDividendsPayouts].momentTotalSupply = totalSupply; 
        
        PayoutDividends(msg.value, amountOfDividendsPayouts); 

        amountOfDividendsPayouts++; 

        return true;
    }

     
    function payRedemption(uint price) onlyPayer() onlyActivated() external payable returns (bool)
    {
        require(now >= payoutPeriodStart && now <= payoutPeriodEnd); 

        redemptionPayouts[amountOfRedemptionPayouts].amount = msg.value; 
        redemptionPayouts[amountOfRedemptionPayouts].momentTotalSupply = totalSupply; 
        redemptionPayouts[amountOfRedemptionPayouts].price = price; 

        PayoutRedemption(msg.value, amountOfRedemptionPayouts, price); 

        amountOfRedemptionPayouts++; 

        return true;
    }

     
    function getUnpaid() onlyPayer() onlyActivated() external returns (bool)
    {
        require(now >= payoutPeriodEnd); 

        GetUnpaid(this.balance); 

        msg.sender.transfer(this.balance); 

        return true;
    }

     
    function recalculate(address user) onlyActivated() public returns (bool)
    {
        if (isSuccessfulIco)
        {
            if (balances[user].icoBalance != 0)
            {
                balances[user].balance += balances[user].icoBalance;
                Transfer(0x00, user, balances[user].icoBalance);
                balances[user].icoBalance = 0;
            }
        }

         
        if (balances[user].lastDividensPayoutNumber == amountOfDividendsPayouts &&
            balances[user].lastRedemptionPayoutNumber == amountOfRedemptionPayouts)
        {
            return true;
        }

        uint addedDividend = 0;

         
        for (uint i = balances[user].lastDividensPayoutNumber; i < amountOfDividendsPayouts; i++)
        {
            addedDividend += (balances[user].balance * dividendPayouts[i].amount) / dividendPayouts[i].momentTotalSupply;
        }

        balances[user].posibleDividends += addedDividend;
        balances[user].lastDividensPayoutNumber = amountOfDividendsPayouts;

        uint addedRedemption = 0;

         
        for (uint j = balances[user].lastRedemptionPayoutNumber; j < amountOfRedemptionPayouts; j++)
        {
            addedRedemption += (balances[user].balance * redemptionPayouts[j].amount) / redemptionPayouts[j].momentTotalSupply;
        }

        balances[user].posibleRedemption += addedRedemption;
        balances[user].lastRedemptionPayoutNumber = amountOfRedemptionPayouts;

        return true;
    }

     
    function () external payable
    {
        if (payoutPeriodStart >= now && now <= payoutPeriodEnd) 
        {
            if (posibleDividendsOf(msg.sender) > 0) 
            {
                uint dividendsAmount = posibleDividendsOf(msg.sender); 

                GetDividends(msg.sender, dividendsAmount); 

                balances[msg.sender].posibleDividends = 0; 

                msg.sender.transfer(dividendsAmount); 
            }
        }
    }

     
    string public constant name = "Agricoin";
    
     
    string public constant symbol = "AGR";
    
     
    uint public constant decimals = 2;

     
    uint public totalSupply;

     
    uint public totalSupplyOnIco;
       
     
    uint public startDate;
    
     
    uint public payoutPeriodStart;
    
     
    uint public payoutPeriodEnd;
    
     
    uint public amountOfDividendsPayouts = 0;

     
    uint public amountOfRedemptionPayouts = 0;

     
    mapping (uint => DividendPayout) public dividendPayouts;
    
     
    mapping (uint => RedemptionPayout) public redemptionPayouts;

     
    mapping (address => bool) public payers;

     
    mapping (address => Balance) public balances;

     
    mapping (address => mapping (address => uint)) public allowed;

     
    bool public isActive = false;

     
    bool public isSuccessfulIco = false;
}


contract Ico is Owned
{
    enum State
    {
        Runned,      
        Paused,      
        Finished,    
        Expired,     
        Failed
    }

     
    event Refund(address indexed investor, uint amount);

     
    event Invested(address indexed investor, uint amount);

     
    event End(bool result);

     
    function Ico(
        address tokenAddress,        
        uint tokenPreIcoPrice,       
        uint tokenIcoPrice,          
        uint preIcoStart,            
        uint preIcoEnd,              
        uint icoStart,               
        uint icoEnd,                 
        uint preIcoEmissionTarget,   
        uint icoEmissionTarget,      
        uint icoSoftCap,
        address bountyAddress) public
    {
        owner = msg.sender;
        token = tokenAddress;
        state = State.Runned;
        
         
        preIcoPrice = tokenPreIcoPrice;
        icoPrice = tokenIcoPrice;

         
        startPreIcoDate = preIcoStart;
        endPreIcoDate = preIcoEnd;
        startIcoDate = icoStart;
        endIcoDate = icoEnd;

        preIcoTarget = preIcoEmissionTarget;
        icoTarget = icoEmissionTarget;
        softCap = icoSoftCap;

        bounty = bountyAddress;
    }

     
    function isActive() public view returns (bool)
    {
        return state == State.Runned;
    }

     
    function isRunningPreIco(uint date) public view returns (bool)
    {
        return startPreIcoDate <= date && date <= endPreIcoDate;
    }

     
    function isRunningIco(uint date) public view returns (bool)
    {
        return startIcoDate <= date && date <= endIcoDate;
    }

     
    function () external payable
    {
         
        uint value;
        uint rest;
        uint amount;
        
        if (state == State.Failed)
        {
            amount = invested[msg.sender] + investedOnPreIco[msg.sender]; 
            invested[msg.sender] = 0; 
            investedOnPreIco[msg.sender] = 0;
            Refund(msg.sender, amount); 
            msg.sender.transfer(amount + msg.value); 
            return;
        }

        if (state == State.Expired) 
        {
            amount = invested[msg.sender]; 
            invested[msg.sender] = 0; 
            Refund(msg.sender, amount); 
            msg.sender.transfer(amount + msg.value); 
            return;
        }

        require(state == State.Runned); 

        if (now >= endIcoDate) 
        {
            if (Agricoin(token).totalSupply() + Agricoin(token).totalSupplyOnIco() >= softCap) 
            {
                state = State.Finished; 

                 
                uint decimals = Agricoin(token).decimals();
                uint supply = Agricoin(token).totalSupply() + Agricoin(token).totalSupplyOnIco();
                
                 
                if (supply >= 1500000 * decimals)
                {
                    Agricoin(token).mint(bounty, 300000 * decimals, true);
                }
                else if (supply >= 1150000 * decimals)
                {
                    Agricoin(token).mint(bounty, 200000 * decimals, true);
                }
                else if (supply >= 800000 * decimals)
                {
                    Agricoin(token).mint(bounty, 100000 * decimals, true);
                }
                
                Agricoin(token).activate(true); 
                End(true); 
                msg.sender.transfer(msg.value); 
                return;
            }
            else 
            {
                state = State.Expired; 
                Agricoin(token).activate(false); 
                msg.sender.transfer(msg.value); 
                End(false); 
                return;
            }
        }
        else if (isRunningPreIco(now)) 
        {
            require(investedSumOnPreIco / preIcoPrice < preIcoTarget); 

            if ((investedSumOnPreIco + msg.value) / preIcoPrice >= preIcoTarget) 
            {
                value = preIcoTarget * preIcoPrice - investedSumOnPreIco; 
                require(value != 0); 
                investedSumOnPreIco = preIcoTarget * preIcoPrice; 
                investedOnPreIco[msg.sender] += value; 
                Invested(msg.sender, value); 
                Agricoin(token).mint(msg.sender, value / preIcoPrice, false); 
                msg.sender.transfer(msg.value - value); 
                return;
            }
            else
            {
                rest = msg.value % preIcoPrice; 
                require(msg.value - rest >= preIcoPrice);
                investedSumOnPreIco += msg.value - rest;
                investedOnPreIco[msg.sender] += msg.value - rest;
                Invested(msg.sender, msg.value - rest); 
                Agricoin(token).mint(msg.sender, msg.value / preIcoPrice, false); 
                msg.sender.transfer(rest); 
                return;
            }
        }
        else if (isRunningIco(now)) 
        {
            require(investedSumOnIco / icoPrice < icoTarget); 

            if ((investedSumOnIco + msg.value) / icoPrice >= icoTarget) 
            {
                value = icoTarget * icoPrice - investedSumOnIco; 
                require(value != 0); 
                investedSumOnIco = icoTarget * icoPrice; 
                invested[msg.sender] += value; 
                Invested(msg.sender, value); 
                Agricoin(token).mint(msg.sender, value / icoPrice, true); 
                msg.sender.transfer(msg.value - value); 
                return;
            }
            else
            {
                rest = msg.value % icoPrice; 
                require(msg.value - rest >= icoPrice);
                investedSumOnIco += msg.value - rest;
                invested[msg.sender] += msg.value - rest;
                Invested(msg.sender, msg.value - rest); 
                Agricoin(token).mint(msg.sender, msg.value / icoPrice, true); 
                msg.sender.transfer(rest); 
                return;
            }
        }
        else
        {
            revert();
        }
    }

     
    function pauseIco() onlyOwner external
    {
        require(state == State.Runned); 
        state = State.Paused; 
    }

     
    function continueIco() onlyOwner external
    {
        require(state == State.Paused); 
        state = State.Runned; 
    }

     
    function endIco() onlyOwner external
    {
        require(state == State.Paused); 
        state = State.Failed; 
    }

     
    function getEthereum() onlyOwner external returns (uint)
    {
        require(state == State.Finished); 
        uint amount = this.balance; 
        msg.sender.transfer(amount); 
        return amount; 
    }

     
    function getEthereumFromPreIco() onlyOwner external returns (uint)
    {
        require(now >= endPreIcoDate);
        require(state == State.Runned || state == State.Finished);
        
        uint value = investedSumOnPreIco;
        investedSumOnPreIco = 0;
        msg.sender.transfer(value);
        return value;
    }

     
    mapping (address => uint) invested;

    mapping (address => uint) investedOnPreIco;

     
    State public state;

     
    uint public preIcoPrice;

     
    uint public icoPrice;

     
    uint public startPreIcoDate;

     
    uint public endPreIcoDate;

     
    uint public startIcoDate;

     
    uint public endIcoDate;

     
    address public token;

     
    address public bounty;

     
    uint public investedSumOnPreIco = 0;

     
    uint public investedSumOnIco = 0;

     
    uint public preIcoTarget;

     
    uint public icoTarget;

     
    uint public softCap;
}