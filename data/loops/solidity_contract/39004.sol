pragma solidity ^0.4.10;

 
 

 
contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
 
contract owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
 
contract halting is owned {
    bool public running = true;

    function start() onlyOwner {
        running = true;
    }

    function stop() onlyOwner {
        running = false;
    }

    function destruct() onlyOwner {
        selfdestruct(owner);
    }

    modifier halting {
        assert(running);
        _;
    }
}

 
 
contract TokenVault is owned, halting {

    address public asset;     
    uint public sellPrice;    
    uint public units;        

    event MakerWithdrewAsset(uint tokens);
    event MakerWithdrewEther(uint ethers);
    event SoldTokens(uint tokens);

     
    function TokenVault (
        address _asset,
        uint _sellPrice,
        uint _units
    ) {
        asset       = _asset;
        sellPrice   = _sellPrice;
        units       = _units;

        require(asset != 0);
        require(sellPrice > 0);
        require(units > 0);
    }

     
    function makerWithdrawAsset(uint tokens) onlyOwner returns (bool ok) {
        MakerWithdrewAsset(tokens);
        return ERC20(asset).transfer(owner, tokens);
    }

     
    function makerWithdrawEther() onlyOwner {
        MakerWithdrewEther(this.balance);
        return owner.transfer(this.balance);
    }

     
    function getAssetBalance() constant returns (uint) {
        return ERC20(asset).balanceOf(address(this));
    }

    function min(uint a, uint b) private returns (uint) {
        return a < b ? a : b;
    }

     
    function takerBuyAsset() payable halting {

         
        require(msg.value >= sellPrice);

        uint order    = msg.value / sellPrice;
        uint can_sell = getAssetBalance() / units;
         
        uint256 change = 0;
        if (msg.value > (can_sell * sellPrice)) {
            change  = msg.value - (can_sell * sellPrice);
            order = can_sell;
        }
        if (change > 0) {
            if (!msg.sender.send(change)) throw;
        }
        if (order > 0) {
            if (!ERC20(asset).transfer(msg.sender, order * units)) throw;
        }
        SoldTokens(order);

    }

     
    function () payable {
        if (msg.sender == owner) {
             
            return;
        }
        else {
             
            takerBuyAsset();
        }
    }
}