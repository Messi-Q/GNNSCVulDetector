 

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

 
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract MplusCrowdsaleA {
    using SafeMath for uint256;

     
    uint256 internal constant NUM_STAGES = 4;

     
    uint256 internal constant ICO_START1 = 1519056000;
     
    uint256 internal constant ICO_START2 = 1521216000;
     
    uint256 internal constant ICO_START3 = 1522598400;
     
    uint256 internal constant ICO_START4 = 1523894400;
     
    uint256 internal constant ICO_END = 1525190399;

     
    uint256 internal constant ICO_RATE1 = 20000;
    uint256 internal constant ICO_RATE2 = 18000;
    uint256 internal constant ICO_RATE3 = 17000;
    uint256 internal constant ICO_RATE4 = 16000;

     
     
     
     
    uint256 internal constant ICO_CAP1 = 14000 * (10 ** 18);
    uint256 internal constant ICO_CAP2 = 21000 * (10 ** 18);
    uint256 internal constant ICO_CAP3 = 28000 * (10 ** 18);
    uint256 internal constant ICO_CAP4 = 35000 * (10 ** 18);

     
    uint256 internal constant MIN_CAP = (10 ** 17);
    uint256 internal constant MAX_CAP = 1000 * (10 ** 18);

     
    address internal owner;

     
    ERC20 public tokenReward;

     
    address internal tokenOwner;

     
    address internal wallet;

     
    uint256 public stage = 0;

     
    uint256 public tokensSold = 0;

     
    uint256 public weiRaised = 0;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    event IcoStageStarted(uint256 stage);
    event IcoEnded();

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function MplusCrowdsaleA(address _tokenAddress, address _wallet) public {
        require(_tokenAddress != address(0));
        require(_wallet != address(0));

        owner = msg.sender;
        tokenOwner = msg.sender;
        wallet = _wallet;

        tokenReward = ERC20(_tokenAddress);
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {
        require(_beneficiary != address(0));
        require(msg.value >= MIN_CAP);
        require(msg.value <= MAX_CAP);
        require(now >= ICO_START1);
        require(now <= ICO_END);
        require(stage <= NUM_STAGES);

        determineCurrentStage();

        uint256 weiAmount = msg.value;

         
        uint256 tokens = getTokenAmount(weiAmount);
        require(tokens > 0);

         
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);
        checkCap();

        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        require(tokenReward.transferFrom(tokenOwner, _beneficiary, tokens));
        forwardFunds();
    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function determineCurrentStage() internal {
        if (stage < 4 && now >= ICO_START4) {
            stage = 4;
            IcoStageStarted(4);
        } else if (stage < 3 && now >= ICO_START3) {
            stage = 3;
            IcoStageStarted(3);
        } else if (stage < 2 && now >= ICO_START2) {
            stage = 2;
            IcoStageStarted(2);
        } else if (stage < 1 && now >= ICO_START1) {
            stage = 1;
            IcoStageStarted(1);
        }
    }

     
    function checkCap() internal {
        if (weiRaised >= ICO_CAP4) {
            stage = 5;
            IcoEnded();
        } else if (stage < 4 && weiRaised >= ICO_CAP3) {
            stage = 4;
            IcoStageStarted(4);
        } else if (stage < 3 && weiRaised >= ICO_CAP2) {
            stage = 3;
            IcoStageStarted(3);
        } else if (stage < 2 && weiRaised >= ICO_CAP1) {
            stage = 2;
            IcoStageStarted(2);
        }
    }

     
    function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 rate = 0;

        if (stage == 1) {
            rate = ICO_RATE1;
        } else if (stage == 2) {
            rate = ICO_RATE2;
        } else if (stage == 3) {
            rate = ICO_RATE3;
        } else if (stage == 4) {
            rate = ICO_RATE4;
        }

        return rate.mul(_weiAmount);
    }
}