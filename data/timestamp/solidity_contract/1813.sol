pragma solidity ^0.4.18;

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function availableSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
  uint256 availableSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function availableSupply() public view returns (uint256) {
    return availableSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 
contract Token is MintableToken {


  function Token() public {
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    return super.mint(_to, _amount);
  }

}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

contract EscrowContract is BasicToken {
    address public creator_;
    address public beneficiary_;
    uint public date_;
    address public token_;

    function EscrowContract (address creator,address beneficiary,uint date, address token) {
        creator_ = creator;
        beneficiary_ = beneficiary;
        date_ = date;
        token_ = token;
    }

    function executeBeneficiary(uint amount_) public onlyBeneficiary onlyMatureEscrow {
        ERC20(token_).transfer(beneficiary_,amount_);
    }

    function executeCreator(uint amount_) public onlyBeneficiary onlyMatureEscrow {
        ERC20(token_).transfer(creator_,amount_);
    }

    modifier onlyBeneficiary() {
        require (msg.sender == beneficiary_);
        _;
    }

    modifier onlyMatureEscrow() {
        require (date_ < block.timestamp);
        _;
    }

}

contract Bittwatt is Token,Claimable, PausableToken {

    string public constant name = "Bittwatt";
    string public constant symbol = "BWT";
    uint8 public constant decimals = 18;

    address public _tokenAllocator;

    function Bittwatt() public Token() {  
        pause();
    }

    function enableTransfers() public onlyOwner {
        unpause();
    }

    function disableTransfers() public onlyOwner {
        pause();
    }

    function setTokenAllocator(address _tokenAllocator) public onlyOwner {
        _tokenAllocator = _tokenAllocator;
    }

    function allocateTokens(address _beneficiary, uint _amount) public onlyOnwerOrTokenAllocator {
        balances[_beneficiary] = _amount;
    }

    function allocateBulkTokens(address[] _destinations, uint[] _amounts) public onlyOnwerOrTokenAllocator {
        uint256 addressCount = _destinations.length;
        for (uint256 i = 0; i < addressCount; i++) {
            address currentAddress = _destinations[i];
            uint256 balance = _amounts[i];
            balances[currentAddress] = balance;
            Transfer(0x0000000000000000000000000000000000000000, currentAddress, balance);
        }
    }

    function getStatus() public view returns (uint,uint, bool,address) {
        return(totalSupply_,availableSupply_, paused, owner);
    }

    function setTotalSupply(uint totalSupply) onlyOwner {
        totalSupply_ = totalSupply;
    }

    function setAvailableSupply(uint availableSupply) onlyOwner {
        availableSupply_ = availableSupply;
    }

    address[] public escrowContracts;
    function createEscrow(address _beneficiary, uint _date, address _tokenAddress) public {
        address escrowContract = new EscrowContract(msg.sender, _beneficiary, _date, _tokenAddress);
        escrowContracts.push(escrowContract);
    }

    function createDate(uint _days, uint _hours, uint _minutes, uint _seconds) public view returns (uint) {
        uint currentTimestamp = block.timestamp;
        currentTimestamp += _seconds;
        currentTimestamp += 60 * _minutes;
        currentTimestamp += 3600 * _hours;
        currentTimestamp += 86400 * _days;
        return currentTimestamp;
    }

    modifier onlyOnwerOrTokenAllocator() {
        require (msg.sender == owner || msg.sender == _tokenAllocator);
        _;
    }

}