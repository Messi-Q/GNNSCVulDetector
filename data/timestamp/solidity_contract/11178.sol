pragma solidity ^0.4.18;

 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

 
contract Ownable {
  address public owner;

  mapping (address => bool) public admins;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
    admins[owner] = true;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier onlyAdmin() {
    require(admins[msg.sender]);
    _;
  }

  function changeAdmin(address _newAdmin, bool _approved) onlyOwner public {
    admins[_newAdmin] = _approved;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

 
contract Economeme is ERC721, Ownable {
  using SafeMath for uint256;

   
  uint256 private totalTokens;
  uint256 public developerCut;
  uint256 public submissionPool;  
  uint256 public submissionPrice;  
  uint256 public endingBalance;  

   
  mapping (uint256 => Meme) public memeData;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
  mapping (address => uint256) public creatorBalances;

   
  event Purchase(uint256 indexed _tokenId, address indexed _buyer, address indexed _seller, uint256 _purchasePrice);
  event Creation(address indexed _creator, uint256 _tokenId, uint256 _timestamp);

   
  uint256 private firstCap  = 0.02 ether;
  uint256 private secondCap = 0.5 ether;
  uint256 private thirdCap  = 2.0 ether;
  uint256 private finalCap  = 5.0 ether;

   
  struct Meme {
    uint256 price;          
    address owner;          
    address creator;        
  }
  
  function Economeme() public {
    submissionPrice = 1 ether / 100;
  }

 

   
  function buyToken(uint256 _tokenId) public 
    payable
  {
     
    Meme storage meme = memeData[_tokenId];
    uint256 price = meme.price;
    address oldOwner = meme.owner;
    address newOwner = msg.sender;
    uint256 excess = msg.value.sub(price);

     
    require(price > 0);
    require(msg.value >= price);
    require(oldOwner != msg.sender);
    
    uint256 devCut = price.mul(2).div(100);
    developerCut = developerCut.add(devCut);

    uint256 creatorCut = price.mul(2).div(100);
    creatorBalances[meme.creator] = creatorBalances[meme.creator].add(creatorCut);

    uint256 transferAmount = price.sub(creatorCut + devCut);

    transferToken(oldOwner, newOwner, _tokenId);

     
    emit Purchase(_tokenId, newOwner, oldOwner, price);

     
    meme.price = getNextPrice(price);

     
    safeTransfer(oldOwner, transferAmount);
    
     
    if (excess > 0) {
      newOwner.transfer(excess);
    }
    
     
     
    if (address(this).balance > endingBalance + creatorCut + devCut) submissionPool += transferAmount;
    
    endingBalance = address(this).balance;
  }

   
  function safeTransfer(address _oldOwner, uint256 _amount) internal { 
    assembly { 
        let x := mload(0x40) 
        let success := call(
            5000, 
            _oldOwner, 
            _amount, 
            x, 
            0x0, 
            x, 
            0x20) 
        mstore(0x40,add(x,0x20)) 
    } 
  }

   
  function transferToken(address _from, address _to, uint256 _tokenId) internal {
     
    require(tokenExists(_tokenId));

     
    require(memeData[_tokenId].owner == _from);

    require(_to != address(0));
    require(_to != address(this));

     
    clearApproval(_from, _tokenId);

     
    removeToken(_from, _tokenId);

     
    addToken(_to, _tokenId);

     
    emit Transfer(_from, _to, _tokenId);
  }
  
   
  function getNextPrice (uint256 _price) internal view returns (uint256 _nextPrice) {
    if (_price < firstCap) {
      return _price.mul(200).div(95);
    } else if (_price < secondCap) {
      return _price.mul(135).div(96);
    } else if (_price < thirdCap) {
      return _price.mul(125).div(97);
    } else if (_price < finalCap) {
      return _price.mul(117).div(97);
    } else {
      return _price.mul(115).div(98);
    }
  }

 

   
  function createToken() external payable {
     
    uint256 tokenId = totalTokens + 1;
    require(memeData[tokenId].price == 0);
    require(msg.value == submissionPrice);
    submissionPool += submissionPrice;
    endingBalance = address(this).balance;
    
     
    memeData[tokenId] = Meme(1 ether / 100, msg.sender, msg.sender);

     
    _mint(msg.sender, tokenId);
    
    emit Creation(msg.sender, tokenId, block.timestamp);
  }

   
  function withdrawBalance(address _beneficiary) external {
    uint256 payout = creatorBalances[_beneficiary];
    creatorBalances[_beneficiary] = 0;
    _beneficiary.transfer(payout);
    endingBalance = address(this).balance;
  }

 

   
  function getMemeData (uint256 _tokenId) external view 
  returns (address _owner, uint256 _price, uint256 _nextPrice, address _creator) 
  {
    Meme memory meme = memeData[_tokenId];
    return (meme.owner, meme.price, getNextPrice(meme.price), meme.creator);
  }

   
  function checkBalance(address _owner) external view returns (uint256) {
    return creatorBalances[_owner];
  }

   
  function tokenExists (uint256 _tokenId) public view returns (bool _exists) {
    return memeData[_tokenId].price > 0;
  }
  
 
  
   
  function withdraw(uint256 _devAmount, uint256 _submissionAmount) public onlyAdmin() {
    if (_devAmount == 0) { 
      _devAmount = developerCut; 
    }
    if (_submissionAmount == 0) {
      _submissionAmount = submissionPool;
    }
    developerCut = developerCut.sub(_devAmount);
    submissionPool = submissionPool.sub(_submissionAmount);
    owner.transfer(_devAmount + _submissionAmount);
    endingBalance = address(this).balance;
  }

   
  function refundSubmission(address _refundee, uint256 _amount) external onlyAdmin() {
    submissionPool = submissionPool.sub(_amount);
    _refundee.transfer(_amount);
    endingBalance = address(this).balance;
  }
  
   
  function refundByToken(uint256 _tokenId) external onlyAdmin() {
    submissionPool = submissionPool.sub(submissionPrice);
    memeData[_tokenId].creator.transfer(submissionPrice);
    endingBalance = address(this).balance;
  }

   
  function changeSubmissionPrice(uint256 _newPrice) external onlyAdmin() {
    submissionPrice = _newPrice;
  }


 

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

 

   
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    return owner;
  }

   
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

   
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }
  
   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    emit Approval(_owner, 0, _tokenId);
  }


     
  function _mint(address _to, uint256 _tokenId) internal {
    addToken(_to, _tokenId);
    emit Transfer(0x0, _to, _tokenId);
  }

   
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    memeData[_tokenId].owner = _to;
    
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }

  function name() public pure returns (string _name) {
    return "Economeme Meme";
  }

  function symbol() public pure returns (string _symbol) {
    return "ECME";
  }

}