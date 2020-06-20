pragma solidity ^0.4.21;


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

     
    function rescueTokens(ERC20Basic _token) external onlyOwner {
        uint256 balance = _token.balanceOf(this);
        assert(_token.transfer(owner, balance));
    }

     
    function withdrawEther() external onlyOwner {
        owner.transfer(address(this).balance);
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

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}


 
contract SellERC20BasicTokens is Ownable {
    using SafeMath for uint256;

     
    ERC20Basic public token;
    uint256 etherDecimals = 18;
    uint256 tokenDecimals;
    uint256 decimalDiff;

     
    uint256 public etherMinimum;

     
    uint256 public rate;
    uint256 public depositRate;

     
    uint256 public deposit;
    
     
    address public wallet;


     
    constructor(ERC20Basic _token, uint256 _tokenDecimals, uint256 _etherMinimum, uint256 _rate, uint256 _depositRate, address _wallet) public {
        token = _token;
        tokenDecimals = _tokenDecimals;
        decimalDiff = etherDecimals.sub(_tokenDecimals);
        etherMinimum = _etherMinimum;
        rate = _rate;
        depositRate = _depositRate;
        wallet = _wallet;
    }

     
    function () public payable {
         
        uint256 weiAmount = msg.value;
        require(weiAmount >= etherMinimum.mul(10 ** etherDecimals));

         
        uint256 balance = token.balanceOf(address(this));
        uint256 onsale = balance.sub(deposit);
        require(onsale > 0);

         
        uint256 tokenBought = weiAmount.mul(rate).div(10 ** decimalDiff);
        uint256 tokenDeposit = weiAmount.mul(depositRate).div(10 ** decimalDiff);
        uint256 tokenAmount = tokenBought.add(tokenDeposit);
        require(tokenAmount > 0);

         
        if (tokenAmount <= onsale) {
            assert(token.transfer(msg.sender, tokenBought));
        } else {
            uint256 weiExpense = onsale.div(rate + depositRate);
            tokenBought = weiExpense.mul(rate);
            tokenDeposit = onsale.sub(tokenBought);

             
            assert(token.transfer(msg.sender, tokenBought));

             
            msg.sender.transfer(weiAmount - weiExpense.mul(10 ** decimalDiff));
        }

         
        deposit = deposit.add(tokenDeposit);

         
        onsale = token.balanceOf(address(this)).sub(deposit);

         
        owner.transfer(address(this).balance);
    }

     
    function sendToken(address _receiver, uint256 _amount) external {
        require(msg.sender == wallet);
        require(_amount <= deposit);
        assert(token.transfer(_receiver, _amount));
        deposit = deposit.sub(_amount);
    }

     
    function setRate(uint256 _rate, uint256 _depositRate) external onlyOwner {
        rate = _rate;
        depositRate = _depositRate;
    }

     
    function setWallet(address _wallet) external onlyOwner {
        wallet = _wallet;
    }
}