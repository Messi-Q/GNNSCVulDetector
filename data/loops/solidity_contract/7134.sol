pragma solidity 0.4.23;
 

 
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


contract FENIX is ERC20
{
    using SafeMath for uint256;
         
    string public constant name = "FENIX";

     
    string public constant symbol = "FNX";
    uint8 public constant decimals = 18;
    uint public _totalsupply = 1000000000 * 10 ** 18;  
    address public owner;
    uint256 public _price_tokn = 100;   
    uint256 no_of_tokens;
    uint256 total_token;
    bool stopped = false;
    uint256 public ico_startdate;
    uint256 public ico_enddate;
    uint256 public preico_startdate;
    uint256 public preico_enddate;
    bool public icoRunningStatus;
    bool public lockstatus; 
  
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public ethFundMain = 0xBe80a978364649422708470c979435f43e027209;  
    uint256 public ethreceived;
    uint bonusCalculationFactor;
    uint256 public pre_minContribution = 100000; 
    uint256 ContributionAmount;
    address public admin;   
 
 
    uint public priceFactor;
    mapping(address => uint256) availTokens;

    enum Stages {
        NOTSTARTED,
        PREICO,
        ICO,
        ENDED
    }
    Stages public stage;

    modifier atStage(Stages _stage) {
        require (stage == _stage);
        _;
    }

    modifier onlyOwner(){
        require (msg.sender == owner);
     _;
    }

  
    constructor(uint256 EtherPriceFactor) public
    {
        require(EtherPriceFactor != 0);
        owner = msg.sender;
        balances[owner] = 890000000 * 10 ** 18;   
        stage = Stages.NOTSTARTED;
        icoRunningStatus =true;
        lockstatus = true;
        priceFactor = EtherPriceFactor;
        emit Transfer(0, owner, balances[owner]);
    }

    function () public payable
    {
        require(stage != Stages.ENDED);
        require(!stopped && msg.sender != owner);
        if (stage == Stages.PREICO && now <= preico_enddate){
             require((msg.value).mul(priceFactor.mul(100)) >= (pre_minContribution.mul(10 ** 18)));

          y();

    }
    else  if (stage == Stages.ICO && now <= ico_enddate){
  
          _price_tokn= getCurrentTokenPrice();
       
          y();

    }
    else {
        revert();
    }
    }
    
   

  function getCurrentTokenPrice() private returns (uint)
        {
        uint price_tokn;
        bonusCalculationFactor = (block.timestamp.sub(ico_startdate)).div(3600);  
        if (bonusCalculationFactor== 0) 
            price_tokn = 70;                      
        else if (bonusCalculationFactor >= 1 && bonusCalculationFactor < 24) 
            price_tokn = 75;                      
        else if (bonusCalculationFactor >= 24 && bonusCalculationFactor < 168) 
            price_tokn = 80;                       
        else if (bonusCalculationFactor >= 168 && bonusCalculationFactor < 336) 
            price_tokn = 90;                      
        else if (bonusCalculationFactor >= 336) 
            price_tokn = 100;                   
            
            return price_tokn;
     
        }
        
         function y() private {
            
             no_of_tokens = ((msg.value).mul(priceFactor.mul(100))).div(_price_tokn);
             if(_price_tokn >=80){
                 availTokens[msg.sender] = availTokens[msg.sender].add(no_of_tokens);
             }
             ethreceived = ethreceived.add(msg.value);
             balances[address(this)] = (balances[address(this)]).sub(no_of_tokens);
             balances[msg.sender] = balances[msg.sender].add(no_of_tokens);
             emit  Transfer(address(this), msg.sender, no_of_tokens);
    }

   
     
    function StopICO() external onlyOwner  {
        stopped = true;

    }

     
    function releaseICO() external onlyOwner
    {
        stopped = false;

    }
    
     
     function setpricefactor(uint256 newPricefactor) external onlyOwner
    {
        priceFactor = newPricefactor;
        
    }
    
     function setEthmainAddress(address newEthfundaddress) external onlyOwner
    {
        ethFundMain = newEthfundaddress;
    }
    
     function setAdminAddress(address newAdminaddress) external onlyOwner
    {
        admin = newAdminaddress;
    }
    
     function start_PREICO() external onlyOwner atStage(Stages.NOTSTARTED)
      {
          stage = Stages.PREICO;
          stopped = false;
          _price_tokn = 70;      
          balances[address(this)] =10000000 * 10 ** 18 ;  
         preico_startdate = now;
         preico_enddate = now + 7 days;  
       emit Transfer(0, address(this), balances[address(this)]);
          }
    
    function start_ICO() external onlyOwner atStage(Stages.PREICO)
      {
          stage = Stages.ICO;
          stopped = false;
          balances[address(this)] =balances[address(this)].add(100000000 * 10 ** 18);  
         ico_startdate = now;
         ico_enddate = now + 21 days;  
       emit Transfer(0, address(this), 100000000 * 10 ** 18);
          }

    function end_ICO() external onlyOwner atStage(Stages.ICO)
    {
        require(now > ico_enddate);
        stage = Stages.ENDED;
        icoRunningStatus = false;
        uint256 x = balances[address(this)];
        balances[owner] = (balances[owner]).add( balances[address(this)]);
        balances[address(this)] = 0;
       emit  Transfer(address(this), owner , x);
        
    }
    
     
    function fixSpecications(bool RunningStatusICO) external onlyOwner
    {
        icoRunningStatus = RunningStatusICO;
    }
    
     
    function removeLocking(bool RunningStatusLock) external onlyOwner
    {
        lockstatus = RunningStatusLock;
    }


   function balanceDetails(address investor)
        constant
        public
        returns (uint256,uint256)
    {
        return (availTokens[investor], balances[investor]) ;
    }
    
     
    function totalSupply() public view returns(uint256 total_Supply) {
        total_Supply = _totalsupply;
    }

     
    function balanceOf(address _owner)public view returns(uint256 balance) {
        return balances[_owner];
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _amount)public returns(bool success) {
        require(_to != 0x0);
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }

     
     
    function approve(address _spender, uint256 _amount)public returns(bool success) {
        require(_spender != 0x0);
        if (!icoRunningStatus && lockstatus) {
            require(_amount <= availTokens[msg.sender]);
        }
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)public view returns(uint256 remaining) {
        require(_owner != 0x0 && _spender != 0x0);
        return allowed[_owner][_spender];
    }
     
    function transfer(address _to, uint256 _amount) public returns(bool success) {
       
       if ( msg.sender == owner || msg.sender == admin) {
            require(balances[msg.sender] >= _amount && _amount >= 0);
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] += _amount;
            availTokens[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        }
        else
        if (!icoRunningStatus && lockstatus && msg.sender != owner) {
            require(availTokens[msg.sender] >= _amount);
            availTokens[msg.sender] -= _amount;
            balances[msg.sender] -= _amount;
            availTokens[_to] += _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        }

          else if(!lockstatus)
         {
           require(balances[msg.sender] >= _amount && _amount >= 0);
           balances[msg.sender] = (balances[msg.sender]).sub(_amount);
           balances[_to] = (balances[_to]).add(_amount);
           emit Transfer(msg.sender, _to, _amount);
           return true;
          }

        else{
            revert();
        }
    }


     
	function transferOwnership(address newOwner)public onlyOwner
	{
	    require( newOwner != 0x0);
	    balances[newOwner] = (balances[newOwner]).add(balances[owner]);
	    balances[owner] = 0;
	    owner = newOwner;
	    emit Transfer(msg.sender, newOwner, balances[newOwner]);
	}


    function drain() external onlyOwner {
        address myAddress = this;
        ethFundMain.transfer(myAddress.balance);
    }

}