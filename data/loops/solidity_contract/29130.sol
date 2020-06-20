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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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

 

contract InkPublicPresale is Ownable {
  using SafeMath for uint256;

   
   
   
   
   
  bool public active;

   
  bool private refundable;

   
  uint256 public globalMin;
   
   
   
   
  uint256 public globalMax;
   
  uint256 public etherCap;
   
  uint256 private etherContributed;
   
  uint256 private xnkPurchased;
   
   
  address public tokenAddress;
   
  uint256 public maxGasPrice;

   
  mapping(address => Contributor) private contributors;

  struct Contributor {
    bool whitelisted;
     
    uint256 rate;
     
    uint256 max;
     
    uint256 balance;
  }

   
  modifier finalized {
    require(tokenAddress != address(0));
    _;
  }

   
  modifier notFinalized {
    require(tokenAddress == address(0));
    _;
  }

  function InkPublicPresale() public {
    globalMax = 1000000000000000000;  
    globalMin = 100000000000000000;   
    maxGasPrice = 40000000000;        
  }

  function updateMaxGasPrice(uint256 _maxGasPrice) public onlyOwner {
    require(_maxGasPrice > 0);

    maxGasPrice = _maxGasPrice;
  }

   
  function getEtherContributed() public view onlyOwner returns (uint256) {
    return etherContributed;
  }

   
  function getXNKPurchased() public view onlyOwner returns (uint256) {
    return xnkPurchased;
  }

   
   
   
  function updateEtherCap(uint256 _newEtherCap) public notFinalized onlyOwner {
    etherCap = _newEtherCap;
  }

   
  function updateGlobalMax(uint256 _globalMax) public notFinalized onlyOwner {
    require(_globalMax > globalMin);

    globalMax = _globalMax;
  }

   
  function updateGlobalMin(uint256 _globalMin) public notFinalized onlyOwner {
    require(_globalMin > 0);
    require(_globalMin < globalMax);

    globalMin = _globalMin;
  }

  function updateTokenAddress(address _tokenAddress) public finalized onlyOwner {
    require(_tokenAddress != address(0));

    tokenAddress = _tokenAddress;
  }

   
  function pause() public onlyOwner {
    require(active);
    active = false;
  }

   
  function resume() public onlyOwner {
    require(!active);
    active = true;
  }

   
   
  function enableRefund() public onlyOwner {
    require(!refundable);
    refundable = true;
  }

   
  function disableRefund() public onlyOwner {
    require(refundable);
    refundable = false;
  }

   
  function addContributor(address _account, uint256 _rate, uint256 _max) public onlyOwner notFinalized {
    require(_account != address(0));
    require(_rate > 0);
    require(_max >= globalMin);
    require(!contributors[_account].whitelisted);

    contributors[_account].whitelisted = true;
    contributors[_account].max = _max;
    contributors[_account].rate = _rate;
  }

   
  function updateContributor(address _account, uint256 _newRate, uint256 _newMax) public onlyOwner notFinalized {
    require(_account != address(0));
    require(_newRate > 0);
    require(_newMax >= globalMin);
    require(contributors[_account].whitelisted);

     
     
    if (contributors[_account].balance > 0 && contributors[_account].rate != _newRate) {
       
      xnkPurchased = xnkPurchased.sub(contributors[_account].balance.mul(contributors[_account].rate));

       
      xnkPurchased = xnkPurchased.add(contributors[_account].balance.mul(_newRate));
    }

    contributors[_account].rate = _newRate;
    contributors[_account].max = _newMax;
  }

   
   
  function removeContributor(address _account) public onlyOwner {
    require(_account != address(0));
    require(contributors[_account].whitelisted);

     
    contributors[_account].whitelisted = false;

     
    if (contributors[_account].balance > 0) {
      uint256 balance = contributors[_account].balance;

      contributors[_account].balance = 0;
      xnkPurchased = xnkPurchased.sub(balance.mul(contributors[_account].rate));
      etherContributed = etherContributed.sub(balance);

       
       
       
       
       
      !_account.call.value(balance)();
    }

    delete contributors[_account];
  }

  function withdrawXNK(address _to) public onlyOwner {
    require(_to != address(0));

    BasicToken token = BasicToken(tokenAddress);
    assert(token.transfer(_to, token.balanceOf(this)));
  }

  function withdrawEther(address _to) public finalized onlyOwner {
    require(_to != address(0));

    assert(_to.call.value(this.balance)());
  }

   
  function balanceOf(address _account) public view returns (uint256) {
    require(_account != address(0));

    return contributors[_account].balance;
  }

   
   
  function refund() public {
    require(active);
    require(refundable);
    require(contributors[msg.sender].whitelisted);

    uint256 balance = contributors[msg.sender].balance;

    require(balance > 0);

    contributors[msg.sender].balance = 0;
    etherContributed = etherContributed.sub(balance);
    xnkPurchased = xnkPurchased.sub(balance.mul(contributors[msg.sender].rate));

    assert(msg.sender.call.value(balance)());
  }

  function airdrop(address _account) public finalized onlyOwner {
    _processPayout(_account);
  }

   
   
   
  function finalize(address _tokenAddress) public notFinalized onlyOwner {
    require(_tokenAddress != address(0));

    tokenAddress = _tokenAddress;
  }

   
  function () public payable {
     
    if (msg.sender == owner && msg.value > 0) {
      return;
    }

    require(active);
    require(contributors[msg.sender].whitelisted);

    if (tokenAddress == address(0)) {
       
      _processContribution();
    } else {
       
       
      _processPayout(msg.sender);
    }
  }

   
  function _processContribution() private {
     
    require(msg.value > 0);
     
    require(tx.gasprice <= maxGasPrice);
     
     
    require(contributors[msg.sender].balance.add(msg.value) >= globalMin);
     
     
    require(etherCap > etherContributed);
     
     
    require(msg.value <= etherCap.sub(etherContributed));

    uint256 newBalance = contributors[msg.sender].balance.add(msg.value);

     
     
    if (globalMax <= contributors[msg.sender].max) {
      require(newBalance <= globalMax);
    } else {
      require(newBalance <= contributors[msg.sender].max);
    }

     
    contributors[msg.sender].balance = newBalance;
     
    etherContributed = etherContributed.add(msg.value);
     
    xnkPurchased = xnkPurchased.add(msg.value.mul(contributors[msg.sender].rate));
  }

   
  function _processPayout(address _recipient) private {
     
    require(msg.value == 0);

    uint256 balance = contributors[_recipient].balance;

     
    require(balance > 0);

     
    uint256 amount = balance.mul(contributors[_recipient].rate);

     
     
    contributors[_recipient].balance = 0;

     
    assert(BasicToken(tokenAddress).transfer(_recipient, amount));
  }
}