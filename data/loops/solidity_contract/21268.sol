pragma solidity ^0.4.21;


contract OrganicumOrders {
    struct order {
    uint256 balance;
    uint256 tokens;
    }

    mapping (address => order) public orders;
    address[] public holders;

    uint256 public supplyTokens;
    uint256 public supplyTokensSaved;
    uint256 public tokenDecimal = 18;

    uint256 minAmount = 1000;  
    uint256 softCap = 5000000;  
    uint256 supplyInvestmen = 0;

    uint16 fee = 500;  

    uint256 public etherCost = 60000;  

    address public owner;

    uint256 public startDate = 1521849600;  
    uint256 public firstPeriod = 1522540800;  
    uint256 public secondPeriod = 1525132800;  
    uint256 public thirdPeriod = 1527811200;  
    uint256 public endDate = 1530403200;  

    function OrganicumOrders()
    {
        owner = msg.sender;
    }

    modifier isOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function changeOwner(address new_owner) isOwner
    {
        assert(new_owner != address(0x0));
        assert(new_owner != address(this));
        owner = new_owner;
    }

    function changeEtherCost(uint256 new_cost) isOwner external
    {
        assert(new_cost > 0);
        etherCost = new_cost*100;
    }

    function getPrice() constant returns(uint256)
    {
        if(now < firstPeriod)
        {
            return 95;  
        }
        else if(now < secondPeriod)
        {
            return 100;  
        }
        else if(now < thirdPeriod)
        {
            return 110;  
        }
        else
        {
            return 120;  
        }
    }

    function () payable
    {
        assert(now >= startDate && now < endDate);
        assert((msg.value * etherCost)/10**18 >= minAmount);

        if(orders[msg.sender].balance == 0 && orders[msg.sender].tokens == 0)
        {
            holders.push(msg.sender);
        }

        uint256 countTokens = (msg.value * etherCost) / getPrice();
        orders[msg.sender].balance += msg.value;
        orders[msg.sender].tokens += countTokens;

        supplyTokens += countTokens;
        supplyTokensSaved += countTokens;
        supplyInvestmen += msg.value;
    }

    function orderFor(address to) payable
    {
        assert(now >= startDate && now < endDate);
        assert((msg.value * etherCost)/10**18 >= minAmount);

        if(orders[to].balance == 0 && orders[to].tokens == 0)
        {
            holders.push(to);
            if (to.balance == 0)
            {
                to.transfer(0.001 ether);
            }
        }

        uint256 countTokens = ((msg.value - 0.001 ether) * etherCost) / getPrice();
        orders[to].balance += msg.value;
        orders[to].tokens += countTokens;

        supplyTokens += countTokens;
        supplyTokensSaved += countTokens;
        supplyInvestmen += msg.value;
    }

    mapping (address => bool) public voter;
    uint256 public sumVote = 0;
    uint256 public durationVoting = 24 hours;

    function vote()
    {
        assert(!voter[msg.sender]);
        assert(now >= endDate && now < endDate + durationVoting);
        assert((supplyInvestmen * etherCost)/10**18 >= softCap);
        assert(orders[msg.sender].tokens > 0);

        voter[msg.sender] = true;
        sumVote += orders[msg.sender].tokens;
    }

    function refund(address holder)
    {
        assert(orders[holder].balance > 0);

        uint256 etherToSend = 0;
        if ((supplyInvestmen * etherCost)/10**18 >= softCap)
        {
            assert(sumVote > supplyTokensSaved / 2);  
            etherToSend = orders[holder].balance * 95 / 100;
        }
        else
        {
            etherToSend = orders[holder].balance;
        }
        assert(etherToSend > 0);

        if (etherToSend > this.balance) etherToSend = this.balance;

        holder.transfer(etherToSend);

        supplyTokens -= orders[holder].tokens;
        orders[holder].balance = 0;
        orders[holder].tokens = 0;
    }

    function takeInvest() isOwner
    {
        assert(now >= endDate + durationVoting);
        assert(this.balance > 0);

        if(sumVote > supplyTokensSaved / 2)
        {
            assert(supplyTokens == 0);
        }

        owner.transfer(this.balance);
    }
}