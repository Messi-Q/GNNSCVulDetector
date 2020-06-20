pragma solidity ^0.4.2;

 
 

contract AbstractToken {
     
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Issuance(address indexed to, uint256 value);
}

contract StandardToken is AbstractToken {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}


 
 
contract HumaniqToken is StandardToken {

     
    address public emissionContractAddress = 0x0;

     
    string constant public name = "HumaniQ";
    string constant public symbol = "HMQ";
    uint8 constant public decimals = 8;

    address public founder = 0x0;
    bool locked = true;
     
    modifier onlyFounder() {
         
        if (msg.sender != founder) {
            throw;
        }
        _;
    }

    modifier isCrowdfundingContract() {
         
        if (msg.sender != emissionContractAddress) {
            throw;
        }
        _;
    }

    modifier unlocked() {
         
        if (locked == true) {
            throw;
        }
        _;
    }

     

     
     
     
    function issueTokens(address _for, uint tokenCount)
        external
        payable
        isCrowdfundingContract
        returns (bool)
    {
        if (tokenCount == 0) {
            return false;
        }
        balances[_for] += tokenCount;
        totalSupply += tokenCount;
        Issuance(_for, tokenCount);
        return true;
    }

    function transfer(address _to, uint256 _value)
        unlocked
        returns (bool success)
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
        unlocked
        returns (bool success)
    {
        return super.transferFrom(_from, _to, _value);
    }

     
     
    function changeEmissionContractAddress(address newAddress)
        external
        onlyFounder
        returns (bool)
    {
        emissionContractAddress = newAddress;
    }

     
     
    function lock(bool value)
        external
        onlyFounder
    {
        locked = value;
    }

     
     
    function HumaniqToken(address _founder)
    {
        totalSupply = 0;
        founder = _founder;
    }
}


 
 
contract HumaniqICO {

     
    HumaniqToken public humaniqToken;

     
    uint constant public CROWDFUNDING_PERIOD = 3 weeks;

     
    address public founder;
    address public multisig;
    uint public startDate = 0;
    uint public icoBalance = 0;
    uint public coinsIssued = 0;
    uint public baseTokenPrice = 1 finney;  
    uint public discountedPrice = baseTokenPrice;
    bool public isICOActive = false;

     
    mapping (address => uint) public investments;

     
    modifier onlyFounder() {
         
        if (msg.sender != founder) {
            throw;
        }
        _;
    }

    modifier minInvestment() {
         
        if (msg.value < baseTokenPrice) {
            throw;
        }
        _;
    }

    modifier icoActive() {
        if (isICOActive == false) {
            throw;
        }
        _;
    }

     
    function getCurrentBonus()
        public
        constant
        returns (uint)
    {
        return getBonus(now);
    }

     
     
    function getBonus(uint timestamp)
        public
        constant
        returns (uint)
    {

        if (startDate == 0) {
            return 1499;  
        }

        uint icoDuration = timestamp - startDate;
        if (icoDuration >= 16 days) {
            return 1000;   
        } else if (icoDuration >= 9 days) {
            return 1125;   
        } else if (icoDuration >= 2 days) {
            return 1250;   
        } else {
            return 1499;   
        }
    }

    function calculateTokens(uint investment, uint timestamp)
        public
        constant
        returns (uint)
    {
         
        discountedPrice = (baseTokenPrice * 1000) / getBonus(timestamp);

         
        return investment / discountedPrice;
    }

     
     
     
     
     
    function issueTokens(address beneficiary, uint investment, uint timestamp, bool sendToFounders)
        private
        returns (uint)
    {
        uint tokenCount = calculateTokens(investment, timestamp);

         
        uint roundedInvestment = tokenCount * discountedPrice;

         
        if (sendToFounders && investment > roundedInvestment && !beneficiary.send(investment - roundedInvestment)) {
            throw;
        }

         
        icoBalance += investment;
        coinsIssued += tokenCount;
        investments[beneficiary] += roundedInvestment;

         
        if (sendToFounders && !multisig.send(roundedInvestment)) {
             
            throw;
        }

        if (!humaniqToken.issueTokens(beneficiary, tokenCount)) {
             
            throw;
        }

        return tokenCount;
    }

     
     
    function fund()
        public
        icoActive
        minInvestment
        payable
        returns (uint)
    {
        return issueTokens(msg.sender, msg.value, now, true);
    }

     
     
     
     
    function fixInvestment(address beneficiary, uint investment, uint timestamp)
        external
        icoActive
        onlyFounder
        returns (uint)
    {
        if (timestamp == 0) {
            return issueTokens(beneficiary, investment, now, false);
        }

        return issueTokens(beneficiary, investment, timestamp, false);
    }

     
     
    function finishCrowdsale()
        external
        onlyFounder
        returns (bool)
    {
        if (isICOActive == true) {
            isICOActive = false;
             
             uint founderBonus = (coinsIssued * 14) / 86;
             if (!humaniqToken.issueTokens(multisig, founderBonus)) {
                  
                 throw;
             }
        }
    }

     
     
    function changeBaseTokenPrice(uint valueInWei)
        external
        onlyFounder
        returns (bool)
    {
        baseTokenPrice = valueInWei;
        return true;
    }

    function changeTokenAddress(address token_address) 
        public
        onlyFounder
    {
         humaniqToken = HumaniqToken(token_address);
    }

    function changeFounder(address _founder) 
        public
        onlyFounder
    {
        founder = _founder;
    }

     
    function startICO()
        external
        onlyFounder
    {
        if (isICOActive == false && startDate == 0) {
           
          isICOActive = true;
           
          startDate = now;
        }
    }

     
    function HumaniqICO(address _founder, address _multisig, address token_address) {
         
        founder = _founder;
         
        multisig = _multisig;
         
        humaniqToken = HumaniqToken(token_address);
    }

     
    function () payable {
        fund();
    }
}