pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 



 
 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
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


 
 
 
 
contract CorrentlyInvest is ERC20Interface, Owned {


    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    bool public mintable;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event MintingDisabled();


     
     
     
    constructor() public {
        symbol = "CORI";
        name = "Corrently Invest";
        decimals = 2;
        mintable = true;
    }


     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


     
     
     
    function disableMinting() public onlyOwner {
        require(mintable);
        mintable = false;
        emit MintingDisabled();
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] -= tokens;
        require( balances[to]+tokens >=  balances[to]);
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        require( balances[to]+tokens >=  balances[to]);
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


     
     
     
    function mint(address tokenOwner, uint tokens) public onlyOwner returns (bool success) {
        require(mintable);
        require( balances[tokenOwner]+tokens >=  balances[tokenOwner]);
        balances[tokenOwner] += tokens;
        require(_totalSupply+tokens>=_totalSupply);
        _totalSupply += tokens;

        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }


     
     
     
    function ()  external  {
         revert();
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract exD is  Owned {

    ERC20Interface public token;

    uint public totalDividend = 0;
    uint public totalSupply = 0;
    uint public divMultiplier =0;
    uint public totalClaimed=0;

    mapping(address => uint) claimed;
    event Dividend(uint _value);
    event Payed(address account,uint _value);
    event Withdraw(uint _value);
    
     
     
     
    constructor(ERC20Interface _token) public {
        token=_token;
    }


    function balanceOf(address _account) public view returns (uint) {
        return (token.balanceOf(_account)*divMultiplier)-claimed[_account];
    }
    
     
     
     
    function withdrawDividend() payable public {
        uint due=(token.balanceOf(msg.sender)*divMultiplier)-claimed[msg.sender];
        if(due+claimed[msg.sender]<claimed[msg.sender]) revert();        
        claimed[msg.sender]+=due;
        totalClaimed+=due;
        msg.sender.transfer(due);
        emit Payed(msg.sender,due);
    }
    
    function withdrawBonds(uint value) onlyOwner public {
        totalDividend-=value;
        owner.transfer(value);
        emit Withdraw(value);
    }
    
     
     
     
    function () public payable  {
      if(msg.value<1) revert();
      if(totalDividend+msg.value<totalDividend) revert();
      if(token.totalSupply()+totalSupply<totalSupply) revert();
      totalDividend+=msg.value;
      totalSupply+=token.totalSupply();
      divMultiplier=totalDividend/totalSupply;
      emit Dividend(msg.value);
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}