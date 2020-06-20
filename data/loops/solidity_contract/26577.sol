pragma solidity ^0.4.19;
 

contract OpenAddressLottery{
    struct SeedComponents{
        uint component1;
        uint component2;
        uint component3;
        uint component4;
    }
    
    address owner;  
    uint private secretSeed;  
    uint private lastReseed;  
    uint LuckyNumber = 7;  
        
    mapping (address => bool) winner;  
    
    function OpenAddressLottery() {
        owner = msg.sender;
        reseed(SeedComponents((uint)(block.coinbase), block.difficulty, block.gaslimit, block.timestamp));  
    }
    
    function participate() payable {
         
        require(winner[msg.sender] == false);
        
        if(luckyNumberOfAddress(msg.sender) == LuckyNumber){  
            winner[msg.sender] = true;  
            
            uint win=msg.value*7;  
            
            if(win>this.balance)  
                win=this.balance;  
            msg.sender.transfer(win);
        }
        
        if(block.number-lastReseed>1000)  
            reseed(SeedComponents((uint)(block.coinbase), block.difficulty, block.gaslimit, block.timestamp));  
    }
    
    function luckyNumberOfAddress(address addr) constant returns(uint n){
         
        n = uint(keccak256(uint(addr), secretSeed)[0]) % 8;
    }
    
    function reseed(SeedComponents components) internal {
        secretSeed = uint256(keccak256(
            components.component1,
            components.component2,
            components.component3,
            components.component4
        ));  
        lastReseed = block.number;
    }
    
    function kill() {
        require(msg.sender==owner);
        
        selfdestruct(msg.sender);
    }
    
    function forceReseed() {  
        require(msg.sender==owner);
        
        SeedComponents s;
        s.component1 = uint(msg.sender);
        s.component2 = uint256(block.blockhash(block.number - 1));
        s.component3 = block.difficulty*(uint)(block.coinbase);
        s.component4 = tx.gasprice * 7;
        
        reseed(s);  
    }
    
    function () payable {  
        if(msg.value>=0.1 ether && msg.sender!=owner)  
            participate();
    }

}