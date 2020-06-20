 
 
 
 
 

 
pragma solidity ^0.4.10;

 
contract Henfruit {
     

     
    string public constant name = "Henfruit";
     
    string public constant symbol = "EGG";
     
    uint256 public totalSupply = 20736;
     
    uint8 public constant decimals = 0;


     
    uint256 public numBrews;
    uint256 public ETH_Rate = 13; 
    uint256 public ETH_Rate_Factor = 10000; 
    uint256 public WeiinEth = 1000000000000000000; 

     
    address public owner;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function Henfruit() public {
        owner = msg.sender;
        balances[this] += totalSupply - 20;
         
        balances[0x943291649C1e162476D840Bea7f471ED788dfDa6] += 20;  
    }

    

                                                                              
                                                                            

    function () public payable {
         
        numBrews = div(div(msg.value,ETH_Rate)*ETH_Rate_Factor,WeiinEth);
        require(numBrews > 0 && balances[this] >= numBrews);
        balances[msg.sender] += numBrews;
        balances[this] -= numBrews;
        owner.transfer(msg.value);
    }



     


    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
  
    function div(uint256 a, uint256 b) public pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }




}