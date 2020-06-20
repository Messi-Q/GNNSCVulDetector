pragma solidity ^0.4.18;

 
 
 
 
 

contract ERC20Interface {
    function totalSupply() public constant returns (uint256 _totalSupply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BCV is ERC20Interface {
    uint256 public constant decimals = 8;

    string public constant symbol = "BCV";
    string public constant name = "BitCapitalVendorToken";

    uint256 public _totalSupply = 120000000000000000;  

     
    address public owner;

     
    mapping(address => uint256) private balances;

     
    mapping(address => mapping (address => uint256)) private allowed;

     
    mapping(address => bool) private approvedInvestorList;

     
    mapping(address => uint256) private deposit;


     
    uint256 public totalTokenSold = 0;


     
    modifier onlyPayloadSize(uint size) {
      if(msg.data.length < size + 4) {
        revert();
      }
      _;
    }



     
    function BCV()
        public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

     
     
    function totalSupply()
        public
        constant
        returns (uint256) {
        return _totalSupply;
    }

     
     
     
    function balanceOf(address _addr)
        public
        constant
        returns (uint256) {
        return balances[_addr];
    }

     
     
    function isApprovedInvestor(address _addr)
        public
        constant
        returns (bool) {
        return approvedInvestorList[_addr];
    }

     
     
     
    function getDeposit(address _addr)
        public
        constant
        returns(uint256){
        return deposit[_addr];
    }


     
     
     
     
    function transfer(address _to, uint256 _amount)
        public

        returns (bool) {
         
         
         
        if ( (balances[msg.sender] >= _amount) &&
             (_amount >= 0) &&
             (balances[_to] + _amount > balances[_to]) ) {

            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    )
    public

    returns (bool success) {
        if (balances[_from] >= _amount && _amount > 0 && allowed[_from][msg.sender] >= _amount) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
    function approve(address _spender, uint256 _amount)
        public

        returns (bool success) {
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function () public payable{
        revert();
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

contract BCVTokenVault is Ownable {
    using SafeMath for uint256;

     
    address public teamReserveWallet = 0x7e5C65b899Fb7Cd0c959e5534489B454B7c6c3dF;
     
    address public lifeReserveWallet = 0xaed0363f76e4b906ef818b0f3199c580b5b01a43;
     
    address public finanReserveWallet = 0xd60A1D84835006499d5E6376Eb7CB9725643E25F;
     
    address public econReserveWallet = 0x0C6e75e481cC6Ba8e32d6eF742768fc2273b1Bf0;
     
    address public developReserveWallet = 0x11aC32f89e874488890E5444723A644248609C0b;

     
    uint256 public teamReserveAllocation = 2.4 * (10 ** 8) * (10 ** 8);
    uint256 public lifeReserveAllocation = 1.2 * (10 ** 8) * (10 ** 8);
    uint256 public finanReserveAllocation = 1.2 * (10 ** 8) * (10 ** 8);
    uint256 public econReserveAllocation = 1.2 * (10 ** 8) * (10 ** 8);
    uint256 public developReserveAllocation = 1.2 * (10 ** 8) * (10 ** 8);

     
    uint256 public totalAllocation = 7.2 * (10 ** 8) * (10 ** 8);

    uint256 public teamReserveTimeLock = 1552060800;  
    uint256 public lifeReserveTimeLock = 1527782400;   
    uint256 public finanReserveTimeLock = 1527782400;   
    uint256 public econReserveTimeLock = 1527782400;   
    uint256 public developReserveTimeLock = 1538236800;   

    uint256 public teamVestingStages = 34;    
    uint256 public lifeVestingStages = 5;   
    uint256 public finanVestingStages = 5;   
    uint256 public econVestingStages = 240;   

    mapping(address => uint256) public allocations;
    mapping(address => uint256) public timeLocks;
    mapping(address => uint256) public claimed;
    uint256 public lockedAt = 0;

    BCV public token;

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
        require(allocations[msg.sender] > claimed[msg.sender]);
        _;
    }

     
    modifier onlyTokenReserveLife {
        require(msg.sender == lifeReserveWallet);
        require(allocations[msg.sender] > 0);
        require(allocations[msg.sender] > claimed[msg.sender]);
        _;
    }

     
    modifier onlyTokenReserveFinance {
        require(msg.sender == finanReserveWallet);
        require(allocations[msg.sender] > 0);
        require(allocations[msg.sender] > claimed[msg.sender]);
        _;
    }

     
    modifier onlyTokenReserveEcon {
        require(msg.sender == econReserveWallet);
        require(allocations[msg.sender] > 0);
        require(allocations[msg.sender] > claimed[msg.sender]);
        _;
    }

     
    modifier onlyTokenReserveDevelop {
        require(msg.sender == developReserveWallet);
        require(allocations[msg.sender] > 0);
        require(allocations[msg.sender] > claimed[msg.sender]);
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
        require(allocations[lifeReserveWallet] == 0);
        require(allocations[finanReserveWallet] == 0);
        require(allocations[econReserveWallet] == 0);
        require(allocations[developReserveWallet] == 0);
        _;
    }

    function BCVTokenVault(ERC20Interface _token) public {
        owner = msg.sender;
        token = BCV(_token);
    }

    function allocate() public notLocked notAllocated onlyOwner {

         
        require(token.balanceOf(address(this)) == totalAllocation);

        allocations[teamReserveWallet] = teamReserveAllocation;
        allocations[lifeReserveWallet] = lifeReserveAllocation;
        allocations[finanReserveWallet] = finanReserveAllocation;
        allocations[econReserveWallet] = econReserveAllocation;
        allocations[developReserveWallet] = developReserveAllocation;

        Allocated(teamReserveWallet, teamReserveAllocation);
        Allocated(lifeReserveWallet, lifeReserveAllocation);
        Allocated(finanReserveWallet, finanReserveAllocation);
        Allocated(econReserveWallet, econReserveAllocation);
        Allocated(developReserveWallet, developReserveAllocation);

        lock();
    }

     
    function lock() internal notLocked onlyOwner {

        lockedAt = block.timestamp;

        timeLocks[teamReserveWallet] = teamReserveTimeLock;
        timeLocks[lifeReserveWallet] = lifeReserveTimeLock;
        timeLocks[finanReserveWallet] = finanReserveTimeLock;
        timeLocks[econReserveWallet] = econReserveTimeLock;
        timeLocks[developReserveWallet] = developReserveTimeLock;

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


     
    function claimTeamReserve() onlyTeamReserve locked public {

        address reserveWallet = msg.sender;
         
        require(block.timestamp > timeLocks[reserveWallet]);

        uint256 vestingStage = teamVestingStage();

         
        uint256 totalUnlocked = vestingStage.mul(7.2 * (10 ** 6) * (10 ** 8));

         
        if (vestingStage == 34) {
          totalUnlocked = allocations[teamReserveWallet];
        }

         
        require(totalUnlocked <= allocations[teamReserveWallet]);

         
        require(claimed[teamReserveWallet] < totalUnlocked);

         
        uint256 payment = totalUnlocked.sub(claimed[teamReserveWallet]);

         
        claimed[teamReserveWallet] = totalUnlocked;

         
        require(token.transfer(teamReserveWallet, payment));

        Distributed(teamReserveWallet, payment);
    }

     
    function teamVestingStage() public view onlyTeamReserve returns(uint256) {

        uint256 nowTime = block.timestamp;
         
        uint256 stage = (nowTime.sub(teamReserveTimeLock)).div(2592000);

         
        if(stage > teamVestingStages) {
            stage = teamVestingStages;
        }
        return stage;

    }

     
    function claimTokenReserveLife() onlyTokenReserveLife locked public {

        address reserveWallet = msg.sender;

         
        require(block.timestamp > timeLocks[reserveWallet]);

         
        uint256 vestingStage = lifeVestingStage();

         
        uint256 totalUnlocked = vestingStage.mul(2.4 * (10 ** 7) * (10 ** 8));

         
        require(totalUnlocked <= allocations[lifeReserveWallet]);

         
        require(claimed[lifeReserveWallet] < totalUnlocked);

         
        uint256 payment = totalUnlocked.sub(claimed[lifeReserveWallet]);

         
        claimed[lifeReserveWallet] = totalUnlocked;

         
        require(token.transfer(reserveWallet, payment));

        Distributed(reserveWallet, payment);
    }

     
    function lifeVestingStage() public view onlyTokenReserveLife returns(uint256) {

        uint256 nowTime = block.timestamp;
         
        uint256 stage = (nowTime.sub(lifeReserveTimeLock)).div(2592000);

         
        if(stage > lifeVestingStages) {
            stage = lifeVestingStages;
        }

        return stage;
    }

     
    function claimTokenReserveFinan() onlyTokenReserveFinance locked public {

        address reserveWallet = msg.sender;

         
        require(block.timestamp > timeLocks[reserveWallet]);

         
        uint256 vestingStage = finanVestingStage();

         
        uint256 totalUnlocked = vestingStage.mul(2.4 * (10 ** 7) * (10 ** 8));

         
        require(totalUnlocked <= allocations[finanReserveWallet]);

         
        require(claimed[finanReserveWallet] < totalUnlocked);

         
        uint256 payment = totalUnlocked.sub(claimed[finanReserveWallet]);

         
        claimed[finanReserveWallet] = totalUnlocked;

         
        require(token.transfer(reserveWallet, payment));

        Distributed(reserveWallet, payment);
    }

     
    function finanVestingStage() public view onlyTokenReserveFinance returns(uint256) {

        uint256 nowTime = block.timestamp;

         
        uint256 stage = (nowTime.sub(finanReserveTimeLock)).div(2592000);

         
        if(stage > finanVestingStages) {
            stage = finanVestingStages;
        }

        return stage;

    }

     
    function claimTokenReserveEcon() onlyTokenReserveEcon locked public {

        address reserveWallet = msg.sender;

         
        require(block.timestamp > timeLocks[reserveWallet]);

        uint256 vestingStage = econVestingStage();

         
        uint256 totalUnlocked;

         
        if (vestingStage <= 72) {
          totalUnlocked = vestingStage.mul(1200000 * (10 ** 8));
        } else {         
          totalUnlocked = ((vestingStage.sub(72)).mul(200000 * (10 ** 8))).add(86400000 * (10 ** 8));
        }

         
        require(totalUnlocked <= allocations[econReserveWallet]);

         
        require(claimed[econReserveWallet] < totalUnlocked);

         
        uint256 payment = totalUnlocked.sub(claimed[econReserveWallet]);

         
        claimed[econReserveWallet] = totalUnlocked;

         
        require(token.transfer(reserveWallet, payment));

        Distributed(reserveWallet, payment);
    }

     
    function econVestingStage() public view onlyTokenReserveEcon returns(uint256) {

        uint256 nowTime = block.timestamp;

         
        uint256 stage = (nowTime.sub(timeLocks[econReserveWallet])).div(2592000);

         
        if(stage > econVestingStages) {
            stage = econVestingStages;
        }

        return stage;

    }

     
    function claimTokenReserveDevelop() onlyTokenReserveDevelop locked public {

      address reserveWallet = msg.sender;

       
      require(block.timestamp > timeLocks[reserveWallet]);

       
      require(claimed[reserveWallet] == 0);

       
      uint256 payment = allocations[reserveWallet];

       
      claimed[reserveWallet] = payment;

       
      require(token.transfer(reserveWallet, payment));

      Distributed(reserveWallet, payment);
    }


     
    function canCollect() public view onlyReserveWallets returns(bool) {

        return block.timestamp > timeLocks[msg.sender] && claimed[msg.sender] == 0;

    }

}