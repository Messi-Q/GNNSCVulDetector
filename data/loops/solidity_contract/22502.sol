pragma solidity ^0.4.11;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

 
contract Ownable {
    address public owner;


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

contract MintableToken is StandardToken, Ownable, Pausable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    uint256 public constant maxTokensToMint = 7320000000 ether;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) whenNotPaused onlyOwner returns (bool) {
        return mintInternal(_to, _amount);
    }

     
    function finishMinting() whenNotPaused onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function mintInternal(address _to, uint256 _amount) internal canMint returns (bool) {
        require(totalSupply.add(_amount) <= maxTokensToMint);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(this, _to, _amount);
        return true;
    }
}

contract Avatar is MintableToken {

    string public constant name = "AvataraCoin";

    string public constant symbol = "VTR";

    bool public transferEnabled = false;

    uint8 public constant decimals = 18;

    uint256 public rate = 100000;

    uint256 public constant hardCap = 30000 ether;

    uint256 public weiFounded = 0;

    address public approvedUser = 0x48BAa849622fb4481c0C4D9E7a68bcE6b63b0213;

    address public wallet = 0x48BAa849622fb4481c0C4D9E7a68bcE6b63b0213;

    uint64 public dateStart = 1520348400;

    bool public icoFinished = false;

    uint256 public constant maxTokenToBuy = 4392000000 ether;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);


     
    function transfer(address _to, uint _value) whenNotPaused canTransfer returns (bool) {
        require(_to != address(this) && _to != address(0));
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint _value) whenNotPaused canTransfer returns (bool) {
        require(_to != address(this) && _to != address(0));
        return super.transferFrom(_from, _to, _value);
    }

     
    function approve(address _spender, uint256 _value) whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

     
    modifier canTransfer() {
        require(transferEnabled);
        _;
    }

    modifier onlyOwnerOrApproved() {
        require(msg.sender == owner || msg.sender == approvedUser);
        _;
    }

     
    function enableTransfer() onlyOwner returns (bool) {
        transferEnabled = true;
        return true;
    }

    function finishIco() onlyOwner returns (bool) {
        icoFinished = true;
        return true;
    }

    modifier canBuyTokens() {
        require(!icoFinished && weiFounded <= hardCap);
        _;
    }

    function setApprovedUser(address _user) onlyOwner returns (bool) {
        require(_user != address(0));
        approvedUser = _user;
        return true;
    }


    function changeRate(uint256 _rate) onlyOwnerOrApproved returns (bool) {
        require(_rate > 0);
        rate = _rate;
        return true;
    }

    function () payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) canBuyTokens whenNotPaused payable {
        require(beneficiary != 0x0);
        require(msg.value >= 100 finney);

        uint256 weiAmount = msg.value;
        uint256 bonus = 0;
        uint256 totalWei = weiAmount.add(weiFounded);
        if(totalWei <= 600 ether){
            require(weiAmount >= 1500 finney);
            bonus = 51;
        }else if (totalWei <= 3000 ether){
            require(weiAmount >= 1500 finney);
            bonus = 30;
            if(weiAmount >= 33 ether){
                bonus = 51;
            }
        }else if (totalWei <= 12000 ether){
            require(weiAmount >= 1000 finney);
            bonus = 21;
            if(weiAmount >= 33 ether){
                bonus = 42;
            }
        }else if (totalWei <= 21000 ether){
            require(weiAmount >= 510 finney);
            bonus = 18;
            if(weiAmount >= 33 ether){
                bonus = 39;
            }
        }else if (totalWei <= 30000 ether){
            require(weiAmount >= 300 finney);
            bonus = 12;
            if(weiAmount >= 33 ether){
                bonus = 33;
            }
        }
         

        uint256 tokens = weiAmount.mul(rate);



        if(bonus > 0){
            tokens += tokens.mul(bonus).div(100);
        }

        require(totalSupply.add(tokens) <= maxTokenToBuy);

        mintInternal(beneficiary, tokens);
        weiFounded = totalWei;
        TokenPurchase(msg.sender, beneficiary, tokens);
        forwardFunds();
    }

     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }


    function changeWallet(address _newWallet) onlyOwner returns (bool) {
        require(_newWallet != 0x0);
        wallet = _newWallet;
        return true;
    }

    
}