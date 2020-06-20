pragma solidity ^0.4.18;
 

 
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
}

contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

    }

contract ICO {
    using SafeMath for uint256;
     
    enum State {
        EarlyPreSale,
        PreSale,
        Crowdsale,
        Successful
    }
     
    State public state = State.EarlyPreSale;  
    uint256 public startTime = now;  
    uint256[2] public price = [6667,5000];  
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public stageDistributed;  
    uint256 public completedAt;  
    token public tokenReward;  
    address public creator;  
    string public campaignUrl;  
    string public version = '1';

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        string _url);
    event LogContributorsPayout(address _addr, uint _amount);
    event StageDistributed(State _stage, uint256 _stageDistributed);

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

        require(msg.value >= 100 finney);

        uint256 tokenBought;  
        totalRaised = totalRaised.add(msg.value);  

        if (state == State.EarlyPreSale){

            tokenBought = msg.value.mul(price[0]);  
            tokenBought = tokenBought.mul(12);  
            tokenBought = tokenBought.div(10);  
            
            require(stageDistributed.add(tokenBought) <= 60000000 * (10 ** 18));  

        } else if (state == State.PreSale){

            tokenBought = msg.value.mul(price[0]);  
            tokenBought = tokenBought.mul(11);  
            tokenBought = tokenBought.div(10);  
            
            require(stageDistributed.add(tokenBought) <= 60000000 * (10 ** 18));  

        } else if (state == State.Crowdsale){

            tokenBought = msg.value.mul(price[1]);  

            require(stageDistributed.add(tokenBought) <= 80000000 * (10 ** 18));  

        }

        totalDistributed = totalDistributed.add(tokenBought);
        stageDistributed = stageDistributed.add(tokenBought);
        
        tokenReward.transfer(msg.sender, tokenBought);
        
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenBought);
        
        checkIfFundingCompleteOrExpired();
    }

     
    function checkIfFundingCompleteOrExpired() public {
        
        if(state!=State.Successful){  
            
            if(state == State.EarlyPreSale && now > startTime.add(8 days)){

                StageDistributed(state,stageDistributed);

                state = State.PreSale;
                stageDistributed = 0;
            
            } else if(state == State.PreSale && now > startTime.add(15 days)){

                StageDistributed(state,stageDistributed);

                state = State.Crowdsale;
                stageDistributed = 0;

            } else if(state == State.Crowdsale && now > startTime.add(36 days)){

                StageDistributed(state,stageDistributed);

                state = State.Successful;  
                completedAt = now;  
                LogFundingSuccessful(totalRaised);  
                finished();  
            
            }
        }
    }

     
    function finished() public {  
        require(state == State.Successful);
        uint256 remanent = tokenReward.balanceOf(this);

        require(creator.send(this.balance));
        tokenReward.transfer(creator,remanent);

        LogBeneficiaryPaid(creator);
        LogContributorsPayout(creator, remanent);
    }

     

    function () public payable {
        contribute();
    }
}