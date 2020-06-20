pragma solidity ^0.4.18;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract SelfllerySaleFoundation is Ownable {
    using SafeMath for uint;

     
    mapping (address => uint) public paidEther;
     
    mapping (address => uint) public preSaleParticipantTokens;
     
    mapping (address => uint) public sentTokens;

     
    address public selflleryManagerWallet;
     
    ERC20 public token;
     
    uint public tokenCents;
     
    uint public tokenPriceWei;
     
    uint public saleTokensCents;

     
    uint public currentCapTokens;
     
    uint public currentCapEther;
     
    uint public startDate;
     
    uint public bonusEndDate;
     
    uint public endDate;
     
    uint public hardCapTokens;
     
    uint public minimumPurchaseAmount;
     
    uint8 public bonusPercent;

    event PreSalePurchase(address indexed purchasedBy, uint amountTokens);

    event Purchase(address indexed purchasedBy, uint amountTokens, uint etherWei);

     
    modifier onlyDuringICODates() {
        require(now >= startDate && now <= endDate);
        _;
    }

     
    function SelfllerySaleFoundation(
        address _token,
        address _selflleryManagerWallet,
        uint _tokenCents,
        uint _tokenPriceWei,
        uint _saleTokensCents,
        uint _startDate,
        uint _bonusEndDate,
        uint _endDate,
        uint _hardCapTokens,
        uint _minimumPurchaseAmount,
        uint8 _bonusPercent
    )
        public
        Ownable()
    {
        token = ERC20(_token);
        selflleryManagerWallet = _selflleryManagerWallet;
        tokenCents = _tokenCents;
        tokenPriceWei = _tokenPriceWei;
        saleTokensCents = _saleTokensCents;
        startDate = _startDate;
        bonusEndDate = _bonusEndDate;
        endDate = _endDate;
        hardCapTokens = _hardCapTokens;
        minimumPurchaseAmount = _minimumPurchaseAmount;
        bonusPercent = _bonusPercent;
    }

     
    function () public payable {
        purchase();
    }

     
    function purchase() public payable returns(bool) {
        return purchaseFor(msg.sender);
    }

     
    function purchaseFor(address _participant) public payable onlyDuringICODates() returns(bool) {
        require(_participant != 0x0);
        require(paidEther[_participant].add(msg.value) >= minimumPurchaseAmount);

        selflleryManagerWallet.transfer(msg.value);

        uint currentBonusPercent = getCurrentBonusPercent();
        uint totalTokens = calcTotalTokens(msg.value, currentBonusPercent);
        require(currentCapTokens.add(totalTokens) <= saleTokensCents);
        require(token.transferFrom(owner, _participant, totalTokens));
        sentTokens[_participant] = sentTokens[_participant].add(totalTokens);
        currentCapTokens = currentCapTokens.add(totalTokens);
        currentCapEther = currentCapEther.add(msg.value);
        paidEther[_participant] = paidEther[_participant].add(msg.value);
        Purchase(_participant, totalTokens, msg.value);

        return true;
    }

     
    function changeMinimumPurchaseAmount(uint _newMinimumPurchaseAmount) public onlyOwner returns(bool) {
        require(_newMinimumPurchaseAmount >= 0);
        minimumPurchaseAmount = _newMinimumPurchaseAmount;
        return true;
    }

     
    function addPreSalePurchaseTokens(address _participant, uint _totalTokens) public onlyOwner returns(bool) {
        require(_participant != 0x0);
        require(_totalTokens > 0);
        require(currentCapTokens.add(_totalTokens) <= saleTokensCents);

        require(token.transferFrom(owner, _participant, _totalTokens));
        sentTokens[_participant] = sentTokens[_participant].add(_totalTokens);
        preSaleParticipantTokens[_participant] = preSaleParticipantTokens[_participant].add(_totalTokens);
        currentCapTokens = currentCapTokens.add(_totalTokens);
        PreSalePurchase(_participant, _totalTokens);
        return true;
    }

     
    function isFinishDateReached() public constant returns(bool) {
        return endDate <= now;
    }

     
    function isHardCapTokensReached() public constant returns(bool) {
        return hardCapTokens <= currentCapTokens;
    }

     
    function isIcoFinished() public constant returns(bool) {
        return isFinishDateReached() || isHardCapTokensReached();
    }

     
    function calcTotalTokens(uint _value, uint _bonusPercent) internal view returns(uint) {
        uint tokensAmount = _value.mul(tokenCents).div(tokenPriceWei);
        require(tokensAmount > 0);
        uint bonusTokens = tokensAmount.mul(_bonusPercent).div(100);
        uint totalTokens = tokensAmount.add(bonusTokens);
        return totalTokens;
    }

     
    function getCurrentBonusPercent() internal constant returns (uint) {
        uint currentBonusPercent;
        if (now <= bonusEndDate) {
            currentBonusPercent = bonusPercent;
        } else {
            currentBonusPercent = 0;
        }
        return currentBonusPercent;
    }
}

contract SelfllerySale is SelfllerySaleFoundation {
    address constant TOKEN_ADDRESS = 0x7e921CA9b78d9A6cCC39891BA545836365525C06;  
    address constant SELFLLERY_MANAGER_WALLET = 0xdABb398298192192e5d4Ed2f120Ff7Af312B06eb; 
    uint constant TOKEN_CENTS = 1e18;
    uint constant TOKEN_PRICE_WEI = 1e15;
    uint constant SALE_TOKENS_CENTS = 55000000 * TOKEN_CENTS;
    uint constant SALE_HARD_CAP_TOKENS = 55000000 * TOKEN_CENTS;

    uint8 constant BONUS_PERCENT = 5;
    uint constant MINIMUM_PURCHASE_AMOUNT = 0.1 ether;

    uint constant SALE_START_DATE = 1520240400;  
    uint constant SALE_BONUS_END_DATE = 1520413200;  
    uint constant SALE_END_DATE = 1522144800;  

     
    function SelfllerySale()
        public
        SelfllerySaleFoundation(
            TOKEN_ADDRESS,
            SELFLLERY_MANAGER_WALLET,
            TOKEN_CENTS,
            TOKEN_PRICE_WEI,
            SALE_TOKENS_CENTS,
            SALE_START_DATE,
            SALE_BONUS_END_DATE,
            SALE_END_DATE,
            SALE_HARD_CAP_TOKENS,
            MINIMUM_PURCHASE_AMOUNT,
            BONUS_PERCENT
        ) {}
}