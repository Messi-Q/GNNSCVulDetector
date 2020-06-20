pragma solidity ^0.4.13;

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

contract PausableToken is Ownable {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function increaseFrozen(address _owner,uint256 _incrementalAmount) public returns (bool);
    function burn(uint256 _value) public;
}

contract AddressWhitelist is Ownable {
     
    mapping (address => bool) whitelisted;
    
    function isWhitelisted(address addr) view public returns (bool) {
        return whitelisted[addr];
    }

    event LogWhitelistAdd(address indexed addr);

     
    function addToWhitelist(address[] addresses) public onlyOwner returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            if (!whitelisted[addresses[i]]) {
                whitelisted[addresses[i]] = true;
                LogWhitelistAdd(addresses[i]);
            }
        }

        return true;
    }

    event LogWhitelistRemove(address indexed addr);

     
    function removeFromWhitelist(address[] addresses) public onlyOwner returns (bool) {
        for (uint i = 0; i < addresses.length; i++) {
            if (whitelisted[addresses[i]]) {
                whitelisted[addresses[i]] = false;
                LogWhitelistRemove(addresses[i]);
            }
        }

        return true;
    }
}

contract RtcTokenCrowdsale is Ownable, AddressWhitelist {
    using SafeMath for uint256;
    PausableToken  public tokenReward;                          

     
    uint256 public initialSupply;
    uint256 public tokensRemaining;
    uint256 public decimals;

     
    address public beneficiaryWallet;                            
    uint256 public tokensPerEthPrice;                            

     
    uint256 public amountRaisedInWei;
    uint256 public fundingMinCapInWei;

     
    uint256 public p1_duration;
    uint256 public p1_start;
    uint256 public p2_start;
    uint256 public white_duration;

     
    uint256 public fundingStartTime;                            
    uint256 public fundingEndTime;                              
    bool    public isCrowdSaleClosed               = false;      
    bool    public areFundsReleasedToBeneficiary   = false;      
    bool    public isCrowdSaleSetup                = false;      

     
    uint256 maxGasPrice = 50000000000;

    event Buy(address indexed _sender, uint256 _eth, uint256 _RTC);
    event Refund(address indexed _refunder, uint256 _value);
    mapping(address => uint256) fundValue;


     
    function toSmallrtc(uint256 amount) public constant returns (uint256) {
        return amount.mul(10**decimals);
    }

     
    function toRtc(uint256 amount) public constant returns (uint256) {
        return amount.div(10**decimals);
    }

    function updateMaxGasPrice(uint256 _newGasPrice) public onlyOwner {
        require(_newGasPrice != 0);
        maxGasPrice = _newGasPrice;
    }

     
    function setupCrowdsale(uint256 _fundingStartTime) external onlyOwner {
        if ((!(isCrowdSaleSetup))
            && (!(beneficiaryWallet > 0))){
             
            tokenReward                             = PausableToken(0x7c5c5F763274FC2f5bb86877815675B5dfB6FE3a);
            beneficiaryWallet                       = 0xf07bd63C5cf404c2f17ab4F9FA1e13fCCEbc5255;
            tokensPerEthPrice                       = 10000;                   

             
            fundingMinCapInWei                      = 1 ether;                           

             
            decimals                                = 18;
            amountRaisedInWei                       = 0;
            initialSupply                           = toSmallrtc(35000000);                   
            tokensRemaining                         = initialSupply;

            fundingStartTime                        = _fundingStartTime;

            white_duration                          = 2 hours;                         
            p1_duration                             = 4 hours;                        

            p1_start                                = fundingStartTime + white_duration;
            p2_start                                = p1_start + p1_duration + 4 hours;    

            fundingEndTime                          = p2_start + 4 hours;  

             
            isCrowdSaleSetup                        = true;
            isCrowdSaleClosed                       = false;
        }
    }

    function setBonusPrice() public constant returns (uint256 bonus) {
        require(isCrowdSaleSetup);
        require(p1_start + p1_duration <= p2_start);
        if (now >= fundingStartTime && now <= p1_start) {  
            bonus = 4000;
        } else if (now > p1_start && now <= p1_start + p1_duration) {  
            bonus = 3000;
        } else if (now > p2_start && now <= p2_start + 10 minutes ) {  
            bonus = 2500;
        } else if (now > p2_start + 10 minutes && now <= p2_start + 1 hours ) {  
            bonus = 2000;
        } else if (now > p2_start + 1 hours && now <= p2_start + 2 hours ) {  
            bonus = 1500;
        } else if (now > p2_start + 2 hours && now <= p2_start + 3 hours ) {  
            bonus = 1000;
        } else if (now > p2_start + 3 hours && now <= fundingEndTime ) {  
            bonus = 500;
        } else {
            revert();
        }
    }

     
    function updateDuration(uint256 _newP2Start) external onlyOwner {  
        require(isCrowdSaleSetup
            && !(p2_start == _newP2Start)
            && !(_newP2Start > p1_start + p1_duration + 30 hours)
            && (now < p2_start)
            && (fundingStartTime + p1_duration < _newP2Start));
        p2_start = _newP2Start;
        fundingEndTime = p2_start.add(4 hours);    
    }

     
    function () external payable {
        require(tx.gasprice <= maxGasPrice);
        require(msg.data.length == 0);
        
        BuyRTCtokens();
    }

    function BuyRTCtokens() public payable {
         
        require(!(msg.value == 0)
        && (isCrowdSaleSetup)
        && (now >= fundingStartTime)
        && (now <= fundingEndTime)
        && (tokensRemaining > 0));

         
        if (now <= p1_start) {
            assert(isWhitelisted(msg.sender));
        }
        uint256 rewardTransferAmount        = 0;
        uint256 rewardBaseTransferAmount    = 0;
        uint256 rewardBonusTransferAmount   = 0;
        uint256 contributionInWei           = msg.value;
        uint256 refundInWei                 = 0;

        rewardBonusTransferAmount       = setBonusPrice();
        rewardBaseTransferAmount        = (msg.value.mul(tokensPerEthPrice));  
        rewardBonusTransferAmount       = (msg.value.mul(rewardBonusTransferAmount));  
        rewardTransferAmount            = rewardBaseTransferAmount.add(rewardBonusTransferAmount);

        if (rewardTransferAmount > tokensRemaining) {
            uint256 partialPercentage;
            partialPercentage = tokensRemaining.mul(10**18).div(rewardTransferAmount);
            contributionInWei = contributionInWei.mul(partialPercentage).div(10**18);
            rewardBonusTransferAmount = rewardBonusTransferAmount.mul(partialPercentage).div(10**18);
            rewardTransferAmount = tokensRemaining;
            refundInWei = msg.value.sub(contributionInWei);
        }

        amountRaisedInWei               = amountRaisedInWei.add(contributionInWei);
        tokensRemaining                 = tokensRemaining.sub(rewardTransferAmount);   
        fundValue[msg.sender]           = fundValue[msg.sender].add(contributionInWei);
        assert(tokenReward.increaseFrozen(msg.sender, rewardBonusTransferAmount));
        tokenReward.transfer(msg.sender, rewardTransferAmount);
        Buy(msg.sender, contributionInWei, rewardTransferAmount);
        if (refundInWei > 0) {
            msg.sender.transfer(refundInWei);
        }
    }

    function beneficiaryMultiSigWithdraw() external onlyOwner {
        checkGoalReached();
        require(areFundsReleasedToBeneficiary && (amountRaisedInWei >= fundingMinCapInWei));
        beneficiaryWallet.transfer(this.balance);
    }

    function checkGoalReached() public returns (bytes32 response) {  
         
        require (isCrowdSaleSetup);
        if ((amountRaisedInWei < fundingMinCapInWei) && (block.timestamp <= fundingEndTime && block.timestamp >= fundingStartTime)) {  
            areFundsReleasedToBeneficiary = false;
            isCrowdSaleClosed = false;
            return "In progress (Eth < Softcap)";
        } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.timestamp < fundingStartTime)) {  
            areFundsReleasedToBeneficiary = false;
            isCrowdSaleClosed = false;
            return "Crowdsale is setup";
        } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.timestamp > fundingEndTime)) {  
            areFundsReleasedToBeneficiary = false;
            isCrowdSaleClosed = true;
            return "Unsuccessful (Eth < Softcap)";
        } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining == 0)) {  
            areFundsReleasedToBeneficiary = true;
            isCrowdSaleClosed = true;
            return "Successful (RTC >= Hardcap)!";
        } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.timestamp > fundingEndTime) && (tokensRemaining > 0)) {  
            areFundsReleasedToBeneficiary = true;
            isCrowdSaleClosed = true;
            return "Successful (Eth >= Softcap)!";
        } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining > 0) && (block.timestamp <= fundingEndTime)) {  
            areFundsReleasedToBeneficiary = true;
            isCrowdSaleClosed = false;
            return "In progress (Eth >= Softcap)!";
        }
    }

    function refund() external {  
        checkGoalReached();
         
        require ((amountRaisedInWei < fundingMinCapInWei)
        && (isCrowdSaleClosed)
        && (now > fundingEndTime)
        && (fundValue[msg.sender] > 0));

         
        uint256 ethRefund = fundValue[msg.sender];
        fundValue[msg.sender] = 0;

         
        msg.sender.transfer(ethRefund);
        Refund(msg.sender, ethRefund);
    }

    function burnRemainingTokens() onlyOwner external {
        require(now > fundingEndTime);
        uint256 tokensToBurn = tokenReward.balanceOf(this);
        tokenReward.burn(tokensToBurn);
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