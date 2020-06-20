pragma solidity ^0.4.18;

 

 
contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


}

 

contract ISStop is Ownable {

    bool public stopped;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() public onlyOwner {
        stopped = true;
    }
    function start() public onlyOwner {
        stopped = false;
    }

}

 

 
contract ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract StandardToken is BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract InseeCoin is ISStop, StandardToken{
    string public name = "Insee Coin";
    uint8 public decimals = 18;
    string public symbol = "SEE";
    string public version = "v0.1";
      
    uint256 public initialAmount = (10 ** 10) * (10 ** 18);
   

    event Destroy(address from, uint value);

    function InseeCoin() public {
        balances[msg.sender] = initialAmount;    
        totalSupply_ = initialAmount;               
    }

    function transfer(address dst, uint wad) public stoppable  returns (bool) {
        return super.transfer(dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public stoppable  returns (bool) {
        return super.transferFrom(src, dst, wad);
    }
    
    function approve(address guy, uint wad) public stoppable  returns (bool) {
        return super.approve(guy, wad);
    }

    function destroy(uint256 _amount) external onlyOwner stoppable  returns (bool success){
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        emit Destroy(msg.sender, _amount);
        return true;
    }

     function setName(string name_) public onlyOwner{
        name = name_;
    }

}

 

contract TokenLock {
    using SafeMath for uint256;
	InseeCoin  public  ISC;      

     
    uint256 private nextLockID = 0;

     
    mapping (uint256 => TokenTimeLockInfo) public locks;

     
    struct TokenTimeLockInfo {

         
        address beneficiary;

         
        uint256 amount;

         
        uint256 unlockTime;
    }

     
    event Lock (uint256 indexed id, address indexed beneficiary,uint256 amount, uint256 lockTime);
       
    event Unlock (uint256 indexed id, address indexed beneficiary,uint256 amount, uint256 unlockTime);

	function TokenLock(InseeCoin isc) public {
        assert(address(isc) != address(0));

        ISC = isc;
	}

	 
    function lock (
      address _beneficiary, uint256 _amount,
        uint256 _lockTime) public returns (uint256) {
        require (_amount > 0);
        require (_lockTime > 0);

        nextLockID = nextLockID.add(1);
        uint256 id = nextLockID;

        TokenTimeLockInfo storage lockInfo = locks [id];
        require (lockInfo.beneficiary == 0x0);
        require (lockInfo.amount == 0);
        require (lockInfo.unlockTime == 0);

        lockInfo.beneficiary = _beneficiary;
        lockInfo.amount = _amount;
        lockInfo.unlockTime =  now.add(_lockTime);

        emit Lock (id, _beneficiary, _amount, _lockTime);

        require (ISC.transferFrom (msg.sender, this, _amount));

        return id;
    }


     
    function unlock (uint256 _id) public {
        TokenTimeLockInfo memory lockInfo = locks [_id];
        delete locks [_id];

        require (lockInfo.amount > 0);
        require (lockInfo.unlockTime <= block.timestamp);

        emit Unlock (_id, lockInfo.beneficiary, lockInfo.amount, lockInfo.unlockTime);

        require (
            ISC.transfer (
                lockInfo.beneficiary, lockInfo.amount));
    }


}