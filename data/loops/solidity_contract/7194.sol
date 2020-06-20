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


 
contract VNETAirdrop is Ownable {
    using SafeMath for uint256;

     
    ERC20Basic public vnetToken;

     
    string public description;
    
     
    uint256 randNonce = 0;

     
    mapping(address => bool) public airdopped;


     
    constructor(ERC20Basic _vnetToken, string _description) public {
        vnetToken = _vnetToken;
        description = _description;
    }

     
    function () public payable {
        require(airdopped[msg.sender] != true);
        uint256 balance = vnetToken.balanceOf(address(this));
        require(balance > 0);

        uint256 vnetAmount = 100;
        vnetAmount = vnetAmount.add(uint256(keccak256(abi.encode(now, msg.sender, randNonce))) % 100).mul(10 ** 6);
        
        if (vnetAmount <= balance) {
            assert(vnetToken.transfer(msg.sender, vnetAmount));
        } else {
            assert(vnetToken.transfer(msg.sender, balance));
        }

        randNonce = randNonce.add(1);
        airdopped[msg.sender] = true;
    }

     
    function setDescription(string _description) external onlyOwner {
        description = _description;
    }
}