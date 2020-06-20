pragma solidity ^0.4.13;

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

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

contract WfmToken is StandardToken {
    string public constant name = "WFM Token";
    string public constant symbol = "WFM";
    uint8 public constant decimals = 18;
    uint256 constant denomination = 10 ** uint(decimals);
    uint256 constant totalTokens = 100000000 * denomination;   
    uint256 constant ownerPart = 35000000 * denomination;      
    uint256 constant crowdsaleRate = 16000;
    uint256 constant icoRate = 11250;
    uint256 constant crowdsaleBeginTime = 1532476800;   
    uint256 constant icoBeginTime =  1535760000;        
    uint256 constant icoFinishTime = 1539648000;        
    uint256 constant softCapEther = 300 ether;
    uint256 constant hardCapEther = 5000 ether;
    address constant public initialOwner = 0xf62acdc7c42a0e1874f099A9f49204E08305bC88;

    address public owner = initialOwner;
    uint256 public raisedEther;
    mapping(address => uint256) public investment;

    constructor() public {
        totalSupply_ = totalTokens;
        balances[this] = totalTokens - ownerPart;
        balances[owner] = ownerPart;
        emit Transfer(address(0), this, totalTokens - ownerPart);
        emit Transfer(address(0), owner, ownerPart);
    }

    function rate() public view returns (uint256) {
        return icoStarted()? icoRate : crowdsaleRate;
    }

    function softCapReached() public view returns (bool) {
        return raisedEther >= softCapEther;
    }

    function hardCapReached() public view returns (bool) {
        return raisedEther >= hardCapEther;
    }

    function saleStarted() public view returns (bool) {
        return now >= crowdsaleBeginTime;
    }

    function icoStarted() public view returns (bool) {
        return now >= icoBeginTime;
    }

    function icoFinished() public view returns (bool) {
        return now >= icoFinishTime;
    }

    function () public payable {
        require(saleStarted() && !icoFinished() && !hardCapReached());
        uint tokens = msg.value.mul(rate());
        investment[msg.sender] = investment[msg.sender].add(msg.value);
        raisedEther = raisedEther.add(msg.value);
        balances[this] = balances[this].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        emit Transfer(this, msg.sender, tokens);
    }

    function withdraw() public {
        if (!softCapReached()) {
            require(icoStarted());
            uint256 amount = investment[msg.sender];
            if (amount > 0) {
                investment[msg.sender] = 0;
                emit Transfer(msg.sender, address(0), balances[msg.sender]);
                balances[msg.sender] = 0;
                msg.sender.transfer(amount);
            }
        } else {
            require(msg.sender == owner);
            owner.transfer(address(this).balance);
        }
    }

    function withdrawUnsoldTokens() public {
        require(msg.sender == owner);
        require(icoFinished());
        uint value = balances[this];
        balances[this] = 0;
        balances[owner] = balances[msg.sender].add(value);
        emit Transfer(this, owner, value);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function transferOwnership(address _newOwner) public {
        require(msg.sender == owner);
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}