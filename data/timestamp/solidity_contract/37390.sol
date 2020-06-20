pragma solidity ^0.4.4;

contract RaffleStrangeLoop {
    address owner;
    address public winner;
    mapping(uint => address) public tickets;

    uint public numTickets;
    uint public ethereumFoundationTickets;

    uint public chooseWinnerDeadline;

    uint public lastBlock;
    bytes32 public serverSeedHash;
    bytes32 public clientSeed;

    event Winner(address value);

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier notFinished() {
        require(winner == 0x0);
        _;
    }

    function RaffleStrangeLoop(bytes32 secretHash) {
        owner = msg.sender;
        serverSeedHash = secretHash;
        chooseWinnerDeadline = block.timestamp + 15 days;
    }

    function getRaffleTimeLeft() constant returns (uint) {
        int timeLeft = int(chooseWinnerDeadline) - int(block.timestamp);
        if (timeLeft > 0) {
            return uint(timeLeft);
        } else {
            return 0;
        }
    }

    function chooseWinner(bytes32 seed) isOwner notFinished {
         
        require(sha3(seed) == serverSeedHash);

         
        int timeLeft = int(chooseWinnerDeadline) - int(block.timestamp);
        require(timeLeft < 0 && timeLeft > -86400);

         
        require(numTickets > 0);

         
        bytes32 serverClientHash = sha3(seed, clientSeed);

        uint winnerIdx = (uint(serverClientHash) ^ lastBlock) % numTickets;
        winner = tickets[winnerIdx];
        Winner(winner);

         
        uint donation = ethereumFoundationTickets * 10000000000000000;
        if (donation > 0) {
             
            address ethereumTipJar = 0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359;
            ethereumTipJar.transfer(donation);
        }

         
        owner.transfer(this.balance);
    }

    function buyTickets(bytes32 beneficiary) payable notFinished {
         
        require(getRaffleTimeLeft() > 0);

         
        uint ticketsBought = msg.value / 10000000000000000;

         
        msg.sender.transfer(msg.value % 10000000000000000);

         
        clientSeed = sha3(clientSeed, msg.sender, msg.value);

         
        lastBlock = block.number;

         
        for (uint i = 0; i < ticketsBought; i++) {
            tickets[numTickets++] = msg.sender;
        }

        if (beneficiary == "ethereum-foundation") {
            ethereumFoundationTickets += ticketsBought;
        }
    }

    function getRefund() notFinished {
         
        int timeLeft = int(chooseWinnerDeadline) - int(block.timestamp);
        require(timeLeft < -86400);

        uint amountToRefund = 0;
        for (uint i = 0; i < numTickets; i++) {
            if(tickets[i] == msg.sender) {
                amountToRefund += 10000000000000000;
                tickets[i] = 0x0;
            }
        }

        msg.sender.transfer(amountToRefund);
    }

    function () payable notFinished {
        buyTickets("owner");
    }
}