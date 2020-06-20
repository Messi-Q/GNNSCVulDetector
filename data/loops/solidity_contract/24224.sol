pragma solidity 0.4.20;
 

 
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

    function balanceOf(address _owner) public constant returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool success);

    }

contract ICO {
    using SafeMath for uint256;
     
    enum State {
        preico,
        week1,
        week2,
        week3,
        week4,
        week5,
        week6,
        week7,
        Successful
    }
     
    State public state = State.preico;  
    uint256 public startTime = now;  
    uint256 public rate;
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public totalContributors;
    uint256 public ICOdeadline;
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
        string _url,
        uint256 _ICOdeadline);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }
     
    function ICO (
        string _campaignUrl,
        token _addressOfTokenUsedAsReward) public {
        require(_addressOfTokenUsedAsReward!=address(0));

        creator = msg.sender;
        campaignUrl = _campaignUrl;
        tokenReward = _addressOfTokenUsedAsReward;
        rate = 3000;
        ICOdeadline = startTime.add(64 days);  

        LogFunderInitialized(
            creator,
            campaignUrl,
            ICOdeadline);
    }

     
    function contribute() public notFinished payable {

        uint256 tokenBought = 0;

        totalRaised = totalRaised.add(msg.value);
        totalContributors = totalContributors.add(1);

        tokenBought = msg.value.mul(rate);

         
        if (state == State.preico){

            tokenBought = tokenBought.mul(14);
            tokenBought = tokenBought.div(10);  
        
        } else if (state == State.week1){

            tokenBought = tokenBought.mul(13);
            tokenBought = tokenBought.div(10);  

        } else if (state == State.week2){

            tokenBought = tokenBought.mul(125);
            tokenBought = tokenBought.div(100);  

        } else if (state == State.week3){

            tokenBought = tokenBought.mul(12);
            tokenBought = tokenBought.div(10);  

        } else if (state == State.week4){

            tokenBought = tokenBought.mul(115);
            tokenBought = tokenBought.div(100);  

        } else if (state == State.week5){

            tokenBought = tokenBought.mul(11);
            tokenBought = tokenBought.div(10);  

        } else if (state == State.week6){

            tokenBought = tokenBought.mul(105);
            tokenBought = tokenBought.div(100);  

        }

        totalDistributed = totalDistributed.add(tokenBought);
        
        require(creator.send(msg.value));
        tokenReward.transfer(msg.sender, tokenBought);

        LogBeneficiaryPaid(creator);
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenBought);
        
        checkIfFundingCompleteOrExpired();
    }

     
    function checkIfFundingCompleteOrExpired() public {

        if(state == State.preico && now > startTime.add(14 days)){

            state = State.week1;

        } else if(state == State.week1 && now > startTime.add(21 days)){

            state = State.week2;
            
        } else if(state == State.week2 && now > startTime.add(28 days)){

            state = State.week3;
            
        } else if(state == State.week3 && now > startTime.add(35 days)){

            state = State.week4;
            
        } else if(state == State.week4 && now > startTime.add(42 days)){

            state = State.week5;
            
        } else if(state == State.week5 && now > startTime.add(49 days)){

            state = State.week6;
            
        } else if(state == State.week6 && now > startTime.add(56 days)){

            state = State.week7;
            
        } else if(now > ICOdeadline && state!=State.Successful ) {  

            state = State.Successful;  
            completedAt = now;  

            LogFundingSuccessful(totalRaised);  
            finished();  
        }
    }

     
    function finished() public {  

        require(state == State.Successful);
        uint256 remanent = tokenReward.balanceOf(this);

        tokenReward.transfer(creator,remanent);
        LogContributorsPayout(creator, remanent);

    }

     

    function () public payable {
        
        contribute();

    }
}