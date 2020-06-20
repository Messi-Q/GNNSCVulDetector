pragma solidity ^0.4.21;

 
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

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
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

interface GACR {
    function transfer(address to, uint256 value) external returns (bool);
    function mint(address _to, uint256 _amount) external returns (bool);
    function finishMinting() external returns (bool);
    function totalSupply() external view returns (uint256);
    function setTeamAddress(address _teamFund) external;
    function transferOwnership(address newOwner) external;
}

contract Crowdsale is Ownable {
    using SafeMath for uint256;

     
    enum CrowdsaleStage { PreICO, ICO }
    CrowdsaleStage public stage = CrowdsaleStage.PreICO;  

     
    uint256 public constant maxTokens           = 50000000*1e18;     
    uint256 public constant tokensForSale       = 28500000*1e18;     
    uint256 public constant tokensForBounty     = 1500000*1e18;      
    uint256 public constant tokensForAdvisors   = 3000000*1e18;      
    uint256 public constant tokensForTeam       = 9000000*1e18;      
    uint256 public tokensForEcosystem           = 8000000*1e18;      

     
    uint256 startTime   = 1522494000;    
    uint256 endTime     = 1539169200;    

     
    GACR public token;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    uint256 public cap;

     
    mapping(address => bool) public whitelist;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    event WhitelistUpdate(address indexed purchaser, bool status);

     
    event Finalized();

     
    constructor(uint256 _cap, uint256 _rate, address _wallet, address _token) public {
        require(_cap > 0);
        require(_rate > 0);
        require(_wallet != address(0));

        cap = _cap;
        rate = _rate;
        wallet = _wallet;
        token = GACR(_token);
    }

     
    modifier saleIsOn() {
        require(now > startTime && now < endTime);
        _;
    }

     
     
     
     
     

     
    function buyTokens(address _beneficiary) saleIsOn public payable {
        uint256 _weiAmount = msg.value;

        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(weiRaised.add(_weiAmount) <= cap);

        require(stage==CrowdsaleStage.PreICO ||
               (stage==CrowdsaleStage.ICO && isWhitelisted(_beneficiary)));

         
        uint256 _tokenAmount = _weiAmount.mul(rate);

         
        uint256 bonusTokens = 0;
        if (stage == CrowdsaleStage.PreICO) {
            if (_tokenAmount >= 50e18 && _tokenAmount < 3000e18) {
                bonusTokens = _tokenAmount.mul(23).div(100);
            } else if (_tokenAmount >= 3000e18 && _tokenAmount < 15000e18) {
                bonusTokens = _tokenAmount.mul(27).div(100);
            } else if (_tokenAmount >= 15000e18 && _tokenAmount < 30000e18) {
                bonusTokens = _tokenAmount.mul(30).div(100);
            } else if (_tokenAmount >= 30000e18) {
                bonusTokens = _tokenAmount.mul(35).div(100);
            }
        } else if (stage == CrowdsaleStage.ICO) {
            uint256 _nowTime = now;

            if (_nowTime >= 1531486800 && _nowTime < 1532696400) {
                bonusTokens = _tokenAmount.mul(18).div(100);
            } else if (_nowTime >= 1532696400 && _nowTime < 1533906000) {
                bonusTokens = _tokenAmount.mul(15).div(100);
            } else if (_nowTime >= 1533906000 && _nowTime < 1535115600) {
                bonusTokens = _tokenAmount.mul(12).div(100);
            } else if (_nowTime >= 1535115600 && _nowTime < 1536325200) {
                bonusTokens = _tokenAmount.mul(9).div(100);
            } else if (_nowTime >= 1536325200 && _nowTime < 1537534800) {
                bonusTokens = _tokenAmount.mul(6).div(100);
            } else if (_nowTime >= 1537534800 && _nowTime < endTime) {
                bonusTokens = _tokenAmount.mul(3).div(100);
            }
        }
        _tokenAmount += bonusTokens;

         
        require(tokensForSale >= (token.totalSupply() + _tokenAmount));

         
        weiRaised = weiRaised.add(_weiAmount);
        token.mint(_beneficiary, _tokenAmount);

        emit TokenPurchase(msg.sender, _beneficiary, _weiAmount, _tokenAmount);

        wallet.transfer(_weiAmount);
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function setCrowdsaleStage(uint value) public onlyOwner {

        CrowdsaleStage _stage;

        if (uint256(CrowdsaleStage.PreICO) == value) {
            _stage = CrowdsaleStage.PreICO;
        } else if (uint256(CrowdsaleStage.ICO) == value) {
            _stage = CrowdsaleStage.ICO;
        }

        stage = _stage;
    }

     
    function setNewRate(uint _newRate) public onlyOwner {
        require(_newRate > 0);
        rate = _newRate;
    }

     
    function setHardCap(uint256 _newCap) public onlyOwner {
        require(_newCap > 0);
        cap = _newCap;
    }

     
    function changeWallet(address _newWallet) public onlyOwner {
        require(_newWallet != address(0));
        wallet = _newWallet;
    }

     
    function updateWhitelist(address[] addresses, bool status) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address contributorAddress = addresses[i];
            whitelist[contributorAddress] = status;
            emit WhitelistUpdate(contributorAddress, status);
        }
    }

     
    function isWhitelisted(address contributor) public constant returns (bool) {
        return whitelist[contributor];
    }

     
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
        return token.mint(_to, _amount);
    }

     
    function returnOwnership() onlyOwner public returns (bool) {
        token.transferOwnership(owner);
    }

     
    function finish(address _bountyFund, address _advisorsFund, address _ecosystemFund, address _teamFund) public onlyOwner {
        require(_bountyFund != address(0));
        require(_advisorsFund != address(0));
        require(_ecosystemFund != address(0));
        require(_teamFund != address(0));

        emit Finalized();

         
        uint256 unsoldTokens = tokensForSale - token.totalSupply();
        if (unsoldTokens > 0) {
            tokensForEcosystem = tokensForEcosystem + unsoldTokens;
        }

         
        token.mint(_bountyFund,tokensForBounty);
        token.mint(_advisorsFund,tokensForAdvisors);
        token.mint(_ecosystemFund,tokensForEcosystem);
        token.mint(_teamFund,tokensForTeam);

         
        token.finishMinting();

         
        token.setTeamAddress(_teamFund);
    }
}