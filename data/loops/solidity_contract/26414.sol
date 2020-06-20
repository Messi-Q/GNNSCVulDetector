pragma solidity 0.4.19;
 

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

contract FiatContract {
 
  function USD(uint _id) constant returns (uint256);

}

contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

}

 
contract admined {  
    address public admin;  

     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

    
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        require(_newAdmin != address(0));
        admin = _newAdmin;
        TransferAdminship(admin);
    }

    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

contract ICO is admined{
    using SafeMath for uint256;
     
    enum State {
        Sale,
        Successful
    }
     
    State public state = State.Sale;  
    uint256 public startTime = now;  
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public completedAt;  
    token public tokenReward;  
    address public creator;  
    string public campaignUrl;  
    string public version = '1';

    FiatContract price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);  
     

    uint256 remanent;

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        string _url);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }
     
    function ICO (string _campaignUrl, token _addressOfTokenUsedAsReward) public {
        creator = msg.sender;
        campaignUrl = _campaignUrl;
        tokenReward = token(_addressOfTokenUsedAsReward);

        LogFunderInitialized(
            creator,
            campaignUrl
            );
    }

     
    function contribute() public notFinished payable {

        uint256 tokenBought;  
        uint256 tokenPrice = price.USD(0);  

        tokenPrice = tokenPrice.div(10 ** 8);
        totalRaised = totalRaised.add(msg.value);  

        tokenBought = msg.value.div(tokenPrice);
        tokenBought = tokenBought.mul(10 **10);
        
        totalDistributed = totalDistributed.add(tokenBought);
        
        tokenReward.transfer(msg.sender,tokenBought);
        
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender,tokenBought);
    }

    function finishFunding() onlyAdmin public {

        state = State.Successful;  
        completedAt = now;  
        LogFundingSuccessful(totalRaised);  
        claimTokens();
        claimEth();
            
    }

    function claimTokens() onlyAdmin public{

        remanent = tokenReward.balanceOf(this);
        tokenReward.transfer(msg.sender,remanent);
        
        LogContributorsPayout(msg.sender,remanent);
    }

    function claimEth() onlyAdmin public {  
        
        require(msg.sender.send(this.balance));

        LogBeneficiaryPaid(msg.sender);
        
    }

     

    function () public payable {
        contribute();
    }
}