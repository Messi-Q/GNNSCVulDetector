contract TokenInterface {
    uint totalSupply;
    function balanceOf(address owner) constant returns (uint256 balance);
    
    function transfer(address to, uint256 value) returns (bool success);

    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract StandardToken is TokenInterface {

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;
    
    function StandardToken(){
    }
    function transfer(address to, uint256 value) returns (bool success) {
        
        
        if (balances[msg.sender] >= value && value > 0) {

             
            balances[msg.sender] -= value;
            balances[to]         += value;
            
             
            Transfer(msg.sender, to, value);
            return true;
        } else {
            
            return false; 
        }
    }
    
    function transferFrom(address from, address to, uint256 value) returns (bool success) {
    
        if ( balances[from] >= value && 
             allowed[from][msg.sender] >= value && 
             value > 0) {
                                          
    
             
            balances[from] -= value;    
            balances[to] =+ value;            
            

             
             
            allowed[from][msg.sender] -= value;
            
             
            Transfer(from, to, value);
            return true;
        } else { 
            
            return false; 
        }
    }
    function balanceOf(address owner) constant returns (uint256 balance) {
        return balances[owner];
    }

    function approve(address spender, uint256 value) returns (bool success) {
        
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        
        return true;
    }

    function allowance(address owner, address spender) constant returns (uint256 remaining) {
      return allowed[owner][spender];
    }

}
contract HackerGold is StandardToken {

    string public name = "HackerGold";

    uint8  public decimals = 3;
    string public symbol = "HKG";
    
    uint BASE_PRICE = 200;
    uint MID_PRICE = 150;
    uint FIN_PRICE = 100;
    uint SAFETY_LIMIT = 4000000 ether;
    uint DECIMAL_ZEROS = 1000;
    
    uint totalValue;
    
    address wallet;

    struct milestones_struct {
      uint p1;
      uint p2; 
      uint p3;
      uint p4;
      uint p5;
      uint p6;
    }
     
    milestones_struct milestones;
    
    function HackerGold(address multisig) {
        
        wallet = multisig;

         
        milestones = milestones_struct(
        
          1476799200,   
          1478181600,   
          1479391200,   
                        
          1480600800,   
          1481810400,   
          1482415200    
        );
                
    }
    
    
     
    function () payable {
        createHKG(msg.sender);
    }
    
     
    function createHKG(address holder) payable {
        
        if (now < milestones.p1) throw;
        if (now >= milestones.p6) throw;
        if (msg.value == 0) throw;
    
         
        if (getTotalValue() + msg.value > SAFETY_LIMIT) throw; 
    
        uint tokens = msg.value * getPrice() * DECIMAL_ZEROS / 1 ether;

        totalSupply += tokens;
        balances[holder] += tokens;
        totalValue += msg.value;
        
        if (!wallet.send(msg.value)) throw;
    }
    
     
    function getPrice() constant returns (uint result) {
        
        if (now < milestones.p1) return 0;
        
        if (now >= milestones.p1 && now < milestones.p2) {
        
            return BASE_PRICE;
        }
        
        if (now >= milestones.p2 && now < milestones.p3) {
            
            uint days_in = 1 + (now - milestones.p2) / 1 days; 
            return BASE_PRICE - days_in * 25 / 7;   
        }

        if (now >= milestones.p3 && now < milestones.p4) {
        
            return MID_PRICE;
        }
        
        if (now >= milestones.p4 && now < milestones.p5) {
            
            days_in = 1 + (now - milestones.p4) / 1 days; 
            return MID_PRICE - days_in * 25 / 7;   
        }

        if (now >= milestones.p5 && now < milestones.p6) {
        
            return FIN_PRICE;
        }
        
        if (now >= milestones.p6){

            return 0;
        }

     }
    
     
    function getTotalSupply() constant returns (uint result) {
        return totalSupply;
    } 

     
    function getNow() constant returns (uint result) {
        return now;
    }

     
    function getTotalValue() constant returns (uint result) {
        return totalValue;  
    }
}