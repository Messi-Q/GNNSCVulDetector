pragma solidity ^0.4.24;

 



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

    constructor() internal {
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



 
 
 
 
 



contract ESS is Ownable {

     
    using SafeMath for uint256;

    uint256 public tokenPrice=0;
    address public addrFWD;
    address public token;
    uint256 public decimals=18;
    string public name="ESS PUBLIC ENGAGEMENT";

    mapping (address => uint256) public sold;

    uint256 public pubEnd=0;
     
    uint256 public tokenUnit = uint256(10)**decimals;



     
     
     


    constructor
        (
        address destAddr,
        address mastTokCon
        ) public {
        addrFWD = destAddr;
        token = mastTokCon;
    }



    function () public payable {
        buy();    
    }



    function setPrice(uint256 _value) public onlyOwner{
      tokenPrice=_value;    

    }

    function setaddrFWD(address _value) public onlyOwner{
      addrFWD=_value;    

    }

    function setPubEnd(uint256 _value) public onlyOwner{
      pubEnd=_value;    

    }



    function buy()  public payable {
        require(block.timestamp<pubEnd);
        require(msg.value>0);
        uint256 tokenAmount = (msg.value * tokenUnit) / tokenPrice ;   

        transferBuy(msg.sender, tokenAmount);
        addrFWD.transfer(msg.value);
    }



    function withdrawPUB() public returns(bool){
        require(block.timestamp>pubEnd);    
        require(sold[msg.sender]>0);


        bool result=token.call(bytes4(keccak256("transfer(address,uint256)")), msg.sender, sold[msg.sender]);
        delete sold[msg.sender];
        return result;
    }



    function transferBuy(address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));

        sold[_to]=sold[_to].add(_value);    

        return true;

    }
}