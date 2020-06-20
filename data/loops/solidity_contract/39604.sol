pragma solidity ^0.4.6;

contract StandardToken {

     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
     
     
     
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


 
 
contract TokenFund is StandardToken {

     
    address public emissionContractAddress = 0x0;

     
    string constant public name = "TheToken Fund";
    string constant public symbol = "TKN";
    uint8 constant public decimals = 8;

     
    address public owner = 0x0;
    bool public emissionEnabled = true;
    bool transfersEnabled = true;

     

    modifier isCrowdfundingContract() {
         
        if (msg.sender != emissionContractAddress) {
            throw;
        }
        _;
    }

    modifier onlyOwner() {
         
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

     

      
     
     
    function issueTokens(address _for, uint tokenCount)
        external
        isCrowdfundingContract
        returns (bool)
    {
        if (emissionEnabled == false) {
            throw;
        }

        balances[_for] += tokenCount;
        totalSupply += tokenCount;
        return true;
    }

     
     
    function withdrawTokens(uint tokenCount)
        public
        returns (bool)
    {
        uint balance = balances[msg.sender];
        if (balance < tokenCount) {
            return false;
        }
        balances[msg.sender] -= tokenCount;
        totalSupply -= tokenCount;
        return true;
    }

     
     
    function changeEmissionContractAddress(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        emissionContractAddress = newAddress;
    }

     
     
    function enableTransfers(bool value)
        external
        onlyOwner
    {
        transfersEnabled = value;
    }

     
     
    function enableEmission(bool value)
        external
        onlyOwner
    {
        emissionEnabled = value;
    }

     
    function transfer(address _to, uint256 _value)
        returns (bool success)
    {
        if (transfersEnabled == true) {
            return super.transfer(_to, _value);
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        returns (bool success)
    {
        if (transfersEnabled == true) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }


     
     
    function TokenFund(address _owner)
    {
        totalSupply = 0;
        owner = _owner;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract Fund is owned {

	 
    TokenFund public tokenFund;

	 
    address public ethAddress;
    address public multisig;
    address public supportAddress;
    uint public tokenPrice = 1 finney;  

    mapping (address => address) public referrals;

     

	 
     
    function withdrawTokens(uint tokenCount)
        public
        returns (bool)
    {
        return tokenFund.withdrawTokens(tokenCount);
    }

    function issueTokens(address _for, uint tokenCount)
    	private
    	returns (bool)
    {
    	if (tokenCount == 0) {
        return false;
      }

      var percent = tokenCount / 100;

       
      if (!tokenFund.issueTokens(multisig, percent)) {
         
        throw;
      }

		   
      if (!tokenFund.issueTokens(supportAddress, percent)) {
         
        throw;
      }

      if (referrals[_for] != 0) {
      	 
      	if (!tokenFund.issueTokens(referrals[_for], 3 * percent)) {
           
          throw;
        }
      } else {
      	 
      	if (!tokenFund.issueTokens(multisig, 3 * percent)) {
           
          throw;
        }
      }

      if (!tokenFund.issueTokens(_for, tokenCount - 5 * percent)) {
         
        throw;
	    }

	    return true;
    }

     
     
     
    function addInvestment(address beneficiary, uint valueInWei)
        external
        onlyOwner
        returns (bool)
    {
        uint tokenCount = calculateTokens(valueInWei);
    	return issueTokens(beneficiary, tokenCount);
    }

     
    function fund()
        public
        payable
        returns (bool)
    {
         
        address beneficiary = msg.sender;
        uint tokenCount = calculateTokens(msg.value);
        uint roundedInvestment = tokenCount * tokenPrice / 100000000;

         
        if (msg.value > roundedInvestment && !beneficiary.send(msg.value - roundedInvestment)) {
          throw;
        }
         
        if (!ethAddress.send(roundedInvestment)) {
          throw;
        }
        return issueTokens(beneficiary, tokenCount);
    }

    function calculateTokens(uint valueInWei)
        public
        constant
        returns (uint)
    {
        return valueInWei * 100000000 / tokenPrice;
    }

    function estimateTokens(uint valueInWei)
        public
        constant
        returns (uint)
    {
        return valueInWei * 95000000 / tokenPrice;
    }

    function setReferral(address client, address referral)
        public
        onlyOwner
    {
        referrals[client] = referral;
    }

    function getReferral(address client)
        public
        constant
        returns (address)
    {
        return referrals[client];
    }

     
     
    function setTokenPrice(uint valueInWei)
        public
        onlyOwner
    {
        tokenPrice = valueInWei;
    }

    function getTokenPrice()
        public
        constant
        returns (uint)
    {
        return tokenPrice;
    }

    function changeMultisig(address newMultisig)
        onlyOwner
    {
        multisig = newMultisig;
    }

    function changeEthAddress(address newEthAddress)
        onlyOwner
    {
        ethAddress = newEthAddress;
    }

     
     
     
     
     
    function Fund(address _owner, address _ethAddress, address _multisig, address _supportAddress, address _tokenAddress)
    {
        owner = _owner;
        ethAddress = _ethAddress;
        multisig = _multisig;
        supportAddress = _supportAddress;
        tokenFund = TokenFund(_tokenAddress);
    }

     
    function () payable {
        fund();
    }
}