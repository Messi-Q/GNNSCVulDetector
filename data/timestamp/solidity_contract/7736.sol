pragma solidity ^0.4.21;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract CTCVesting is Ownable {
  using SafeMath for uint256;

  address public teamWallet;
  address public earlyWallet;
  address public institutionWallet;
  
  uint256 public teamTimeLock = 1000 days;
  uint256 public earlyTimeLock = 5 * 30 days;
  uint256 public institutionTimeLock = 50 * 30 days;
  
   
  uint256 public teamAllocation = 15 * (10 ** 7) * (10 ** 18);
  uint256 public earlyAllocation = 5 * (10 ** 7) * (10 ** 18);
  uint256 public institutionAllocation = 15 * (10 ** 7) * (10 ** 18);
  
  uint256 public totalAllocation = 35 * (10 ** 7) * (10 ** 18);
  
  uint256 public teamStageSetting = 34;
  uint256 public earlyStageSetting = 5;
  uint256 public institutionStageSetting = 50;
  ERC20Basic public token;
   
  uint256 public start;
   
  uint256 public lockStartTime; 
    
    mapping(address => uint256) public allocations;
    
    mapping(address => uint256) public stageSettings;
    
    mapping(address => uint256) public timeLockDurations;

     
    mapping(address => uint256) public releasedAmounts;
    
    modifier onlyReserveWallets {
        require(allocations[msg.sender] > 0);
        _;
    }
    function CTCVesting(ERC20Basic _token,
                          address _teamWallet,
                          address _earlyWallet,
                          address _institutionWallet,
                          uint256 _start,
                          uint256 _lockTime)public{
        require(_start > 0);
        require(_lockTime > 0);
        require(_start.add(_lockTime) > 0);
        require(_teamWallet != address(0));
        require(_earlyWallet != address(0));
        require(_institutionWallet != address(0));
        
        token = _token;
        teamWallet = _teamWallet;
        earlyWallet = _earlyWallet;
        institutionWallet = _institutionWallet;
        start = _start;
        lockStartTime = start.add(_lockTime);
    }
    
    function allocateToken() onlyOwner public{
        require(block.timestamp > lockStartTime);
         
        require(allocations[teamWallet] == 0);
        require(token.balanceOf(address(this)) == totalAllocation);
        
        allocations[teamWallet] = teamAllocation;
        allocations[earlyWallet] = earlyAllocation;
        allocations[institutionWallet] = institutionAllocation;
        
        stageSettings[teamWallet] = teamStageSetting;
        stageSettings[earlyWallet] = earlyStageSetting;
        stageSettings[institutionWallet] = institutionStageSetting;
        
        timeLockDurations[teamWallet] = teamTimeLock;
        timeLockDurations[earlyWallet] = earlyTimeLock;
        timeLockDurations[institutionWallet] = institutionTimeLock;
    }
    function releaseToken() onlyReserveWallets public{
        uint256 totalUnlocked = unlockAmount();
        require(totalUnlocked <= allocations[msg.sender]);
        require(releasedAmounts[msg.sender] < totalUnlocked);
        uint256 payment = totalUnlocked.sub(releasedAmounts[msg.sender]);
        
        releasedAmounts[msg.sender] = totalUnlocked;
        require(token.transfer(teamWallet, payment));
    }
    function unlockAmount() public view onlyReserveWallets returns(uint256){
        uint256 stage = vestStage();
        uint256 totalUnlocked = stage.mul(allocations[msg.sender]).div(stageSettings[msg.sender]);
        return totalUnlocked;
    }
    
    function vestStage() public view onlyReserveWallets returns(uint256){
        uint256 vestingMonths = timeLockDurations[msg.sender].div(stageSettings[msg.sender]);
        uint256 stage = (block.timestamp.sub(lockStartTime)).div(vestingMonths);
        
        if(stage > stageSettings[msg.sender]){
            stage = stageSettings[msg.sender];
        }
        return stage;
    }
}