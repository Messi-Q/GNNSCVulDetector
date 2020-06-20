pragma solidity ^0.4.21;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 
contract MintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) canMint internal returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() canMint internal returns (bool) {
    mintingFinished = true;
    emit MintFinished();
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract MTF is MintableToken, Ownable {

    using SafeMath for uint256;
     
    string public constant name = "MintFlint Token";
     
    string public constant symbol = "MTF";
     
    uint8 public constant decimals = 18;

     
    uint256 public constant maxCap = 1500000000e18;
     
    uint256 public totalWeiReceived;

     
    uint256 public startTime;
     
    uint256 public endTime;
     
    bool public paused;

     
    event StateChanged(bool);
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);

    function MTF(uint256 _startTime, uint256 _endTime) public {
        startTime = _startTime;
        endTime = _endTime;
        paused = false;
        totalSupply_ = 0;
    }

    modifier whenSaleEnded() {
        require(now >= endTime);
        _;
    }

     
    modifier validTimeframe() {
        require(!paused && now >=startTime && now < endTime);
        _;
    }

     
    function teamAllocation(address _airdropAddress) public onlyOwner whenSaleEnded {
        uint256 toDistribute = totalSupply_.mul(2);
         
        uint256 part1 = toDistribute.mul(3).div(400);
        mint(0x1117Db9F1bf18C91233Bff3BF2676137709463B3, part1);
        mint(0x6C137b489cEE58C32fd8Aec66EAdC4B959550198, part1);
        mint(0x450023b2D943498949f0A9cdb1DbBd827844EE78, part1);
        mint(0x89080db76A555c42D7b43556E40AcaAFeB786CDD, part1);

         
        uint256 part2 = toDistribute.mul(195).div(4000);
        mint(0xcFc43257606C6a642d9438dCd82bf5b39A17dbAB, part2);
        mint(0x4a8C5Ea0619c40070f288c8aC289ef2f6Bb87cff, part2);
        mint(0x947251376EeAFb0B0CD1bD47cC6056A5162bEaF4, part2);
        mint(0x39A49403eFB1e85F835A9e5dc82706B970D112e4, part2);

         
        mint(0x733bc7201261aC3c9508D20a811D99179304240a, toDistribute.mul(2).div(100));

         
        mint(0x4b6716bd349dC65d07152844ed4990C2077cF1a7, toDistribute.mul(18).div(100));

         
        uint256 part5 = toDistribute.mul(6).div(400);
        mint(0xEf628A29668C00d5C7C4D915F07188dC96cF24eb, part5);
        mint(0xF28a5e85316E0C950f8703e2d99F15A7c077014c, part5);
        mint(0x0c8C9Dcfa4ed27e02349D536fE30957a32b44a04, part5);
        mint(0x0A86174f18D145D3850501e2f4C160519207B829, part5);

         
         
         
        mint(0x35eeb3216E2Ff669F2c1Ff90A08A22F60e6c5728, toDistribute.mul(75).div(10000));
        mint(0x28dcC9Af670252A5f76296207cfcC29B4E3C68D5, toDistribute.mul(75).div(10000));

        mint(_airdropAddress, 175000000 ether);

        finishMinting();
    }

    function transfer(address _to, uint _value) whenSaleEnded public returns(bool _success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) whenSaleEnded public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function getPrice() public pure returns(uint256) {
        return 100000;
    }

     
    function pauseSale() public onlyOwner {
        require(!paused);
        paused = true;
    }

     
    function resumeSale() public onlyOwner {
        require(paused);
        paused = false;
    }

    function buyTokens(address beneficiary) internal validTimeframe {
        uint256 tokensBought = msg.value.mul(getPrice());
        totalWeiReceived = totalWeiReceived.add(msg.value);
        emit TokenPurchase(beneficiary, msg.value, tokensBought);
        mint(beneficiary, tokensBought);
        require(totalSupply_ <= maxCap);
    }

    function () public payable {
        buyTokens(msg.sender);
    }

     
    function drain() public onlyOwner whenSaleEnded {
        owner.transfer(address(this).balance);
    }
}