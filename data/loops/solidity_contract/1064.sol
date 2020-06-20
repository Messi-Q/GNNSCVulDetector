pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
 
contract XToken is Owned {
    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
    mapping(address => uint256) balances;

    string public name = "XToken";
    string public symbol = "XT";
    uint8 public decimals = 18;
    uint256 private fee_ = 5;  

    uint256 public totalSupply = 100000000 * (1 ether);
    uint256 public tokenMarketPool = 0;  
    uint256 public poolPrice = 1 finney;


     
     
     
     
    constructor () public {
        balances[msg.sender] = 30000000 * (1 ether);  
        tokenMarketPool = totalSupply.sub(balances[msg.sender]);
    }

     
     
     
     
    function () public payable {
        if (!isContract(msg.sender)) {
            revert("Can not Send Eth directly to this token");
        }
    }

    function buy() public payable {
        uint256 ethAmount = msg.value;
        uint256 taxed = ethAmount.sub(ethAmount.mul(fee_).div(100));
        uint256 tokenAmount = taxed.mul(1 ether).div(poolPrice);

        require(tokenMarketPool >= tokenAmount, "No enough token in market pool");
        tokenMarketPool = tokenMarketPool.sub(tokenAmount);
        balances[msg.sender] = balanceOf(msg.sender).add(tokenAmount);
    }

    function sell(uint256 tokenAmount) public {
        require(balanceOf(msg.sender) >= tokenAmount, "No enough token");
        uint256 sellPrice = getSellPrice();
        uint256 soldEth = tokenAmount.mul(sellPrice).div(1 ether);

        balances[msg.sender] = balanceOf(msg.sender).sub(tokenAmount);
        tokenMarketPool = tokenMarketPool.add(tokenAmount);
        uint256 gotEth = soldEth.sub(soldEth.mul(fee_).div(100));
        msg.sender.transfer(gotEth);
    }

    function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {
        if (isContract(_to)) {
            require(balanceOf(msg.sender) >= _value, "no enough token");
            balances[msg.sender] = balanceOf(msg.sender).sub(_value);
            balances[_to] = balanceOf(_to).add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
     
     
     
    function getShareToken() public view returns (uint256) {
        return totalSupply.sub(tokenMarketPool);
    }

    function getSellPrice() public view returns (uint256) {
        return address(this).balance.mul(1 ether).div(getShareToken());
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
     
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
        require (balanceOf(msg.sender) >= _value, "No Enough Token");
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
        require (balanceOf(msg.sender) >= _value, "No Enough Token");
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
}

 
 
 
 
interface ContractReceiver {
    function tokenFallback(address _from, uint256 _value, bytes _data) external;
}

interface ERC20Interface {
    function transfer(address _to, uint256 _value) external returns (bool);
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