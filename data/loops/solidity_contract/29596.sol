library SafeMath {
  function mul(uint256 a, uint256 b) constant public returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) constant public returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) constant public returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) constant public returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Ownable {
  address public owner;


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    if(msg.sender == owner){
      _;
    }
    else{
      revert();
    }
  }

}
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant public returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    if(!mintingFinished){
      _;
    }
    else{
      revert();
    }
  }

   
  function mint(address _to, uint256 _amount) canMint internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0),_to,_amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


contract MON is MintableToken{
    
    event BuyStatus(uint256 status);
    struct Buy{
        uint256 amountOfEth;
        uint256 stage;
    }
    
	string public constant name = "MillionCoin";
	string public constant symbol = "MON";
	uint256 public constant DECIMALS = 8;
	uint256 public constant decimals = 8;
	address public beneficiary ;
    uint256 private alreadyRunned 	= 0;
    uint256 private _now =0;
    uint256 public stageIndex = 0;
    uint256[] public stageSum;
    uint256[] public stageCurrentSum;
    uint256[] public stagePrice;
    uint256[] public stageEnd;
    uint256 public period = 3600*24;  
    uint256 public start = 0;
    uint256 public sumMultiplayer = 100000;
    mapping(address => Buy) stageBuys;
 
 modifier runOnce(uint256 bit){
     if((alreadyRunned & bit)==0){
        alreadyRunned = alreadyRunned | bit;   
         _;   
     }
     else{
         revert();
     }
 }
 
 
 function MON(address _benef,uint256 _start,uint256 _sumMul,uint256 _period) public{
     beneficiary = _benef;
     start = _start;
     if(_period!=0){
         period = _period;
     }
     if(_sumMul!=0){
         sumMultiplayer = _sumMul;
     }
     stageSum.push(50*sumMultiplayer);
     stageSum.push(60*sumMultiplayer);
     stageSum.push(50*sumMultiplayer);
     stageSum.push(60*sumMultiplayer);
     stageSum.push(65*sumMultiplayer);
     stageSum.push(55*sumMultiplayer);
     stagePrice.push(5000);
     stagePrice.push(3000);
     stagePrice.push(1666);
     stagePrice.push(1500);
     stagePrice.push(1444);
     stagePrice.push(1000);
     stageEnd.push(_start+period*151);
     stageEnd.push(_start+period*243);
     stageEnd.push(_start+period*334);
     stageEnd.push(_start+period*455);
     stageEnd.push(_start+period*548);
     stageEnd.push(_start+period*641);
     stageCurrentSum.push(0);
     stageCurrentSum.push(0);
     stageCurrentSum.push(0);
     stageCurrentSum.push(0);
     stageCurrentSum.push(0);
     stageCurrentSum.push(0);
     
 }
 
 
 function GetMaxStageEthAmount() public constant returns(uint256){
     
     return (stageSum[stageIndex].mul(10**18)).div(stagePrice[stageIndex]);
 }
 
 
 function () public payable {
     uint256  status = 0;
     status = 0;
     bool transferToBenef = false;
     uint256  amountOfEthBeforeBuy = 0;
     uint256  stageMaxEthAmount = 0;
     if(GetNow()<start){
         revert();
     }
     if(this.balance <msg.value){
        amountOfEthBeforeBuy =0 ;
     }
     else{
        amountOfEthBeforeBuy = this.balance - msg.value;
     }
     stageMaxEthAmount = (stageSum[stageIndex].mul(10**18)).div(stagePrice[stageIndex]);
         uint256 amountToReturn =0;
         uint256 amountToMint =0;
         Buy b = stageBuys[msg.sender];
     if(stageEnd[stageIndex]<GetNow() && amountOfEthBeforeBuy<stageMaxEthAmount){
         status = 1;
          
          
         amountToReturn = msg.value;
         if(b.stage==stageIndex){
             amountToReturn = amountToReturn.add(b.amountOfEth);
             burn(msg.sender,b.amountOfEth.mul(stagePrice[stageIndex]));
         }
         stageBuys[msg.sender].amountOfEth=0;
         msg.sender.transfer(amountToReturn);
     }
     else{
         status = 2;
         
         if(b.stage!=stageIndex){
             b.stage = stageIndex;
             b.amountOfEth = 0;
             status = status*10+3;
         }
         
         if(stageEnd[stageIndex]>now &&  this.balance < stageMaxEthAmount){
             
             b.amountOfEth = b.amountOfEth.add(msg.value);
            amountToMint = msg.value.mul(stagePrice[stageIndex]);
            status = status*10+4;
            mintCoins(msg.sender,amountToMint);
         }else{
             if( this.balance >=stageMaxEthAmount){
                  
                status = status*10+5;
                 transferToBenef = true;
                amountToMint = ((stageMaxEthAmount - amountOfEthBeforeBuy).mul(stagePrice[stageIndex]));
                mintCoins(msg.sender,amountToMint);
                stageIndex = stageIndex+1;
                if(stageIndex<5){
                  
                     
                    amountToMint = ((this.balance.sub(stageMaxEthAmount)).mul(stagePrice[stageIndex]));
                    b.stage = stageIndex;
                    b.amountOfEth =(this.balance.sub(stageMaxEthAmount));
                    mintCoins(msg.sender,amountToMint);
                }
                else{
                    status = status*10+8;
                     
                    amountToReturn = (this.balance.sub(stageMaxEthAmount));
                    msg.sender.transfer(amountToReturn);
                }
             }else{
                status = status*10+6;
            
             }
         }
         
     }
     if(transferToBenef){
        beneficiary.transfer(stageMaxEthAmount);
     }
     BuyStatus(status);
 }
 
 function GetNow() public constant returns(uint256){
    return now; 
 }
 
 function GetBalance() public constant returns(uint256){
     return this.balance;
 }

  uint256 public constant maxTokenSupply = (10**(18-DECIMALS))*(10**6)*34 ;  
  
  function burn(address _from, uint256 _amount) private returns (bool){
      _amount = _amount.div(10**10);
      balances[_from] = balances[_from].sub(_amount);
      totalSupply = totalSupply.sub(_amount);
      Transfer(_from,address(0),_amount);
  }
  
  function GetStats()public constant returns (uint256,uint256,uint256,uint256){
      uint256 timeToEnd = 0;
      uint256 round =0;
      if(GetNow()>start){
        round = stageIndex+1;
        timeToEnd = stageEnd[stageIndex]-GetNow();
      }
      else{
        timeToEnd = start-GetNow();
      }
      return(timeToEnd,
       round,
       stageSum[stageIndex].div(stagePrice[stageIndex]).mul(1000),
       GetMaxStageEthAmount().div(10**15));
  }
  
  function mintCoins(address _to, uint256 _amount)  canMint internal returns (bool) {
      
    _amount = _amount.div(10**10);
  	if(totalSupply.add(_amount)<maxTokenSupply){
  	  super.mint(_to,_amount);
  	  super.mint(address(beneficiary),(_amount.mul(20)).div(80));
  	  
  	  return true;
  	}
  	else{
  		return false; 
  	}
  	
  	return true;
  }
  
  
}