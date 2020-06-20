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


 
contract VNETPrivatePlacement is Ownable {
    using SafeMath for uint256;

    ERC20Basic public vnetToken;

    string public description;
    uint256 public rate;
    uint256 public etherMinimum;
    uint256 public etherMaximum;

     
    constructor(ERC20Basic _vnetToken, string _description, uint256 _rate, uint256 _min, uint256 _max) public {
        vnetToken = _vnetToken;
        rate = _rate;
        etherMinimum = _min;
        etherMaximum = _max;
        description = _description;
    }

     
    function () public payable {
         
        uint256 balance = vnetToken.balanceOf(address(this));
        require(balance > 0);
        
         
        uint256 weiAmount = msg.value;
        require(weiAmount >= etherMinimum.mul(10 ** 18));
        require(weiAmount <= etherMaximum.mul(10 ** 18));

         
        uint256 tokenAmount = weiAmount.mul(rate).div(10 ** 12);

         
        if (balance >= tokenAmount) {
            assert(vnetToken.transfer(msg.sender, tokenAmount));
            owner.transfer(address(this).balance);
        } else {
            uint256 expend = balance.div(rate);
            assert(vnetToken.transfer(msg.sender, balance));
            msg.sender.transfer(weiAmount - expend.mul(10 ** 12));
            owner.transfer(address(this).balance);
        }
    }

      
    function sendVNET(address _to, uint256 _amount) external onlyOwner {
        assert(vnetToken.transfer(_to, _amount));
    }

     
    function setDescription(string _description) external onlyOwner {
        description = _description;
    }
    
     
    function setRate(uint256 _rate, uint256 _min, uint256 _max) external onlyOwner {
        rate = _rate;
        etherMinimum = _min;
        etherMaximum = _max;
    }
}