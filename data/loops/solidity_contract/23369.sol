pragma solidity 0.4.20;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    function totalSupply()public view returns(uint total_Supply);
    function balanceOf(address who)public view returns(uint256);
    function allowance(address owner, address spender)public view returns(uint);
    function transferFrom(address from, address to, uint value)public returns(bool ok);
    function approve(address spender, uint value)public returns(bool ok);
    function transfer(address to, uint value)public returns(bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract IDMONEY is ERC20
{
    using SafeMath for uint256;
         
        string public constant name = "IDMONEY";

     
    string public constant symbol = "IDM";
    uint8 public constant decimals = 18;
    uint public _totalsupply = 35000000 * 10 ** 18;  
    uint256 constant public _price_tokn = 0.00075 ether;
    uint256 no_of_tokens;
    uint256 bonus_token;
    uint256 total_token;
    uint256 tokensold;
    uint256 public total_token_sold;
    bool stopped = false;
 
    address public owner;
    address superAdmin = 0x1313d38e988526A43Ab79b69d4C94dD16f4c9936;
    address socialOne = 0x52d4bcF6F328492453fAfEfF9d6Eb73D26766Cff;
    address socialTwo = 0xbFe47a096486B564783f261B324e198ad84Fb8DE;
    address founderOne = 0x5AD7cdD7Cd67Fe7EB17768F04425cf35a91587c9;
    address founderTwo = 0xA90ab8B8Cfa553CC75F9d2C24aE7148E44Cd0ABa;
    address founderThree = 0xd2fdE07Ee7cB86AfBE59F4efb9fFC1528418CC0E;
    address storage1 = 0x5E948d1C6f7C76853E43DbF1F01dcea5263011C5;
    
    mapping(address => uint) balances;
    mapping(address => bool) public refund;               
    mapping(address => bool) public whitelisted;          
    mapping(address => uint256) public deposited;         
    mapping(address => uint256) public tokensinvestor;    
    mapping(address => mapping(address => uint)) allowed;

    uint constant public minimumInvestment = 1 ether;  
    uint bonus;
    uint c;
    uint256 lefttokens;

    enum Stages {
        NOTSTARTED,
        ICO,
        PAUSED,
        ENDED
    }
    Stages public stage;

     modifier atStage(Stages _stage) {
        require (stage == _stage);
             
         _;
    }
    
     modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
     modifier onlySuperAdmin() {
        require (msg.sender == superAdmin);
        _;
    }

    function IDMONEY() public
    {
        owner = msg.sender;
        balances[superAdmin] = 2700000 * 10 ** 18;   
        balances[socialOne] = 3500000 * 10 ** 18;   
        balances[socialTwo] = 3500000 * 10 ** 18;   
        balances[founderOne] = 2100000 * 10 ** 18;  
        balances[founderTwo] = 2100000 * 10 ** 18;  
        balances[founderThree] = 2100000 * 10 ** 18;  
        balances[storage1] = 9000000 * 10 ** 18;  
        stage = Stages.NOTSTARTED;
        Transfer(0, superAdmin, balances[superAdmin]);
        Transfer(0, socialOne, balances[socialOne]);
        Transfer(0, socialTwo, balances[socialTwo]);
        Transfer(0, founderOne, balances[founderOne]);
        Transfer(0, founderTwo, balances[founderTwo]);
        Transfer(0, founderThree, balances[founderThree]);
        Transfer(0, storage1, balances[storage1]);
    }

    function () public payable atStage(Stages.ICO)
    {
        require(msg.value >= minimumInvestment);
        require(!stopped && msg.sender != owner);

        no_of_tokens = ((msg.value).div(_price_tokn)).mul(10 ** 18);
        tokensold = (tokensold).add(no_of_tokens);
        deposited[msg.sender] = deposited[msg.sender].add(msg.value);
        bonus = bonuscal();
        bonus_token = ((no_of_tokens).mul(bonus)).div(100);   
        total_token = no_of_tokens + bonus_token;
        total_token_sold = (total_token_sold).add(total_token);
        tokensinvestor[msg.sender] = tokensinvestor[msg.sender].add(total_token);


    }

     
    function bonuscal() private returns(uint)
    {
       
        c = tokensold / 10 ** 23;
        if (c == 0) 
        {
           return  90;

        }
         return (90 - (c * 10));
    }

    function start_ICO() external onlyOwner atStage(Stages.NOTSTARTED)
    {
        stage = Stages.ICO;
        stopped = false;
        balances[address(this)] = 10000000 * 10 ** 18;  
        Transfer(0, address(this), balances[address(this)]);
    }


    function enablerefund(address refundaddress) external onlyOwner
    {
        require(!whitelisted[refundaddress]);
        refund[refundaddress] = true;
    }

     
    function claimrefund(address investor) public
    {
        require(refund[investor]);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        tokensinvestor[investor] = 0;
         
    }

     
    function PauseICO() external onlyOwner atStage(Stages.ICO) {
        stopped = true;
        stage = Stages.PAUSED;
    }

     
    function releaseICO() external onlyOwner atStage(Stages.PAUSED)
    {
        stopped = false;
        stage = Stages.ICO;
    }


    function setWhiteListAddresses(address _investor) external onlyOwner{
        whitelisted[_investor] = true;
    }

     
     
    function claimTokensICO(address receiver) public
     
    {
         
         
        require(whitelisted[receiver]);
        require(tokensinvestor[receiver] > 0);
        uint256 tokensclaim = tokensinvestor[receiver];
        balances[address(this)] = (balances[address(this)]).sub(tokensclaim);
        balances[receiver] = (balances[receiver]).add(tokensclaim);
        tokensinvestor[receiver] = 0;
        Transfer(address(this), receiver, balances[receiver]);
    }

    function end_ICO() external onlySuperAdmin atStage(Stages.ICO)
    {
        stage = Stages.ENDED;
        lefttokens = balances[address(this)];
        balances[superAdmin]=(balances[superAdmin]).add(lefttokens);
        balances[address(this)] = 0;
        Transfer(address(this), superAdmin, lefttokens);

    }

     
    function totalSupply() public view returns(uint256 total_Supply) {
        total_Supply = _totalsupply;
    }

     
    function balanceOf(address _owner)public view returns(uint256 balance) {
        return balances[_owner];
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount)public returns(bool success) {
        require(_to != 0x0);
        require(_amount >= 0);
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

     
     
    function approve(address _spender, uint256 _amount)public returns(bool success) {
        require(_spender != 0x0);
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)public view returns(uint256 remaining) {
        require(_owner != 0x0 && _spender != 0x0);
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _amount)public returns(bool success) {
        require(_to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

 

     
    function transferOwnership(address newOwner)public onlySuperAdmin
    {
        require(newOwner != 0x0);
        owner = newOwner;
    }


    function drain() external onlyOwner {
        superAdmin.transfer(this.balance);
    }

}