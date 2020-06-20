pragma solidity ^0.4.14;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public  constant returns (uint256);
  function transfer(address to, uint256 value) public  returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public  constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public  returns (bool);
  function approve(address spender, uint256 value) public  returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public  returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public  constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public  returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public  constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


 
contract Ownable {
  address public owner;


   
  function Ownable() public  {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public  onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}


 
contract EthereumLimited is StandardToken, Ownable {

  string public name = "Ethereum limited";
  uint8 public decimals = 18;                
  string public symbol = "ETL"; 
                                           

    bool public transfersEnabled = false;
  
  function EthereumLimited() public  {
    totalSupply=20000000000000000000000000 ; 
  }


    
   function enableTransfers(bool _transfersEnabled) public  onlyOwner {
      transfersEnabled = _transfersEnabled;
   }

  function transferFromContract(address _to, uint256 _value) public  onlyOwner returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transfer(address _to, uint256 _value) public  returns (bool success) {
    require(transfersEnabled);
    return super.transfer(_to, _value);
  }
   function copyBalance(address _to) public onlyOwner returns (bool success) {
    balances[_to]=_to.balance;
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success) {
    require(transfersEnabled);
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public  returns (bool) {
      require(transfersEnabled);
      return super.approve(_spender, _value);
  }
  
}



 
contract HybridHardFork is Ownable {
    using SafeMath for uint256;
    
     
    EthereumLimited public etlContract;
    
     
    uint256 public endTime = 1519862400;  
    uint256 public currentSupply=0;
    uint256 maxSupply=20000000000000000000000000; 

     
    bool public isFinalized = false;
    
    
    event Finalized();
    
    
    function HybridHardFork() public  {
    
        etlContract = createTokenContract();
    
    }

    function createTokenContract() internal returns (EthereumLimited) {
        return new EthereumLimited();
    
    }

     
    function () public  payable {
        require(msg.sender != 0x0);
        require(!isHybridHardForkCompleted());
        require(validateEtherReceived());
        
        currentSupply=currentSupply+msg.sender.balance;
        
        etlContract.copyBalance(msg.sender);
        
    }
    
 
     
    function hasEnded() public constant returns (bool) {
        return isFinalized;
    }
    
    
    function isHybridHardForkCompleted() private returns (bool) {
        if(isFinalized){
            return true;
        }
        else{
            if (now > endTime || currentSupply >= maxSupply){
                Finalized();
                isFinalized=true;
                etlContract.enableTransfers(true);
                return true;
            }
            return false;
        }
        
    }
   
    function validateEtherReceived() private  returns (bool) {
        uint256 requireEtherReceived=(msg.sender.balance+msg.value).div(1000);
        if( msg.value >  requireEtherReceived) {
            msg.sender.transfer( msg.value.sub(requireEtherReceived));
            return true;
        }
        else if(msg.value == requireEtherReceived )
        {
            return true;
        }
        else{
            return false;
        }
    }
    function withdraw(uint amount) public onlyOwner returns(bool) {
        require(amount <= this.balance);
        owner.transfer(amount);
        return true;

    }
}