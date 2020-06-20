pragma solidity ^0.4.18;

 

 
interface IEscrow {

  event Created(
    address indexed sender,
    address indexed recipient,
    address indexed arbitrator,
    uint256 transactionId
  );
  event Released(address indexed arbitrator, address indexed sentTo, uint256 transactionId);
  event Dispute(address indexed arbitrator, uint256 transactionId);
  event Paid(address indexed arbitrator, uint256 transactionId);

  function create(
      address _sender,
      address _recipient,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee,
      uint256 _expiration
  ) public;

  function fund(
      address _sender,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee
  ) public;

}

 

 
interface ISendToken {
  function transfer(address to, uint256 value) public returns (bool);

  function isVerified(address _address) public constant returns(bool);

  function verify(address _address) public;

  function unverify(address _address) public;

  function verifiedTransferFrom(
      address from,
      address to,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate,
      uint256 fee
  ) public;

  function issueExchangeRate(
      address _from,
      address _to,
      address _verifiedAddress,
      uint256 _value,
      uint256 _referenceId,
      uint256 _exchangeRate
  ) public;

  event VerifiedTransfer(
      address indexed from,
      address indexed to,
      address indexed verifiedAddress,
      uint256 value,
      uint256 referenceId,
      uint256 exchangeRate
  );
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

 

 
contract Escrow is IEscrow, Ownable {
  using SafeMath for uint256;

  ISendToken public token;

  struct Lock {
    address sender;
    address recipient;
    uint256 value;
    uint256 fee;
    uint256 expiration;
    bool paid;
  }

  mapping(address => mapping(uint256 => Lock)) internal escrows;

  function Escrow(address _token) public {
    token = ISendToken(_token);
  }

  modifier tokenRestricted() {
    require(msg.sender == address(token));
    _;
  }

  function getStatus(address _arbitrator, uint256 _transactionId) 
      public view returns(address, address, uint256, uint256, uint256, bool) {
    return(
      escrows[_arbitrator][_transactionId].sender,
      escrows[_arbitrator][_transactionId].recipient,
      escrows[_arbitrator][_transactionId].value,
      escrows[_arbitrator][_transactionId].fee,
      escrows[_arbitrator][_transactionId].expiration,
      escrows[_arbitrator][_transactionId].paid
    );
  }

  function isUnlocked(address _arbitrator, uint256 _transactionId) public view returns(bool) {
    return escrows[_arbitrator][_transactionId].expiration == 1;
  }

   
  function create(
      address _sender,
      address _recipient,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee,
      uint256 _expiration
  ) public tokenRestricted {

    require(_tokens > 0);
    require(_fee >= 0);
    require(escrows[_arbitrator][_transactionId].value == 0);

    escrows[_arbitrator][_transactionId].sender = _sender;
    escrows[_arbitrator][_transactionId].recipient = _recipient;
    escrows[_arbitrator][_transactionId].value = _tokens;
    escrows[_arbitrator][_transactionId].fee = _fee;
    escrows[_arbitrator][_transactionId].expiration = _expiration;

    Created(_sender, _recipient, _arbitrator, _transactionId);
  }

   
  function fund(
      address _sender,
      address _arbitrator,
      uint256 _transactionId,
      uint256 _tokens,
      uint256 _fee
  ) public tokenRestricted {

    require(escrows[_arbitrator][_transactionId].sender == _sender);
    require(escrows[_arbitrator][_transactionId].value == _tokens);
    require(escrows[_arbitrator][_transactionId].fee == _fee);
    require(escrows[_arbitrator][_transactionId].paid == false);

    escrows[_arbitrator][_transactionId].paid = true;

    Paid(_arbitrator, _transactionId);
  }

   
  function release(
      address _sender,
      address _recipient,
      uint256 _transactionId,
      uint256 _exchangeRate
  ) public {

    Lock memory lock = escrows[msg.sender][_transactionId];

    require(lock.expiration != 1);
    require(lock.sender == _sender);
    require(lock.recipient == _recipient || lock.sender == _recipient);
    require(lock.paid);

    if (lock.fee > 0 && lock.recipient == _recipient) {
      token.transfer(_recipient, lock.value);
      token.transfer(msg.sender, lock.fee);
    } else {
      token.transfer(_recipient, lock.value.add(lock.fee));
    }

    delete escrows[msg.sender][_transactionId];

    token.issueExchangeRate(
      _sender,
      _recipient,
      msg.sender,
      lock.value,
      _transactionId,
      _exchangeRate
    );
    Released(msg.sender, _recipient, _transactionId);
  }

   
  function releaseUnlocked(
      address _sender,
      address _recipient,
      uint256 _transactionId,
      uint256 _exchangeRate
  ) public {

    Lock memory lock = escrows[msg.sender][_transactionId];

    require(lock.expiration == 1);
    require(lock.sender == _sender);
    require(lock.paid);

    if (lock.fee > 0 && lock.sender != _recipient) {
      token.transfer(_recipient, lock.value);
      token.transfer(msg.sender, lock.fee);
    } else {
      token.transfer(_recipient, lock.value.add(lock.fee));
    }

    delete escrows[msg.sender][_transactionId];

    token.issueExchangeRate(
      _sender,
      _recipient,
      msg.sender,
      lock.value,
      _transactionId,
      _exchangeRate
    );
    Released(msg.sender, _recipient, _transactionId);
  }

   
  function claim(
      address _arbitrator,
      uint256 _transactionId
  ) public {
    Lock memory lock = escrows[_arbitrator][_transactionId];

    require(lock.sender == msg.sender);
    require(lock.paid);
    require(lock.expiration < block.timestamp);
    require(lock.expiration != 0);
    require(lock.expiration != 1);

    delete escrows[_arbitrator][_transactionId];

    token.transfer(msg.sender, lock.value.add(lock.fee));

    Released(
      _arbitrator,
      msg.sender,
      _transactionId
    );
  }

   
  function mediate(
      uint256 _transactionId
  ) public {
    require(escrows[msg.sender][_transactionId].paid);
    require(escrows[msg.sender][_transactionId].expiration != 0);
    require(escrows[msg.sender][_transactionId].expiration != 1);

    escrows[msg.sender][_transactionId].expiration = 0;

    Dispute(msg.sender, _transactionId);
  }

   
  function transferToken(address _tokenAddress, address _transferTo, uint256 _value) public onlyOwner {
    require(_tokenAddress != address(token));

    ISendToken erc20Token = ISendToken(_tokenAddress);
    erc20Token.transfer(_transferTo, _value);
  }
}