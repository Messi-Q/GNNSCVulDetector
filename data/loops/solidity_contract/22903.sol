pragma solidity ^0.4.21;


 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

}





 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}





 
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;


   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}






 
contract SUCToken is StandardToken {
    string public constant NAME = "SUPPLYCHAIN";
    string public constant SYMBOL = "SUC";
    uint public constant DECIMALS = 18;

     
     
     
     
     
    uint8[10] public bonusPercentages = [
        20,
        10,
        0
    ];

    uint public constant NUM_OF_PHASE = 3;
  
     
     
    uint16 public constant BLOCKS_PER_PHASE = 29000;

     
     
     
     
     
     
    address public target;

     
     
    uint public firstblock = 0;

     
     
    bool public unsoldTokenIssued = false;

     
    uint256 public constant GOAL = 5000 ether;

     
    uint256 public constant HARD_CAP = 10000 ether;

     
    uint256 public constant BASE_RATE = 50000;

     
    uint public totalEthReceived = 0;

     
    uint public issueIndex = 0;

     

     
    event SaleStarted();

     
    event SaleEnded();

     
    event InvalidCaller(address caller);

     
     
    event InvalidState(bytes msg);

     
    event Issue(uint issueIndex, address addr, uint ethAmount, uint tokenAmount);

     
    event SaleSucceeded();

     
     
     
    event SaleFailed();

     

    modifier onlyOwner {
        if (target == msg.sender) {
            _;
        } else {
            InvalidCaller(msg.sender);
            throw;
        }
    }

    modifier beforeStart {
        if (!saleStarted()) {
            _;
        } else {
            InvalidState("Sale has not started yet");
            throw;
        }
    }

    modifier inProgress {
        if (saleStarted() && !saleEnded()) {
            _;
        } else {
            InvalidState("Sale is not in progress");
            throw;
        }
    }

    modifier afterEnd {
        if (saleEnded()) {
            _;
        } else {
            InvalidState("Sale is not ended yet");
            throw;
        }
    }

     
    function SUCToken(address _target) {
        target = _target;
        totalSupply = 10 ** 27;
        balances[target] = totalSupply;
    }

     

     
     
    function start(uint _firstblock) public onlyOwner beforeStart {
        if (_firstblock <= block.number) {
             
            throw;
        }

        firstblock = _firstblock;
        SaleStarted();
    }

     
    function close() public onlyOwner afterEnd {
        if (totalEthReceived < GOAL) {
            SaleFailed();
        } else {
            SaleSucceeded();
        }
    }

     
    function price() public constant returns (uint tokens) {
        return computeTokenAmount(1 ether);
    }

     
     
    function () payable {
        issueToken(msg.sender);
    }

     
     
    function issueToken(address recipient) payable inProgress {
         
        assert(msg.value >= 0.01 ether);

         
        assert(msg.value <= 10000 ether);

         
        uint ethReceived = totalEthReceived + msg.value;
        assert(ethReceived <= HARD_CAP);

        uint tokens = computeTokenAmount(msg.value);
        totalEthReceived = totalEthReceived.add(msg.value);
        
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[target] = balances[target].sub(tokens);

        Issue(
            issueIndex++,
            recipient,
            msg.value,
            tokens
        );

        if (!target.send(msg.value)) {
            throw;
        }
    }

     
  
     
     
     
    function computeTokenAmount(uint ethAmount) internal constant returns (uint tokens) {
        uint phase = (block.number - firstblock).div(BLOCKS_PER_PHASE);

         
        if (phase >= bonusPercentages.length) {
            phase = bonusPercentages.length - 1;
        }

        uint tokenBase = ethAmount.mul(BASE_RATE);
        uint tokenBonus = tokenBase.mul(bonusPercentages[phase]).div(100);

        tokens = tokenBase.add(tokenBonus);
    }

     
    function saleStarted() constant returns (bool) {
        return (firstblock > 0 && block.number >= firstblock);
    }

     
    function saleEnded() constant returns (bool) {
        return firstblock > 0 && (saleDue() || hardCapReached());
    }

     
    function saleDue() constant returns (bool) {
        return block.number >= firstblock + BLOCKS_PER_PHASE * NUM_OF_PHASE;
    }

     
    function hardCapReached() constant returns (bool) {
        return totalEthReceived >= HARD_CAP;
    }
}