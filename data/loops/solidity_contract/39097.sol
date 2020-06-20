contract Token { 
    function issue(address _recipient, uint256 _value) returns (bool success) {} 
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function unlock() returns (bool success) {}
    function startIncentiveDistribution() returns (bool success) {}
    function transferOwnership(address _newOwner) {}
    function owner() returns (address _owner) {}
}

contract DRPCrowdsale {

     
    address public beneficiary;  
    address public confirmedBy;  
    uint256 public minAmount = 4137 ether;  
    uint256 public maxAmount = 54285 ether;  
    uint256 public minAcceptedAmount = 40 finney;  

     
    uint256 public percentageOfRaisedAmountThatRemainsInContract = 51;  

     
    uint256 public rateAngelDay = 650;
    uint256 public rateFirstWeek = 550;
    uint256 public rateSecondWeek = 475;
    uint256 public rateThirdWeek = 425;
    uint256 public rateLastWeek = 400;

    uint256 public rateAngelDayEnd = 1 days;
    uint256 public rateFirstWeekEnd = 8 days;
    uint256 public rateSecondWeekEnd = 15 days;
    uint256 public rateThirdWeekEnd = 22 days;
    uint256 public rateLastWeekEnd = 29 days;

    enum Stages {
        InProgress,
        Ended,
        Withdrawn,
        Proposed,
        Accepted
    }

    Stages public stage = Stages.InProgress;

     
    uint256 public start;
    uint256 public end;
    uint256 public raised;

     
    Token public drpToken;

     
    mapping (address => uint256) balances;

    struct Proposal {
        address dcorpAddress;
        uint256 deadline;
        uint256 approvedWeight;
        uint256 disapprovedWeight;
        mapping (address => uint256) voted;
    }

     
    Proposal public transferProposal;

     
    uint256 public transferProposalEnd = 7 days;

     
    uint256 public transferProposalCooldown = 1 days;


     
    modifier atStage(Stages _stage) {
        if (stage != _stage) {
            throw;
        }
        _;
    }
    

     
    modifier atStages(Stages _stage1, Stages _stage2) {
        if (stage != _stage1 && stage != _stage2) {
            throw;
        }
        _;
    }


     
    modifier onlyBeneficiary() {
        if (beneficiary != msg.sender) {
            throw;
        }
        _;
    }


     
    modifier onlyShareholders() {
        if (drpToken.balanceOf(msg.sender) == 0) {
            throw;
        }
        _;
    }


     
    modifier beforeDeadline() {
        if (now > transferProposal.deadline) {
            throw;
        }
        _;
    }


     
    modifier afterDeadline() {
        if (now < transferProposal.deadline) {
            throw;
        }
        _;
    }


     
    function balanceOf(address _investor) constant returns (uint256 balance) {
        return balances[_investor];
    }


     
    function DRPCrowdsale(address _tokenAddress, address _beneficiary, uint256 _start) {
        drpToken = Token(_tokenAddress);
        beneficiary = _beneficiary;
        start = _start;
        end = start + 29 days;
    }


     
    function confirmBeneficiary() onlyBeneficiary {
        confirmedBy = msg.sender;
    }


     
    function toDRP(uint256 _wei) returns (uint256 amount) {
        uint256 rate = 0;
        if (stage != Stages.Ended && now >= start && now <= end) {

             
            if (now <= start + rateAngelDayEnd) {
                rate = rateAngelDay;
            }

             
            else if (now <= start + rateFirstWeekEnd) {
                rate = rateFirstWeek;
            }

             
            else if (now <= start + rateSecondWeekEnd) {
                rate = rateSecondWeek;
            }

             
            else if (now <= start + rateThirdWeekEnd) {
                rate = rateThirdWeek;
            }

             
            else if (now <= start + rateLastWeekEnd) {
                rate = rateLastWeek;
            }
        }

        return _wei * rate * 10**2 / 1 ether;  
    }


     
    function endCrowdsale() atStage(Stages.InProgress) {

         
        if (now < end) {
            throw;
        }

        stage = Stages.Ended;
    }


     
    function withdraw() onlyBeneficiary atStage(Stages.Ended) {

         
        if (raised < minAmount) {
            throw;
        }

        uint256 amountToSend = raised * (100 - percentageOfRaisedAmountThatRemainsInContract) / 10**2;
        if (!beneficiary.send(amountToSend)) {
            throw;
        }

        stage = Stages.Withdrawn;
    }


     
    function refund() atStage(Stages.Ended) {

         
        if (raised >= minAmount) {
            throw;
        }

        uint256 receivedAmount = balances[msg.sender];
        balances[msg.sender] = 0;

        if (receivedAmount > 0 && !msg.sender.send(receivedAmount)) {
            balances[msg.sender] = receivedAmount;
        }
    }


     
    function proposeTransfer(address _dcorpAddress) onlyBeneficiary atStages(Stages.Withdrawn, Stages.Proposed) {
        
         
        if (stage == Stages.Proposed && now < transferProposal.deadline + transferProposalCooldown) {
            throw;
        }

        transferProposal = Proposal({
            dcorpAddress: _dcorpAddress,
            deadline: now + transferProposalEnd,
            approvedWeight: 0,
            disapprovedWeight: 0
        });

        stage = Stages.Proposed;
    }


     
    function vote(bool _approve) onlyShareholders beforeDeadline atStage(Stages.Proposed) {

         
        if (transferProposal.voted[msg.sender] >= transferProposal.deadline - transferProposalEnd) {
            throw;
        }

        transferProposal.voted[msg.sender] = now;
        uint256 weight = drpToken.balanceOf(msg.sender);

        if (_approve) {
            transferProposal.approvedWeight += weight;
        } else {
            transferProposal.disapprovedWeight += weight;
        }
    }


     
    function executeTransfer() afterDeadline atStage(Stages.Proposed) {

         
        if (transferProposal.approvedWeight <= transferProposal.disapprovedWeight) {
            throw;
        }

        if (!drpToken.unlock()) {
            throw;
        }
        
        if (!drpToken.startIncentiveDistribution()) {
            throw;
        }

        drpToken.transferOwnership(transferProposal.dcorpAddress);
        if (drpToken.owner() != transferProposal.dcorpAddress) {
            throw;
        }

        if (!transferProposal.dcorpAddress.send(this.balance)) {
            throw;
        }

        stage = Stages.Accepted;
    }

    
     
    function () payable atStage(Stages.InProgress) {

         
        if (now < start) {
            throw;
        }

         
        if (now > end) {
            throw;
        }

         
        if (msg.value < minAcceptedAmount) {
            throw;
        }
 
        uint256 received = msg.value;
        uint256 valueInDRP = toDRP(msg.value);
        if (!drpToken.issue(msg.sender, valueInDRP)) {
            throw;
        }

        balances[msg.sender] += received;
        raised += received;

         
        if (raised >= maxAmount) {
            stage = Stages.Ended;
        }
    }
}