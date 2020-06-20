pragma solidity 0.4.24;
 

 
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
}

contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

    }

 
contract admined {
    address public admin;  

     
    constructor() internal {
        admin = 0x6585b849371A40005F9dCda57668C832a5be1777;  
        emit Admined(admin);
    }

     
    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        admin = _newAdmin;
        emit TransferAdminship(admin);
    }

     
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

contract ICO is admined {

    using SafeMath for uint256;
     
    enum State {
        stage1,
        stage2,
        stage3,
        stage4,
        stage5,
        Successful
    }
     
    State public state = State.stage1;  
    uint256 public startTime = now;
    uint256 public stage1Deadline = startTime.add(20 days);
    uint256 public stage2Deadline = stage1Deadline.add(20 days);
    uint256 public stage3Deadline = stage2Deadline.add(20 days);
    uint256 public stage4Deadline = stage3Deadline.add(20 days);
    uint256 public stage5Deadline = stage4Deadline.add(20 days);
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public stageDistributed;
    uint256 public completedAt;
    token public tokenReward;
    address constant public creator = 0x6585b849371A40005F9dCda57668C832a5be1777;
    string public version = '1';
    uint256[5] rates = [2327,1551,1163,931,775];

    mapping (address => address) public refLed;

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(address _creator);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogStageFinish(State _state, uint256 _distributed);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }
     
    constructor (token _addressOfTokenUsedAsReward ) public {

        tokenReward = _addressOfTokenUsedAsReward;

        emit LogFunderInitialized(creator);
    }

     
    function contribute(address _ref) public notFinished payable {

        address referral = _ref;
        uint256 referralBase = 0;
        uint256 referralTokens = 0;
        uint256 tokenBought = 0;

        if(refLed[msg.sender] == 0){  
          refLed[msg.sender] = referral;  
        } else {  
          referral = refLed[msg.sender];  
        }

        totalRaised = totalRaised.add(msg.value);

         
        if (state == State.stage1){

            tokenBought = msg.value.mul(rates[0]);

        } else if (state == State.stage2){

            tokenBought = msg.value.mul(rates[1]);

        } else if (state == State.stage3){

            tokenBought = msg.value.mul(rates[2]);

        } else if (state == State.stage4){

            tokenBought = msg.value.mul(rates[3]);

        } else if (state == State.stage5){

            tokenBought = msg.value.mul(rates[4]);

        }

         
        referralBase = tokenBought;

         
        if(msg.value >= 5 ether ){
          tokenBought = tokenBought.mul(102);
          tokenBought = tokenBought.div(100);  
        }

        totalDistributed = totalDistributed.add(tokenBought);
        stageDistributed = stageDistributed.add(tokenBought);

        tokenReward.transfer(msg.sender, tokenBought);

        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit LogContributorsPayout(msg.sender, tokenBought);


        if (referral != address(0) && referral != msg.sender){

            referralTokens = referralBase.div(20);  
            totalDistributed = totalDistributed.add(referralTokens);
            stageDistributed = stageDistributed.add(referralTokens);

            tokenReward.transfer(referral, referralTokens);

            emit LogContributorsPayout(referral, referralTokens);
        }

        checkIfFundingCompleteOrExpired();
    }

     
    function checkIfFundingCompleteOrExpired() public {

        if(now > stage5Deadline && state!=State.Successful ){  

            emit LogStageFinish(state,stageDistributed);

            state = State.Successful;  
            completedAt = now;  

            emit LogFundingSuccessful(totalRaised);  
            finished();  

        } else if(state == State.stage1 && now > stage1Deadline){

            emit LogStageFinish(state,stageDistributed);

            state = State.stage2;
            stageDistributed = 0;

        } else if(state == State.stage2 && now > stage2Deadline){

            emit LogStageFinish(state,stageDistributed);

            state = State.stage3;
            stageDistributed = 0;

        } else if(state == State.stage3 && now > stage3Deadline){

            emit LogStageFinish(state,stageDistributed);

            state = State.stage4;
            stageDistributed = 0;

        } else if(state == State.stage4 && now > stage4Deadline){

            emit LogStageFinish(state,stageDistributed);

            state = State.stage5;
            stageDistributed = 0;

        }
    }

     
    function finished() public {  

        require(state == State.Successful);
        uint256 remanent = tokenReward.balanceOf(this);

        creator.transfer(address(this).balance);
        tokenReward.transfer(creator,remanent);

        emit LogBeneficiaryPaid(creator);
        emit LogContributorsPayout(creator, remanent);

    }

     
    function claimTokens(token _address) onlyAdmin public{
        require(state == State.Successful);  

        uint256 remainder = _address.balanceOf(this);  
        _address.transfer(admin,remainder);  

    }

     

    function () public payable {

        contribute(address(0));

    }
}