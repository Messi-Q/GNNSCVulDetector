pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 


 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
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

    function Owned() public {
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


 
 
 
 
contract CoinDogToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;

    uint public TotalSupply;
    uint public AmountToDistribute;

    uint256 public sellPrice;
    uint256 public buyPrice;


    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    function CoinDogToken() public {
        symbol = "CDS";
        name = "Coin Dogs Share";
        decimals = 0;
        TotalSupply = 3000000;
        setAmountToDistribute(TotalSupply/3);
        buyPrice = 1000000000000000000/400;
        owner = msg.sender;
        balances[this] = TotalSupply;
        emit Transfer(address(0), this, TotalSupply);
    }


     
     
     
    function totalSupply() public constant returns (uint) {
        return TotalSupply;
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function balanceOfTheContract() public constant returns (uint balance) {
        return balances[this];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


     
     
     
    function () public payable {
        buy();
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }





    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function setAmountToDistribute(uint amount) public onlyOwner {
        AmountToDistribute=amount;
    }

    function sendToken(address to, uint amount) public onlyOwner {
        sendToken_internal(to,amount);
    }

    function DistributedSoFar() public constant returns (uint tokens) {
        return TotalSupply-balances[this];
    }
    

    function sendToken_internal(address to, uint amount) internal {

        require(DistributedSoFar()+amount <= AmountToDistribute);

        balances[this] = safeSub(balances[this], amount);
        balances[to] = safeAdd(balances[to], amount);

        emit Transfer(this, to, amount);
    }

    function distributeTokens(address[] addresses, uint[] values) public onlyOwner {
         require(addresses.length==values.length && values.length>0);
         for (uint i = 0; i < addresses.length; i++) {
            sendToken_internal(addresses[i], values[i]);
         }
    }



    function buy() public payable returns (uint amount)  {
        require(buyPrice>0);

        amount = msg.value / buyPrice;                     

        sendToken_internal(msg.sender, amount);

        return amount;                                     
    }

    function sell(uint amount) public returns (uint revenue) {
        require(sellPrice>0);

        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        balances[this] = safeAdd(balances[this], amount);


        revenue = amount * sellPrice;
        msg.sender.transfer(revenue);                      
        emit Transfer(msg.sender, this, amount);                
        return revenue;                                    
    }




}