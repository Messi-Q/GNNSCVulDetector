pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract Ownable {
  address public owner;


  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
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

contract Crowdsale is Ownable {
  using SafeMath for uint256;

  ERC20 public token;

   
  uint256 public price;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  bool public isFinalized = false;

  event Finalized();

   
  constructor(ERC20 _token, uint256 _price) public {
    require(_token != address(0));
    require(_price > 0);
    token = _token;
    price = _price;
  }

   
  function () external payable {
    require(!isFinalized);

    address beneficiary = msg.sender;
    uint256 weiAmount = msg.value;

    require(beneficiary != address(0));
    require(weiAmount != 0);

    uint256 tokens = weiAmount.div(price);
    uint256 selfBalance = balance();
    require(tokens > 0);
    require(tokens <= selfBalance);

     
    token.transfer(beneficiary, tokens);

    emit TokenPurchase(
      beneficiary,
      weiAmount,
      tokens
    );

     
    owner.transfer(msg.value);

     
    weiRaised = weiRaised.add(weiAmount);
  }


   
  function balance() public view returns (uint256) {
    address self = address(this);
    uint256 selfBalance = token.balanceOf(self);
    return selfBalance;
  }

   
  function setPrice(uint256 _price) onlyOwner public {
    require(_price > 0);
    price = _price;
  }

   
  function finalize() onlyOwner public {
    require(!isFinalized);

    transferBallance();

    emit Finalized();
    isFinalized = true;
  }

   
  function transferBallance() onlyOwner public {
    uint256 selfBalance = balance();
    token.transfer(msg.sender, selfBalance);
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