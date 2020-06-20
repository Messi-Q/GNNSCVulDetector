pragma solidity ^0.4.24;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) throw;
    }
}

contract AccessControl is SafeMath{

     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    address newContractAddress;

    uint public tip_total = 0;
    uint public tip_rate = 20000000000000000;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    function () public payable{
        tip_total = safeAdd(tip_total, msg.value);
    }

     
     
    function amountWithTip(uint amount) internal returns(uint){
        uint tip = safeMul(amount, tip_rate) / (1 ether);
        tip_total = safeAdd(tip_total, tip);
        return safeSub(amount, tip);
    }

     
    function withdrawTip(uint amount) external onlyCFO {
        require(amount > 0 && amount <= tip_total);
        require(msg.sender.send(amount));
        tip_total = tip_total - amount;
    }

     
    function setNewAddress(address newContract) external onlyCEO whenPaused {
        newContractAddress = newContract;
        emit ContractUpgrade(newContract);
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}


contract RpsGame is SafeMath , AccessControl{

     
    uint8 constant public NONE = 0;
    uint8 constant public ROCK = 10;
    uint8 constant public PAPER = 20;
    uint8 constant public SCISSORS = 30;
    uint8 constant public DEALERWIN = 201;
    uint8 constant public PLAYERWIN = 102;
    uint8 constant public DRAW = 101;

     
    event CreateGame(uint gameid, address dealer, uint amount);
    event JoinGame(uint gameid, address player, uint amount);
    event Reveal(uint gameid, address player, uint8 choice);
    event CloseGame(uint gameid,address dealer,address player, uint8 result);

     
    struct Game {
        uint expireTime;
        address dealer;
        uint dealerValue;
        bytes32 dealerHash;
        uint8 dealerChoice;
        address player;
        uint8 playerChoice;
        uint playerValue;
        uint8 result;
        bool closed;
    }

     
    mapping (uint => mapping(uint => uint8)) public payoff;
    mapping (uint => Game) public games;
    mapping (address => uint[]) public gameidsOf;

     
    uint public maxgame = 0;
    uint public expireTimeLimit = 30 minutes;

     
    function RpsGame() {
        payoff[ROCK][ROCK] = DRAW;
        payoff[ROCK][PAPER] = PLAYERWIN;
        payoff[ROCK][SCISSORS] = DEALERWIN;
        payoff[PAPER][ROCK] = DEALERWIN;
        payoff[PAPER][PAPER] = DRAW;
        payoff[PAPER][SCISSORS] = PLAYERWIN;
        payoff[SCISSORS][ROCK] = PLAYERWIN;
        payoff[SCISSORS][PAPER] = DEALERWIN;
        payoff[SCISSORS][SCISSORS] = DRAW;
        payoff[NONE][NONE] = DRAW;
        payoff[ROCK][NONE] = DEALERWIN;
        payoff[PAPER][NONE] = DEALERWIN;
        payoff[SCISSORS][NONE] = DEALERWIN;
        payoff[NONE][ROCK] = PLAYERWIN;
        payoff[NONE][PAPER] = PLAYERWIN;
        payoff[NONE][SCISSORS] = PLAYERWIN;

        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
    }

     
    function createGame(bytes32 dealerHash, address player) public payable whenNotPaused returns (uint){
        require(dealerHash != 0x0);

        maxgame += 1;
        Game storage game = games[maxgame];
        game.dealer = msg.sender;
        game.player = player;
        game.dealerHash = dealerHash;
        game.dealerChoice = NONE;
        game.dealerValue = msg.value;
        game.expireTime = expireTimeLimit + now;

        gameidsOf[msg.sender].push(maxgame);

        emit CreateGame(maxgame, game.dealer, game.dealerValue);

        return maxgame;
    }

     
    function joinGame(uint gameid, uint8 choice) public payable whenNotPaused returns (uint){
        Game storage game = games[gameid];

        require(msg.value == game.dealerValue && game.dealer != address(0) && game.dealer != msg.sender && game.playerChoice==NONE);
        require(game.player == address(0) || game.player == msg.sender);
        require(!game.closed);
        require(now < game.expireTime);
        require(checkChoice(choice));

        game.player = msg.sender;
        game.playerChoice = choice;
        game.playerValue = msg.value;
        game.expireTime = expireTimeLimit + now;

        gameidsOf[msg.sender].push(gameid);

        emit JoinGame(gameid, game.player, game.playerValue);

        return gameid;
    }

     
    function reveal(uint gameid, uint8 choice, bytes32 randomSecret) public returns (bool) {
        Game storage game = games[gameid];
        bytes32 proof = getProof(msg.sender, choice, randomSecret);

        require(!game.closed);
        require(now < game.expireTime);
        require(game.dealerHash != 0x0);
        require(checkChoice(choice));
        require(checkChoice(game.playerChoice));
        require(game.dealer == msg.sender && proof == game.dealerHash );

        game.dealerChoice = choice;

        Reveal(gameid, msg.sender, choice);

        close(gameid);

        return true;
    }

     
    function close(uint gameid) public returns(bool) {
        Game storage game = games[gameid];

        require(!game.closed);
        require(now > game.expireTime || (game.dealerChoice != NONE && game.playerChoice != NONE));

        uint8 result = payoff[game.dealerChoice][game.playerChoice];

        if(result == DEALERWIN){
            require(game.dealer.send(amountWithTip(safeAdd(game.dealerValue, game.playerValue))));
        }else if(result == PLAYERWIN){
            require(game.player.send(amountWithTip(safeAdd(game.dealerValue, game.playerValue))));
        }else if(result == DRAW){
            require(game.dealer.send(game.dealerValue) && game.player.send(game.playerValue));
        }

        game.closed = true;
        game.result = result;

        emit CloseGame(gameid, game.dealer, game.player, result);

        return game.closed;
    }


    function getProof(address sender, uint8 choice, bytes32 randomSecret) public view returns (bytes32){
        return sha3(sender, choice, randomSecret);
    }

    function gameCountOf(address owner) public view returns (uint){
        return gameidsOf[owner].length;
    }

    function checkChoice(uint8 choice) public view returns (bool){
        return choice==ROCK||choice==PAPER||choice==SCISSORS;
    }

}