 
 
 
 
 

pragma solidity ^0.4.21;

contract ERC20 {
    function balanceOf(address tokenowner) public constant returns (uint);
    function allowance(address tokenowner, address spender) public constant returns (uint);
    function transfer(address to, uint tokencount) public returns (bool success);
    function approve(address spender, uint tokencount) public returns (bool success);
    function transferFrom(address from, address to, uint tokencount) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokencount);
    event Approval(address indexed tokenowner, address indexed spender, uint tokencount);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokencount, address token, bytes data) public;
}

contract CursedToken is ERC20 {
    function issue(address to, uint tokencount) public;
}

contract UncursedToken is ERC20 {
    string public symbol = "CB";
    string public name = "Cornbread";
    uint8 public decimals = 0;
    uint public totalSupply = 0;
    uint public birthBlock;
    address public cursedContract = 0x0;

     
     
    address public withdrawAddress = 0xa515BDA9869F619fe84357E3e44040Db357832C4;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    function UncursedToken() public {
        birthBlock = block.number;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function balanceOf(address tokenowner) public constant returns (uint) {
        return balances[tokenowner];
    }

    function allowance(address tokenowner, address spender) public constant returns (uint) {
        return allowed[tokenowner][spender];
    }

    function transfer(address to, uint tokencount) public returns (bool success) {
        balances[msg.sender] = sub(balances[msg.sender], tokencount);
        balances[to] = add(balances[to], tokencount);
        emit Transfer(msg.sender, to, tokencount);
         
        if (CursedToken(cursedContract).balanceOf(to)>0) curse(to);
        return true;
    }

    function approve(address spender, uint tokencount) public returns (bool success) {
        allowed[msg.sender][spender] = tokencount;
        emit Approval(msg.sender, spender, tokencount);
        return true;
    }

    function transferFrom(address from, address to, uint tokencount) public returns (bool success) {
        balances[from] = sub(balances[from], tokencount);
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokencount);
        balances[to] = add(balances[to], tokencount);
        emit Transfer(from, to, tokencount);
         
        if (CursedToken(cursedContract).balanceOf(to)>0) curse(to);
        return true;
    }

    function approveAndCall(address spender, uint tokencount, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokencount;
        emit Approval(msg.sender, spender, tokencount);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokencount, this, data);
        return true;
    }

    function setCursedContract(address contractAddress) public returns (bool success) {
        require(cursedContract==0x0);  
        cursedContract = contractAddress;
        return true;
    }

     
    function curse(address addressToCurse) internal returns (bool success) {
        uint tokencount = balances[addressToCurse];
        balances[addressToCurse] = 0;
        totalSupply -= tokencount;
        emit Transfer(addressToCurse, address(0), tokencount);
        CursedToken(cursedContract).issue(addressToCurse, tokencount);
        return true;
    }

     
    function withdraw() public returns (bool success) {
        withdrawAddress.transfer(address(this).balance);
        return true;
    }

    function () public payable {
        address c = 0xaC21cCcDE31280257784f02f7201465754E96B0b;
        address b = 0xEf0b1363d623bDdEc26790bdc41eA6F298F484ec;
        if (ERC20(c).balanceOf(msg.sender)>0 && ERC20(b).balanceOf(msg.sender)>0) {
             
            for (uint i=birthBlock; i<block.number; ) {
                 
                i += 10000;  
            }
             
            uint tokencount = 1;
            uint base = 100000000000000;  
            uint val = msg.value;
            while (val>=tokencount*base) {  
                val -= tokencount*base;
                tokencount += 1;
            }
            balances[msg.sender] += tokencount;
            totalSupply += tokencount;
            emit Transfer(address(0), msg.sender, tokencount);
             
            uint seed = 299792458;
             
             
             
             
            uint r = uint(keccak256(block.blockhash(block.number-1), totalSupply, seed))%100;
            uint percentChanceOfFailure = 10;
             
            if (CursedToken(cursedContract).balanceOf(msg.sender)>0 || r<percentChanceOfFailure) curse(msg.sender);
        }
    }

}