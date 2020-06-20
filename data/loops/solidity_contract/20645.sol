pragma solidity ^0.4.18;

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
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
    
     function percent(uint256 a,uint256 b) internal  pure returns (uint256){
      return mul(div(a,uint256(100)),b);
    }
  
    function power(uint256 a,uint256 b) internal pure returns (uint256){
      return mul(a,10**b);
    }
}


 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract RDOToken is StandardToken {
    string public name = "RDO roken";
    string public symbol = "RDO";
    uint256 public decimals = 8;
    address owner;
    address crowdsale;
    
    event Burn(address indexed burner, uint256 value);

    function RDOToken() public {
        owner=msg.sender;
        uint256 initialTotalSupply=1000000000;
        totalSupply=initialTotalSupply.power(decimals);
        balances[msg.sender]=totalSupply;
        
        crowdsale=new RDOCrowdsale(this,msg.sender);
        allocate(crowdsale,75); 
        allocate(0x523f6034c79915cE9AacD06867721D444c45a6a5,12); 
        allocate(0x50d0a8eDe1548E87E5f8103b89626bC9C76fe2f8,7); 
        allocate(0xD8889ff86b9454559979Aa20bb3b41527AE4b74b,3); 
        allocate(0x5F900841910baaC70e8b736632600c409Af05bf8,3); 
        
    }

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }


    function allocate(address _address,uint256 percent) private{
        uint256 bal=totalSupply.percent(percent);
        transfer(_address,bal);
    }
     
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    
    function stopCrowdfunding() onlyOwner public {
        if(crowdsale!=0x0){
            RDOCrowdsale(crowdsale).stopCrowdsale();
            crowdsale=0x0;
        }
    }
    
    function getCrowdsaleAddress() constant public returns(address){
        return crowdsale;
    }
}

 
contract RDOCrowdsale {
    using SafeMath for uint256;

     
    RDOToken public token;

     
    address public wallet;

     
    address public owners;

    
     
    uint256 public price=0.55 finney;

     
    mapping (uint => Phase) phases;

     
    uint public totalPhases = 9;

     
    struct Phase {
        uint256 startTime;
        uint256 endTime;
        uint256 bonusPercent;
    }

     
    BonusValue[] bonusValue;

    struct BonusValue{
        uint256 minimum;
        uint256 maximum;
        uint256 bonus;
    }
    
     
    uint256 public constant minContribution = 100 finney;


     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 bonusPercent, uint256 amount);

     
    event WalletSet(address indexed wallet);

    function RDOCrowdsale(address _tokenAddress, address _wallet) public {
        require(_tokenAddress != address(0));
        token = RDOToken(_tokenAddress);
        wallet = _wallet;
        owners=msg.sender;
        
         
        
        fillPhase(0,40,25 days);
        fillPhase(1,30,15 days);
        fillPhase(2,25,15 days);
        fillPhase(3,20,15 days);
        fillPhase(4,15,15 days);
        fillPhase(5,10,15 days);
        fillPhase(6,7,15 days);
        fillPhase(7,5,15 days);
        fillPhase(8,3,15 days);
        
         
        bonusValue.push(BonusValue({
            minimum:5 ether,
            maximum:25 ether,
            bonus:5
        }));
        bonusValue.push(BonusValue({
            minimum:26 ether,
            maximum:100 ether,
            bonus:8
        }));
        bonusValue.push(BonusValue({
            minimum:101 ether,
            maximum:100000 ether,
            bonus:10
        }));
    }
    
    function fillPhase(uint8 index,uint256 bonus,uint256 delay) private{
        phases[index].bonusPercent=bonus;
        if(index==0){
            phases[index].startTime = now;
        }
        else{
            phases[index].startTime = phases[index-1].endTime;
        }
        phases[index].endTime = phases[index].startTime+delay;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(msg.value != 0);

        uint256 currentBonusPercent = getBonusPercent(now);
        uint256 weiAmount = msg.value;
        uint256 volumeBonus=getVolumeBonus(weiAmount);
        
        require(weiAmount>=minContribution);

         
        uint256 tokens = calculateTokenAmount(weiAmount, currentBonusPercent,volumeBonus);

         
        weiRaised = weiRaised.add(weiAmount);

        token.transfer(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, currentBonusPercent, tokens);

        forwardFunds();
    }

    function getVolumeBonus(uint256 _wei) private view returns(uint256){
        for(uint256 i=0;i<bonusValue.length;++i){
            if(_wei>bonusValue[i].minimum && _wei<bonusValue[i].maximum){
                return bonusValue[i].bonus;
            }
        }
        return 0;
    }
    
     
     
    function getBonusPercent(uint256 datetime) private view returns (uint256) {
        for (uint i = 0; i < totalPhases; i++) {
            if (datetime >= phases[i].startTime && datetime <= phases[i].endTime) {
                return phases[i].bonusPercent;
            }
        }
        return 0;
    }

     
    modifier onlyOwner() {
        require(owners==msg.sender);
        _;
    }

     
     
    function calculateTokenAmount(uint256 _weiDeposit, uint256 _bonusTokensPercent,uint256 _volumeBonus) private view returns (uint256) {
        uint256 mainTokens = _weiDeposit.div(price);
        uint256 bonusTokens = mainTokens.percent(_bonusTokensPercent);
        uint256 volumeBonus=mainTokens.percent(_volumeBonus);
        return mainTokens.add(bonusTokens).add(volumeBonus);
    }

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function stopCrowdsale() public {
        token.burn(token.balanceOf(this));
        selfdestruct(wallet);
    }
    
    function getCurrentBonus() public constant returns(uint256){
        return getBonusPercent(now);
    }
    
    function calculateEstimateToken(uint256 _wei) public constant returns(uint256){
        uint256 timeBonus=getCurrentBonus();
        uint256 volumeBonus=getVolumeBonus(_wei);
        return calculateTokenAmount(_wei,timeBonus,volumeBonus);
    }
}