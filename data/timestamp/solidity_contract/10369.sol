pragma solidity ^0.4.18;

 
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

contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}



contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


 
contract MuskToken is StandardToken {

    function () {
         
        throw;
    }

     

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  
    string public version = 'H1.0';        

 
 
 

 
 

    function MuskToken(
        ) {
        balances[msg.sender] = 1000000000000000000000000000;                
        totalSupply = 1000000000000000000000000000;                         
        name = "Musk Token";                                    
        decimals = 18;                             
        symbol = "MUSK";                                
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}

 
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

contract MuskTokenVault is Ownable {
    using SafeMath for uint256;

     
    address public teamReserveWallet = 0xBf7E6DC9317dF0e9Fde7847577154e6C5114370d;
    address public finalReserveWallet = 0xBf7E6DC9317dF0e9Fde7847577154e6C5114370d;

     
    uint256 public teamReserveAllocation = 240 * (10 ** 6) * (10 ** 18);
    uint256 public finalReserveAllocation = 10 * (10 ** 6) * (10 ** 18);

     
    uint256 public totalAllocation = 250 * (10 ** 6) * (10 ** 18);

    uint256 public teamTimeLock = 2 * 365 days;
    uint256 public teamVestingStages = 8;
    uint256 public finalReserveTimeLock = 2 * 365 days;

     
    mapping(address => uint256) public allocations;

       
    mapping(address => uint256) public timeLocks;

     
    mapping(address => uint256) public claimed;

     
    uint256 public lockedAt = 0;

    MuskToken public token;

     
    event Allocated(address wallet, uint256 value);

     
    event Distributed(address wallet, uint256 value);

     
    event Locked(uint256 lockTime);

     
    modifier onlyReserveWallets {
        require(allocations[msg.sender] > 0);
        _;
    }

     
    modifier onlyTeamReserve {
        require(msg.sender == teamReserveWallet);
        require(allocations[msg.sender] > 0);
        _;
    }

     
    modifier onlyTokenReserve {
        require(msg.sender == finalReserveWallet);
        require(allocations[msg.sender] > 0);
        _;
    }

     
    modifier notLocked {
        require(lockedAt == 0);
        _;
    }

    modifier locked {
        require(lockedAt > 0);
        _;
    }

     
    modifier notAllocated {
        require(allocations[teamReserveWallet] == 0);
        require(allocations[finalReserveWallet] == 0);
        _;
    }

    function MuskTokenVault(Token _token) public {

        owner = msg.sender;
        token = MuskToken(_token);
        
    }

    function allocate() public notLocked notAllocated onlyOwner {

         
        require(token.balanceOf(address(this)) == totalAllocation);
        
        allocations[teamReserveWallet] = teamReserveAllocation;
        allocations[finalReserveWallet] = finalReserveAllocation;

        Allocated(teamReserveWallet, teamReserveAllocation);
        Allocated(finalReserveWallet, finalReserveAllocation);

        lock();
    }

     
    function lock() internal notLocked onlyOwner {

        lockedAt = block.timestamp;

        timeLocks[teamReserveWallet] = lockedAt.add(teamTimeLock);
        timeLocks[finalReserveWallet] = lockedAt.add(finalReserveTimeLock);

        Locked(lockedAt);
    }

     
     
    function recoverFailedLock() external notLocked notAllocated onlyOwner {

         
        require(token.transfer(owner, token.balanceOf(address(this))));
    }

     
    function getTotalBalance() public view returns (uint256 tokensCurrentlyInVault) {

        return token.balanceOf(address(this));

    }

     
    function getLockedBalance() public view onlyReserveWallets returns (uint256 tokensLocked) {

        return allocations[msg.sender].sub(claimed[msg.sender]);

    }

     
    function claimTokenReserve() onlyTokenReserve locked public {

        address reserveWallet = msg.sender;

         
        require(block.timestamp > timeLocks[reserveWallet]);

         
        require(claimed[reserveWallet] == 0);

        uint256 amount = allocations[reserveWallet];

        claimed[reserveWallet] = amount;

        require(token.transfer(reserveWallet, amount));

        Distributed(reserveWallet, amount);
    }

     
    function claimTeamReserve() onlyTeamReserve locked public {

        uint256 vestingStage = teamVestingStage();

         
        uint256 totalUnlocked = vestingStage.mul(allocations[teamReserveWallet]).div(teamVestingStages);

        require(totalUnlocked <= allocations[teamReserveWallet]);

         
        require(claimed[teamReserveWallet] < totalUnlocked);

        uint256 payment = totalUnlocked.sub(claimed[teamReserveWallet]);

        claimed[teamReserveWallet] = totalUnlocked;

        require(token.transfer(teamReserveWallet, payment));

        Distributed(teamReserveWallet, payment);
    }

     
    function teamVestingStage() public view onlyTeamReserve returns(uint256){
        
         
        uint256 vestingMonths = teamTimeLock.div(teamVestingStages); 

        uint256 stage = (block.timestamp.sub(lockedAt)).div(vestingMonths);

         
        if(stage > teamVestingStages){
            stage = teamVestingStages;
        }

        return stage;

    }

     
    function canCollect() public view onlyReserveWallets returns(bool) {

        return block.timestamp > timeLocks[msg.sender] && claimed[msg.sender] == 0;

    }

}