pragma solidity ^0.4.18;

contract PoP{
	using SafeMath for uint256;
	using SafeInt for int256;
	using Player for Player.Data;
	using BettingRecordArray for BettingRecordArray.Data;
	using WrappedArray for WrappedArray.Data;
	using FixedPoint for FixedPoint.Data;

	 
	string public name;
  	string public symbol;
  	uint8 public decimals;
  	address private author;
	
  	 
  	event Bet(address player, uint256 betAmount, uint256 betNumber, uint256 gameNumber);
	event Withdraw(address player, uint256 amount, uint256 numberOfRecordsProcessed);
	event EndGame(uint256 currentGameNumber);	

	 
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Burn(address indexed burner, uint256 value);
	event Mined(address indexed miner, uint256 value);

	 
	function PoP() public {
		name = "PopCoin"; 
    	symbol = "PoP"; 
    	decimals = 18;
    	author = msg.sender;
    	totalSupply_ = 10000000 * 10 ** uint256(decimals);
    	lastBetBlockNumber = 0;
    	currentGameNumber = 0;
    	currentPot = 0;
    	initialSeed = 0;
		minimumWager = kBaseMinBetSize.toUInt256Raw();
    	minimumNumberOfBlocksToEndGame = kLowerBoundBlocksTillGameEnd.add(kUpperBoundBlocksTillGameEnd).toUInt256Raw();
    	gameHasStarted = false;
    	currentMiningDifficulty = FixedPoint.fromInt256(kStartingGameMiningDifficulty);
		unPromisedSupplyAtStartOfCurrentGame_ = totalSupply_;
		currentPotSplit = 1000;

		nextGameMaxBlock = kUpperBoundBlocksTillGameEnd;
		nextGameMinBlock = kLowerBoundBlocksTillGameEnd;
    	currentGameInitialMinBetSize = kBaseMinBetSize;
    	nextGameInitialMinBetSize = currentGameInitialMinBetSize;

    	nextFrontWindowAdjustmentRatio = frontWindowAdjustmentRatio;
    	nextBackWindowAdjustmentRatio = backWindowAdjustmentRatio;
    	nextGameSeedPercent = percentToTakeAsSeed;
    	nextGameRakePercent = percentToTakeAsRake;
    	nextGameDeveloperMiningPower = developerMiningPower;
    	nextGamePotSplit = currentPotSplit;

    	 
    	canUpdateNextGameInitalMinBetSize = true;
		canUpdateFrontWindowAdjustmentRatio = true;
		canUpdateBackWindowAdjustmentRatio = true;
		canUpdateNextGamePotSplit = true;
		canUpdatePercentToTakeAsSeed = true;
		canUpdateNextGameMinAndMaxBlockUntilGameEnd = true;
		canUpdateAmountToTakeAsRake = true;
		canUpdateDeveloperMiningPower = true;
	}


	 
	FixedPoint.Data _2pi = FixedPoint.Data({val: 26986075409});
	FixedPoint.Data _pi = FixedPoint.Data({val: 13493037704});
	FixedPoint.Data kBackPayoutEndPointInitial = FixedPoint.fromFraction(1, 2);
	FixedPoint.Data kFrontPayoutStartPointInitial = FixedPoint.fromFraction(1, 2);
	uint256 public percentToTakeAsRake = 500;  
	uint256 public percentToTakeAsSeed = 900;  
	uint256 public developerMiningPower = 3000;  
	uint256 constant kTotalPercent = 10000; 
	uint8 constant kStartingGameMiningDifficulty = 1;
	uint256 potSplitMax = 2000;
	uint8 constant kDifficultyWindow = 10;  
	FixedPoint.Data kDifficultyDropOffFactor = FixedPoint.fromFraction(8, 10);  
	uint256 constant kWeiConstant = 10 ** 18;
	FixedPoint.Data kExpectedFirstGameSize = FixedPoint.fromInt256(Int256(10 * kWeiConstant));
	FixedPoint.Data kExpectedPopCoinToBePromisedPercent = FixedPoint.fromFraction(1, 1000);  
	FixedPoint.Data kLowerBoundBlocksTillGameEnd = FixedPoint.fromInt256(6);  
	FixedPoint.Data kUpperBoundBlocksTillGameEnd = FixedPoint.fromInt256(80);  
	FixedPoint.Data kBaseMinBetSize = FixedPoint.fromInt256(Int256(kWeiConstant/1000)); 
	FixedPoint.Data kMaxPopMiningPotMultiple = FixedPoint.fromFraction(118709955, 1000000);  


	 
	uint256 public lastBetBlockNumber;
	uint256 public minimumNumberOfBlocksToEndGame;
	uint256 public currentPot;
	uint256 public currentGameNumber;
	FixedPoint.Data currentMiningDifficulty;
	uint256 public initialSeed;
	uint256 public bonusSeed;
	uint256 public minimumWager;
	uint256 public currentBetNumber;
	uint256 public nextGameSeedPercent;
	uint256 public nextGameRakePercent;
	uint256 public nextGameDeveloperMiningPower;
	uint256 public currentPotSplit;
	uint256 public nextGamePotSplit;

	 
	mapping (address => Player.Data) playerCollection;
	BettingRecordArray.Data currentGameBettingRecords;
	WrappedArray.Data gameMetaData;
	mapping (address => uint256) playerInternalWallet;
	FixedPoint.Data public initialBankrollGrowthAmount;  
	FixedPoint.Data public nextGameInitialMinBetSize;
	FixedPoint.Data currentGameInitialMinBetSize;
	FixedPoint.Data public nextGameMaxBlock;
	FixedPoint.Data public nextGameMinBlock;

	FixedPoint.Data public frontWindowAdjustmentRatio = FixedPoint.fromFraction(13, 10);  
	FixedPoint.Data public backWindowAdjustmentRatio = FixedPoint.fromFraction(175, 100);  
	FixedPoint.Data public nextFrontWindowAdjustmentRatio;
	FixedPoint.Data public nextBackWindowAdjustmentRatio;

	 
	mapping(address => uint256) popBalances;
	mapping (address => mapping (address => uint256)) internal allowed;
	uint256 totalSupply_;
	uint256 supplyMined_;
	uint256 supplyBurned_;
	uint256 unPromisedSupplyAtStartOfCurrentGame_;
	bool gameHasStarted;


	 
	bool public canUpdateNextGameInitalMinBetSize;
	bool public canUpdateFrontWindowAdjustmentRatio;
	bool public canUpdateBackWindowAdjustmentRatio;
	bool public canUpdateNextGamePotSplit;
	bool public canUpdatePercentToTakeAsSeed;
	bool public canUpdateNextGameMinAndMaxBlockUntilGameEnd;
	bool public canUpdateAmountToTakeAsRake;
	bool public canUpdateDeveloperMiningPower;

	function turnOffCanUpdateNextGameInitalMinBetSize () public {
		require (msg.sender == author);
		require (canUpdateNextGameInitalMinBetSize == true);
		canUpdateNextGameInitalMinBetSize = false;
	}

	function turnOffCanUpdateFrontWindowAdjustmentRatio () public {
		require (msg.sender == author);
		require (canUpdateFrontWindowAdjustmentRatio == true);
		canUpdateFrontWindowAdjustmentRatio = false;
	}

	function turnOffCanUpdateBackWindowAdjustmentRatio () public {
		require (msg.sender == author);
		require (canUpdateBackWindowAdjustmentRatio == true);
		canUpdateBackWindowAdjustmentRatio = false;
	}

	function turnOffCanUpdateNextGamePotSplit () public {
		require (msg.sender == author);
		require (canUpdateNextGamePotSplit == true);
		canUpdateNextGamePotSplit = false;
	}

	function turnOffCanUpdatePercentToTakeAsSeed () public {
		require (msg.sender == author);
		require (canUpdatePercentToTakeAsSeed == true);
		canUpdatePercentToTakeAsSeed = false;
	}

	function turnOffCanUpdateNextGameMinAndMaxBlockUntilGameEnd () public {
		require (msg.sender == author);
		require (canUpdateNextGameMinAndMaxBlockUntilGameEnd == true);
		canUpdateNextGameMinAndMaxBlockUntilGameEnd = false;
	}

	function turnOffCanUpdateAmountToTakeAsRake () public {
		require (msg.sender == author);
		require (canUpdateAmountToTakeAsRake == true);
		canUpdateAmountToTakeAsRake = false;
	}

	function turnOffCanUpdateDeveloperMiningPower () public {
		require (msg.sender == author);
		require (canUpdateDeveloperMiningPower == true);
		canUpdateDeveloperMiningPower = false;
	}
	
	
	function balanceOfContract () public constant returns(uint256 res)   {
		return address(this).balance;
	}

	function getCurrentGameInitialMinBetSize () public view returns(uint256 res)  {
		return currentGameInitialMinBetSize.toUInt256Raw();
	}
	

	function startGame () payable public {
		require (msg.sender == author);
		require (msg.value > 0);
		require (gameHasStarted == false);
		
		initialSeed = initialSeed.add(msg.value);
		currentPot = initialSeed;
		gameHasStarted = true;
	}
	
	function updateNextGameInitalMinBetSize (uint256 nextGameMinBetSize) public {
		require (msg.sender == author);
		require (canUpdateNextGameInitalMinBetSize == true);
		require (nextGameMinBetSize > 0);
		FixedPoint.Data memory nextMinBet = FixedPoint.fromInt256(Int256(nextGameMinBetSize));

		 
		require(nextMinBet.cmp(currentGameInitialMinBetSize.mul(FixedPoint.fromInt256(2))) != 1);
		require(nextMinBet.cmp(currentGameInitialMinBetSize.div(FixedPoint.fromInt256(2))) != -1);
		
		nextGameInitialMinBetSize = FixedPoint.fromInt256(Int256(nextGameMinBetSize));
	}

	function updateNextWindowAdjustmentRatio (int256 numerator, bool updateFront) public {
		require (msg.sender == author);
		require (numerator >= 1000);
		require (numerator <= 2718);
		require ((updateFront && canUpdateFrontWindowAdjustmentRatio) || (!updateFront && canUpdateBackWindowAdjustmentRatio));

		if(updateFront == true) {
			nextFrontWindowAdjustmentRatio = FixedPoint.fromFraction(numerator, 1000);
		} else {
			nextBackWindowAdjustmentRatio = FixedPoint.fromFraction(numerator, 1000);
		}
	}

	function updateNextGamePotSplit (uint256 potSplit ) public {
		require (msg.sender == author);
		require (canUpdateNextGamePotSplit);
		require (potSplit <= 2000);
		nextGamePotSplit = potSplit;
	}

	function updatePercentToTakeAsSeed (uint256 value) public {
		require (msg.sender == author);
		require (canUpdatePercentToTakeAsSeed);
		require (value < 10000);
		if (value > percentToTakeAsSeed){
			require (value / percentToTakeAsSeed == 1);
		} else {
			require (percentToTakeAsSeed / value == 1);
		}

		nextGameSeedPercent = value;
	}

	function updateNextGameMinAndMaxBlockUntilGameEnd (uint256 maxBlocks, uint256 minBlocks) public {
		require (msg.sender == author);
		require (canUpdateNextGameMinAndMaxBlockUntilGameEnd);
		require (maxBlocks > 0);
		require (minBlocks > 0);
		FixedPoint.Data memory nextMaxBlock = FixedPoint.fromInt256(Int256(maxBlocks));
		FixedPoint.Data memory nextMinBlock = FixedPoint.fromInt256(Int256(minBlocks));
		require(nextMaxBlock.cmp(kUpperBoundBlocksTillGameEnd.mul(FixedPoint.fromInt256(2))) != 1);
		require(nextMaxBlock.cmp(kUpperBoundBlocksTillGameEnd.div(FixedPoint.fromInt256(2))) != -1);
		require(nextMinBlock.cmp(kLowerBoundBlocksTillGameEnd.mul(FixedPoint.fromInt256(2))) != 1);
		require(nextMaxBlock.cmp(kLowerBoundBlocksTillGameEnd.div(FixedPoint.fromInt256(2))) != -1);

		nextGameMaxBlock = FixedPoint.fromInt256(Int256(maxBlocks));
		nextGameMinBlock = FixedPoint.fromInt256(Int256(minBlocks));
	}

	function getUpperBoundBlocksTillGameEnd() public view returns(uint256) {
		return kUpperBoundBlocksTillGameEnd.toUInt256Raw();

	}

	function getLowerBoundBlocksTillGameEnd() public view returns(uint256) {
		return kLowerBoundBlocksTillGameEnd.toUInt256Raw();
	}

	function addToRakePool () public payable{
		assert (msg.value > 0);
		playerInternalWallet[this] = playerInternalWallet[this].add(msg.value);
	}

	 
	function bet () payable public {
		 
		require(msg.value >= minimumWager); 
		require(gameHasStarted);

		uint256 betAmount = msg.value;

		 
		betAmount = betAmountAfterRakeHasBeenWithdrawnAndProcessed(betAmount);

		if((block.number.sub(lastBetBlockNumber) >= minimumNumberOfBlocksToEndGame) && (lastBetBlockNumber != 0)) {
			processEndGame(betAmount);
		} else if (lastBetBlockNumber == 0) {
			initialBankrollGrowthAmount = FixedPoint.fromInt256(Int256(betAmount.add(initialSeed)));
		}

		emit Bet(msg.sender, betAmount, currentBetNumber, currentGameNumber);

		Player.BettingRecord memory newBetRecord = Player.BettingRecord(msg.sender, currentGameNumber, betAmount, currentBetNumber, currentPot.sub(initialSeed), 0, 0, true); 

		Player.Data storage currentPlayer = playerCollection[msg.sender];

		currentPlayer.insertBettingRecord(newBetRecord);

		Player.BettingRecord memory oldGameUnprocessedBettingRecord = currentGameBettingRecords.getNextRecord();

		currentGameBettingRecords.pushRecord(newBetRecord);

		if(oldGameUnprocessedBettingRecord.isActive == true) {
			processBettingRecord(oldGameUnprocessedBettingRecord);
		}

		currentPot = currentPot.add(betAmount);
		currentBetNumber = currentBetNumber.add(1);
		lastBetBlockNumber = block.number;
		FixedPoint.Data memory currentGameSize = FixedPoint.fromInt256(Int256(currentPot));
		FixedPoint.Data memory expectedGameSize = currentMiningDifficulty.mul(kExpectedFirstGameSize);
		minimumNumberOfBlocksToEndGame = calcNumberOfBlocksUntilGameEnds(currentGameSize, expectedGameSize).toUInt256Raw();
		minimumWager = calcMinimumBetSize(currentGameSize, expectedGameSize).toUInt256Raw();
	}

	function getMyBetRecordCount() public view returns(uint256) {
		Player.Data storage currentPlayer = playerCollection[msg.sender];
		return currentPlayer.unprocessedBettingRecordCount();
	}

	function getDeveloperMiningPowerForGameId (uint256 gameId) private view returns(uint256 res) {
		if(gameId == currentGameNumber) {
			return developerMiningPower;
		} else {
			WrappedArray.GameMetaDataElement memory elem = gameMetaData.itemAtIndex(gameId);
			return elem.developerMiningPower;
		}
	}

	function playerPopMining(uint256 recordIndex, bool onlyCurrentGame) public view returns(uint256) {
		Player.Data storage currentPlayer = playerCollection[msg.sender];
		Player.BettingRecord memory playerBettingRecord = currentPlayer.getBettingRecordAtIndex(recordIndex);
		return computeAmountToMineForBettingRecord(playerBettingRecord, onlyCurrentGame).mul(kTotalPercent - getDeveloperMiningPowerForGameId(playerBettingRecord.gameId)).div(kTotalPercent);
	}

	function getBetRecord(uint256 recordIndex) public view returns(uint256, uint256, uint256) {
		Player.Data storage currentPlayer = playerCollection[msg.sender];
		Player.BettingRecord memory bettingRecord = currentPlayer.getBettingRecordAtIndex(recordIndex);
		return (bettingRecord.gamePotBeforeBet, bettingRecord.wagerAmount, bettingRecord.gameId);
	}

	function withdraw (uint256 withdrawCount) public returns(bool res) {
		Player.Data storage currentPlayer = playerCollection[msg.sender];

		uint256 playerBettingRecordCount = currentPlayer.unprocessedBettingRecordCount();
		uint256 numberOfIterations = withdrawCount < playerBettingRecordCount ? withdrawCount : playerBettingRecordCount;
		numberOfIterations = numberOfIterations == 0 ? 0 : numberOfIterations.add(1);

		for (uint256 i = 0 ; i < numberOfIterations; i = i.add(1)) {
			Player.BettingRecord memory unprocessedRecord = currentPlayer.getNextRecord();
			processBettingRecord(unprocessedRecord);
		}

		uint256 playerBalance = playerInternalWallet[msg.sender];

		playerInternalWallet[msg.sender] = 0;

		if(playerBalance == 0) {
			return true;
		}

		emit Withdraw(msg.sender, playerBalance, numberOfIterations);

		if(!msg.sender.send(playerBalance)) {
			 
			playerInternalWallet[msg.sender] = playerBalance;
			return false;
		}
		return true;
	}


	function getCurrentMiningDifficulty() public view returns(uint256){
		return UInt256(currentMiningDifficulty.toInt256());
	}

	function getPlayerInternalWallet() public view returns(uint256) {
		return playerInternalWallet[msg.sender];
	}

	function getWinningsForRecordId(uint256 recordIndex, bool onlyWithdrawable, bool onlyCurrentGame) public view returns(uint256) {
		Player.Data storage currentPlayer = playerCollection[msg.sender];
		Player.BettingRecord memory record = currentPlayer.getBettingRecordAtIndex(recordIndex);
		if(onlyCurrentGame && record.gameId != currentGameNumber) {
			return 0;
		}
		return getWinningsForRecord(record, onlyWithdrawable);
	}

	function getWinningsForRecord(Player.BettingRecord record, bool onlyWithdrawable) private view returns(uint256) {

		if(onlyWithdrawable && recordIsTooNewToProcess(record)) {
			return 0;
		}

		uint256 payout = getPayoutForPlayer(record).toUInt256Raw();
		uint256 seedPercentForGame = getSeedPercentageForGameId(record.gameId);
		payout = payout.sub(amountToSeedNextRound(payout, seedPercentForGame));
		return payout.sub(record.withdrawnAmount);

	}

	function totalAmountRaked ()  public constant returns(uint256 res) {
		return playerInternalWallet[this];
	}

	function betAmountAfterRakeHasBeenWithdrawnAndProcessed (uint256 betAmount) private returns(uint256 betLessRake){
		uint256 amountToRake = amountToTakeAsRake(betAmount);
		playerInternalWallet[this] = playerInternalWallet[this].add(amountToRake);
		return betAmount.sub(amountToRake);
	}

	function getSeedPercentageForGameId (uint256 gameId) private view returns(uint256 res) {
		if(gameId == currentGameNumber) {
			return percentToTakeAsSeed;
		} else {
			WrappedArray.GameMetaDataElement memory elem = gameMetaData.itemAtIndex(gameId);
			return elem.percentToTakeAsSeed;
		}
	}

	function amountToSeedNextRound (uint256 value, uint256 seedPercent) private pure returns(uint256 res) {
		return value.mul(seedPercent).div(kTotalPercent);
	}

	function addToBonusSeed () public payable {
		require (msg.value > 0);
		bonusSeed = bonusSeed.add(msg.value);
	}

	function updateAmountToTakeAsRake(uint256 value) public {
		require (msg.sender == author);
		require (canUpdateAmountToTakeAsRake);
		require (value < 10000);
		if(percentToTakeAsRake > value) {
			require(percentToTakeAsRake - value <= 100);
		} else {
			require(value - percentToTakeAsRake <= 100);
		}

		nextGameRakePercent = value;
	}

	function updateDeveloperMiningPower(uint256 value) public {
		require (msg.sender == author);
		require (canUpdateDeveloperMiningPower);
		require (value <= 3000);
		nextGameDeveloperMiningPower = value;
	}

	function amountToTakeAsRake (uint256 value) private view returns(uint256 res) {
		return value.mul(percentToTakeAsRake).div(kTotalPercent);
	}
	
	function processEndGame (uint256 lastBetAmount) private {
		 
		 
		emit EndGame(currentGameNumber);
		 
		gameMetaData.push(WrappedArray.GameMetaDataElement(currentPot, initialSeed, initialBankrollGrowthAmount.toUInt256Raw(), unPromisedSupplyAtStartOfCurrentGame_, developerMiningPower, percentToTakeAsSeed, percentToTakeAsRake, currentPotSplit, currentMiningDifficulty, frontWindowAdjustmentRatio, backWindowAdjustmentRatio, true));  

		frontWindowAdjustmentRatio = nextFrontWindowAdjustmentRatio;
		backWindowAdjustmentRatio = nextBackWindowAdjustmentRatio;

		currentGameInitialMinBetSize = nextGameInitialMinBetSize;
		kUpperBoundBlocksTillGameEnd = nextGameMaxBlock;
		kLowerBoundBlocksTillGameEnd = nextGameMinBlock;

		unPromisedSupplyAtStartOfCurrentGame_ = unPromisedPop();

		initialSeed = amountToSeedNextRound(currentPot, percentToTakeAsSeed).add(bonusSeed);
		bonusSeed = 0;
		currentPot = initialSeed;
		currentMiningDifficulty = calcDifficulty();
		percentToTakeAsSeed = nextGameSeedPercent;
		percentToTakeAsRake = nextGameRakePercent;
		developerMiningPower = nextGameDeveloperMiningPower;
		currentPotSplit = nextGamePotSplit;
		 
		initialBankrollGrowthAmount = FixedPoint.fromInt256(Int256(lastBetAmount.add(initialSeed)));

		 
		currentGameBettingRecords.resetIndex();

		 
		currentGameNumber = currentGameNumber.add(1);
	}

	function processBettingRecord (Player.BettingRecord record) private {
		Player.Data storage currentPlayer = playerCollection[record.playerAddress];
		if(currentPlayer.containsBettingRecordFromId(record.bettingRecordId) == false) {
			return;
		}
		 
		Player.BettingRecord memory bettingRecord = currentPlayer.getBettingRecordForId(record.bettingRecordId);

		currentPlayer.deleteBettingRecordForId(bettingRecord.bettingRecordId);

		 
		uint256 bettingRecordValue = getWinningsForRecord(bettingRecord, true);
		uint256 amountToMineForBettingRecord = computeAmountToMineForBettingRecord(bettingRecord, false);

		 
		if(bettingRecord.gameId == currentGameNumber) {
			bettingRecord.withdrawnAmount = bettingRecord.withdrawnAmount.add(bettingRecordValue);
			bettingRecord.withdrawnPopAmount = bettingRecord.withdrawnPopAmount.add(amountToMineForBettingRecord);
			currentPlayer.insertBettingRecord(bettingRecord);
		}
		minePoP(bettingRecord.playerAddress, amountToMineForBettingRecord, bettingRecord.gameId);
		playerInternalWallet[bettingRecord.playerAddress] = playerInternalWallet[bettingRecord.playerAddress].add(bettingRecordValue);
	}

	
	function recordIsTooNewToProcess (Player.BettingRecord record) private view returns(bool res) {

		if(record.gameId == currentGameNumber) {
			return true;
		}
		return false;
	}

	function UInt256 (int256 elem) private pure returns(uint256 res) {
		assert(elem >= 0);
		return uint256(elem);
	}
	
	function Int256 (uint256 elem) private pure returns(int256 res) {
		assert(int256(elem) >= 0);
		return int256(elem);
	}
	
	function getBankRollGrowthForGameId (uint256 gameId) private view returns(FixedPoint.Data res) {
		if(gameId == currentGameNumber) {
			return FixedPoint.fromInt256(Int256(currentPot)).div(initialBankrollGrowthAmount);
		} else {
			WrappedArray.GameMetaDataElement memory elem = gameMetaData.itemAtIndex(gameId);
			return FixedPoint.fromInt256(Int256(elem.totalPotAmount)).div(FixedPoint.fromInt256(Int256(elem.initialBet)));
		}
	}

	function getSeedAmountForGameId (uint256 gameId) private view returns(FixedPoint.Data res) {
		if(gameId == currentGameNumber) {
			return FixedPoint.fromInt256(Int256(initialSeed));
		} else {
			WrappedArray.GameMetaDataElement memory elem = gameMetaData.itemAtIndex(gameId);
			return FixedPoint.fromInt256(Int256(elem.seedAmount));
		}
	}

	function getWindowAdjRatioForGameId (uint256 gameId, bool isFront) internal view returns(FixedPoint.Data) {
		if(gameId == currentGameNumber) {
			return isFront == true ? frontWindowAdjustmentRatio : backWindowAdjustmentRatio;
		} else {
			WrappedArray.GameMetaDataElement memory elem = gameMetaData.itemAtIndex(gameId);
			return isFront == true ? elem.frontWindowAdjustmentRatio : elem.backWindowAdjustmentRatio;
		}
	}

	function getSplitPotAsFixedPointForGameId (uint256 gameId, bool isFront) internal view returns (FixedPoint.Data) {
		if(gameId == currentGameNumber) {
			if(isFront){
				return FixedPoint.fromFraction(Int256(currentPotSplit), 1000);
			} else {
				return FixedPoint.fromFraction(Int256(potSplitMax.sub(currentPotSplit)), 1000);
			}
		} else {
			WrappedArray.GameMetaDataElement memory elem = gameMetaData.itemAtIndex(gameId);
			if(isFront){
				return FixedPoint.fromFraction(Int256(elem.potSplit), 1000);
			} else {
				return FixedPoint.fromFraction(Int256(potSplitMax.sub(elem.potSplit)), 1000);
			}
		}
	}

	function getAdjustedPotAsFixedPointForGameId (uint256 gameId, bool isFront) internal view returns (FixedPoint.Data) {
		return getPotAsFixedPointForGameId(gameId).mul(getSplitPotAsFixedPointForGameId(gameId, isFront));
	}

	function getPayoutForPlayer(Player.BettingRecord playerRecord) internal view returns (FixedPoint.Data) {

		FixedPoint.Data memory frontWindowAdjustment = getWindowAdjustmentForGameIdAndRatio(playerRecord.gameId, getWindowAdjRatioForGameId(playerRecord.gameId, true));
		FixedPoint.Data memory backWindowAdjustment = getWindowAdjustmentForGameIdAndRatio(playerRecord.gameId, getWindowAdjRatioForGameId(playerRecord.gameId, false));
		FixedPoint.Data memory backPayoutEndPoint = kBackPayoutEndPointInitial.div(backWindowAdjustment);
		FixedPoint.Data memory frontPayoutSizePercent = kFrontPayoutStartPointInitial.div(frontWindowAdjustment);
        FixedPoint.Data memory frontPayoutStartPoint = FixedPoint.fromInt256(1).sub(frontPayoutSizePercent);

		FixedPoint.Data memory frontPercent = FixedPoint.fromInt256(0);
		if(playerRecord.gamePotBeforeBet != 0) {
			frontPercent = FixedPoint.fromInt256(Int256(playerRecord.gamePotBeforeBet)).div(getPotAsFixedPointForGameId(playerRecord.gameId).sub(getSeedAmountForGameId(playerRecord.gameId)));
		}

		FixedPoint.Data memory backPercent = FixedPoint.fromInt256(Int256(playerRecord.gamePotBeforeBet)).add(FixedPoint.fromInt256(Int256(playerRecord.wagerAmount))).div(getPotAsFixedPointForGameId(playerRecord.gameId).sub(getSeedAmountForGameId(playerRecord.gameId)));

		if(frontPercent.val < backPayoutEndPoint.val) {
		    if(backPercent.val <= backPayoutEndPoint.val) {
		    	 
		        return calcWinnings(frontPercent.div(backPayoutEndPoint), backPercent.div(backPayoutEndPoint), backWindowAdjustment, FixedPoint.fromInt256(0), playerRecord.gameId, false);
		    } else if (backPercent.val <= frontPayoutStartPoint.val) {
		    	 
		        return calcWinnings(frontPercent.div(backPayoutEndPoint), backPayoutEndPoint.div(backPayoutEndPoint), backWindowAdjustment, FixedPoint.fromInt256(0), playerRecord.gameId, false);
		    } else {
		    	 
		        return calcWinnings(frontPercent.div(backPayoutEndPoint), backPayoutEndPoint.div(backPayoutEndPoint), backWindowAdjustment, FixedPoint.fromInt256(0), playerRecord.gameId, false).add(calcWinnings(FixedPoint.fromInt256(0), backPercent.sub(frontPayoutStartPoint).div(frontPayoutSizePercent), frontWindowAdjustment, _pi.div(frontWindowAdjustment), playerRecord.gameId, true));
		    }
		} else if (frontPercent.val < frontPayoutStartPoint.val) {
		    if (backPercent.val <= frontPayoutStartPoint.val) {
		    	 
		        return FixedPoint.fromInt256(0);
		    } else {
		    	 
		        return calcWinnings(FixedPoint.fromInt256(0), backPercent.sub(frontPayoutStartPoint).div(frontPayoutSizePercent), frontWindowAdjustment, _pi.div(frontWindowAdjustment), playerRecord.gameId, true);
		    }
		} else {
			 
		    return calcWinnings(frontPercent.sub(frontPayoutStartPoint).div(frontPayoutSizePercent), backPercent.sub(frontPayoutStartPoint).div(frontPayoutSizePercent), frontWindowAdjustment, _pi.div(frontWindowAdjustment), playerRecord.gameId, true);
		}
	}

	function getWindowAdjustmentForGameIdAndRatio(uint256 gameId, FixedPoint.Data adjustmentRatio) internal view returns (FixedPoint.Data) {
		FixedPoint.Data memory growth = getBankRollGrowthForGameId(gameId); 
		FixedPoint.Data memory logGrowthRate = growth.ln();
		return growth.div(adjustmentRatio.pow(logGrowthRate));
	}

	function integrate(FixedPoint.Data x, FixedPoint.Data a, FixedPoint.Data y) internal pure returns (FixedPoint.Data) {
		return a.mul(x).sin().div(a).add(x).sub(a.mul(y).sin().div(a).add(y));
	}

	function calcWinnings(FixedPoint.Data playerFrontPercent, FixedPoint.Data playerBackPercent, FixedPoint.Data windowAdjustment, FixedPoint.Data sectionOffset, uint256 gameId, bool isFront) internal view returns (FixedPoint.Data) {
		FixedPoint.Data memory potSize = getAdjustedPotAsFixedPointForGameId(gameId, isFront);
		FixedPoint.Data memory startIntegrationPoint = sectionOffset.add(playerFrontPercent.mul(_pi.div(windowAdjustment)));
		FixedPoint.Data memory endIntegrationPoint = sectionOffset.add(playerBackPercent.mul(_pi.div(windowAdjustment)));
		return integrate(endIntegrationPoint, windowAdjustment, startIntegrationPoint).mul(potSize).mul(windowAdjustment).div(_2pi);
	}

    function computeAmountToMineForBettingRecord (Player.BettingRecord record, bool onlyCurrentGame) internal view returns(uint256 value) {
		if(onlyCurrentGame && record.gameId != currentGameNumber){
			return 0;
		}

		uint256 payout = getPopPayoutForRecord(record).toUInt256Raw();
		return payout.sub(record.withdrawnPopAmount);
    }

    function getPopPayoutForRecord(Player.BettingRecord record) private view returns(FixedPoint.Data value) {
    	
    	if(record.isActive == false) {
    		return FixedPoint.fromInt256(0);
    	}

    	return totalTokenPayout(getPotAsFixedPointForGameId(record.gameId).sub(getInitialSeedAsFixedPointForGameId(record.gameId)), getDifficultyAsFixedPointForGameId(record.gameId), getPopRemainingAsFixedPointForGameId(record.gameId), record.wagerAmount, record.gamePotBeforeBet);  
    }

    function unMinedPop () private view returns(uint256 res) {
    	return totalSupply_.sub(supplyMined_);
    }

    function promisedPop () private view returns(uint256) {
    	FixedPoint.Data memory curPot = getPotAsFixedPointForGameId(currentGameNumber);
    	FixedPoint.Data memory seed = getInitialSeedAsFixedPointForGameId(currentGameNumber);
    	FixedPoint.Data memory difficulty = getDifficultyAsFixedPointForGameId(currentGameNumber);
    	FixedPoint.Data memory unpromised = getPopRemainingAsFixedPointForGameId(currentGameNumber);

    	uint256 promisedPopThisGame = totalTokenPayout(curPot.sub(seed), difficulty, unpromised, currentPot.sub(seed.toUInt256Raw()), 0).toUInt256Raw(); 
    	return totalSupply_.sub(unPromisedSupplyAtStartOfCurrentGame_).add(promisedPopThisGame);
    }

    function unPromisedPop () private view returns(uint256 res) {
    	return totalSupply_.sub(promisedPop());
    }
    
    function potentiallyCirculatingPop () public view returns(uint256 res) {
    	return promisedPop().sub(supplyBurned_);
    }
    
    function minePoP(address target, uint256 amountToMine, uint256 gameId) private {
    	if(supplyMined_ >= totalSupply_) { 
    		return;
    	}

    	uint256 remainingPop = unMinedPop();
    	if(amountToMine == 0 || remainingPop == 0) {
    		return;
    	}

    	if(remainingPop < amountToMine) {
    		amountToMine = remainingPop;
    	}
    	uint256 developerMined = amountToMine.mul(getDeveloperMiningPowerForGameId(gameId)).div(kTotalPercent);
    	uint256 playerMined = amountToMine.sub(developerMined);

    	supplyMined_ = supplyMined_.add(amountToMine);
    	
        popBalances[target] = popBalances[target].add(playerMined);
        popBalances[author] = popBalances[author].add(developerMined);

        emit Mined(target, playerMined);
        emit Transfer(0, target, playerMined);
        emit Mined(author, developerMined);
        emit Transfer(0, author, developerMined);
    }

    function redeemPop (uint256 popToRedeem) public returns(bool res) {
    	require(popBalances[msg.sender] >= popToRedeem);
    	require(popToRedeem != 0);

    	uint256 potentiallyAllocatedPop = potentiallyCirculatingPop();

    	FixedPoint.Data memory redeemRatio = popToRedeem < potentiallyAllocatedPop ? FixedPoint.fromFraction(Int256(popToRedeem), Int256(potentiallyAllocatedPop)) :  FixedPoint.fromInt256(1);
    	FixedPoint.Data memory ethPayoutAmount = redeemRatio.mul(FixedPoint.fromInt256(Int256(totalAmountRaked())));
    	uint256 payout = ethPayoutAmount.toUInt256Raw();
    	require(payout<=totalAmountRaked());
    	require(payout <= address(this).balance);
    	
    	burn(popToRedeem);
    	playerInternalWallet[this] = playerInternalWallet[this].sub(payout);
    	playerInternalWallet[msg.sender] = playerInternalWallet[msg.sender].add(payout);

    	return true;
    }

     
    function totalSupply() public view returns (uint256) {
	    return promisedPop();
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return popBalances[_owner];
	}

	function transfer(address _to, uint256 _value) public returns (bool) {
	    require(_to != address(0));
	    require(_value <= popBalances[msg.sender]);

	     
	    popBalances[msg.sender] = popBalances[msg.sender].sub(_value);
	    popBalances[_to] = popBalances[_to].add(_value);
	    emit Transfer(msg.sender, _to, _value);
	    return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
	    require(_to != address(0));
	    require(_value <= popBalances[_from]);
	    require(_value <= allowed[_from][msg.sender]);

	    popBalances[_from] = popBalances[_from].sub(_value);
	    popBalances[_to] = popBalances[_to].add(_value);
	    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
	    emit Transfer(_from, _to, _value);
	    return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
	    allowed[msg.sender][_spender] = _value;
	    emit Approval(msg.sender, _spender, _value);
	    return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256) {
	    return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
	    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
	    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	    return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
	    uint oldValue = allowed[msg.sender][_spender];
	    if (_subtractedValue > oldValue) {
	      allowed[msg.sender][_spender] = 0;
	    } else {
	      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
	    }
	    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
	    return true;
	}

	function burn(uint256 _value) public {
	    require (popBalances[msg.sender] >= _value);
	    
	    address burner = msg.sender;
	    supplyBurned_ = supplyBurned_.add(_value);
	    popBalances[burner] = popBalances[burner].sub(_value);
	    emit Burn(burner, _value);
	}

	function getInitialSeedAsFixedPointForGameId (uint256 gameId) private view returns(FixedPoint.Data res) {
		if(gameId == currentGameNumber) {
			return FixedPoint.fromInt256(Int256(initialSeed));
		} else {
			WrappedArray.GameMetaDataElement memory elem = gameMetaData.itemAtIndex(gameId);
			return FixedPoint.fromInt256(Int256(elem.seedAmount));
		}
	}

	function getPotAsFixedPointForGameId (uint256 gameId) private view returns(FixedPoint.Data res) {
		if(gameId == currentGameNumber) {
			return FixedPoint.fromInt256(Int256(currentPot));
		} else {
			WrappedArray.GameMetaDataElement memory elem = gameMetaData.itemAtIndex(gameId);
			return FixedPoint.fromInt256(Int256(elem.totalPotAmount));
		}
	}

	function getPopRemainingAsFixedPointForGameId (uint256 gameId) private view returns(FixedPoint.Data res) {
		if(gameId == currentGameNumber) {
			return FixedPoint.fromInt256(Int256(unPromisedSupplyAtStartOfCurrentGame_));
		} else {
			WrappedArray.GameMetaDataElement memory elem = gameMetaData.itemAtIndex(gameId);
			return FixedPoint.fromInt256(Int256(elem.coinsRemaining));
		}
	}
	
	function getDifficultyAsFixedPointForGameId (uint256 gameId) private view returns(FixedPoint.Data res) {
		if(gameId == currentGameNumber) {
			return currentMiningDifficulty;
		} else {
			WrappedArray.GameMetaDataElement memory elem = gameMetaData.itemAtIndex(gameId);
			return elem.miningDifficulty;
		}
	}

	function calcDifficulty() private view returns (FixedPoint.Data) {
		FixedPoint.Data memory total = FixedPoint.fromInt256(0);
		FixedPoint.Data memory count = FixedPoint.fromInt256(0);
		uint256 j = 0;
		for(uint256 i=gameMetaData.length().sub(1) ; i>=0 && j<kDifficultyWindow; i = i.sub(1)){
			WrappedArray.GameMetaDataElement memory thisGame = gameMetaData.itemAtIndex(i);
			FixedPoint.Data memory thisGamePotSize = FixedPoint.fromInt256(Int256(thisGame.totalPotAmount));
			FixedPoint.Data memory thisCount = kDifficultyDropOffFactor.pow(FixedPoint.fromInt256(Int256(j)));
			total = total.add(thisCount.mul(thisGamePotSize));
			count = count.add(thisCount);
			j = j.add(1);
			if(i == 0) {
				break;
			}
		}
		
		return total.div(count).div(kExpectedFirstGameSize);
	}

	function getBrAdj(FixedPoint.Data currentPotValue, FixedPoint.Data expectedGameSize) private pure returns (FixedPoint.Data) {
		if(currentPotValue.cmp(expectedGameSize) == -1) {
		    return expectedGameSize.div(currentPotValue).log10().neg();
		} else {
		    return currentPotValue.div(expectedGameSize).log10();
		}
	}

	function getMiningRateAtPoint(FixedPoint.Data point, FixedPoint.Data difficulty, FixedPoint.Data currentPotValue, FixedPoint.Data coins_tbi) private view returns (FixedPoint.Data) {
		assert (point.cmp(currentPotValue) != 1);
        FixedPoint.Data memory expectedGameSize = kExpectedFirstGameSize.mul(difficulty);
		FixedPoint.Data memory depositRatio = point.div(currentPotValue);
		FixedPoint.Data memory brAdj = getBrAdj(currentPotValue, expectedGameSize);
		if(brAdj.cmp(FixedPoint.fromInt256(0)) == -1) {
			return coins_tbi.mul(FixedPoint.fromInt256(1).div(FixedPoint.fromInt256(2).pow(brAdj.neg()))).mul(FixedPoint.fromInt256(2).sub(depositRatio));
		} else {
			return coins_tbi.mul(FixedPoint.fromInt256(2).pow(brAdj)).mul(FixedPoint.fromInt256(2).sub(depositRatio));
		}
	}

    function getExpectedGameSize() external view returns (int256) {
        return kExpectedFirstGameSize.toInt256();
    }

	function totalTokenPayout(FixedPoint.Data currentPotValue, FixedPoint.Data difficulty, FixedPoint.Data unpromisedPopAtStartOfGame, uint256 wagerAmount, uint256 previousPotSize) private view returns (FixedPoint.Data) {
		FixedPoint.Data memory maxPotSize = kExpectedFirstGameSize.mul(difficulty).mul(kMaxPopMiningPotMultiple);
		FixedPoint.Data memory startPoint = FixedPoint.fromInt256(Int256(previousPotSize));
		if(startPoint.cmp(maxPotSize) != -1){  
			return FixedPoint.fromInt256(0);
		}
		FixedPoint.Data memory endPoint = FixedPoint.fromInt256(Int256(previousPotSize + wagerAmount));
		if(endPoint.cmp(maxPotSize) != -1){
			endPoint = maxPotSize;
			wagerAmount = maxPotSize.sub(startPoint).toUInt256Raw();
		}
		if(currentPotValue.cmp(maxPotSize) != -1){
			currentPotValue = maxPotSize;
		}

		FixedPoint.Data memory betSizePercent = FixedPoint.fromInt256(Int256(wagerAmount)).div(kExpectedFirstGameSize.mul(difficulty));
		FixedPoint.Data memory expectedCoinsToBeIssuedTwoThirds = FixedPoint.fromFraction(2, 3).mul(unpromisedPopAtStartOfGame.mul(kExpectedPopCoinToBePromisedPercent));
		return getMiningRateAtPoint(startPoint.add(endPoint).div(FixedPoint.fromInt256(2)), difficulty, currentPotValue, expectedCoinsToBeIssuedTwoThirds).mul(betSizePercent);
	}

	function calcNumberOfBlocksUntilGameEnds(FixedPoint.Data currentGameSize, FixedPoint.Data targetGameSize) internal view returns (FixedPoint.Data) {
		return kLowerBoundBlocksTillGameEnd.add(kUpperBoundBlocksTillGameEnd.mul(FixedPoint.fromInt256(1).div(currentGameSize.div(targetGameSize).exp())));
	}

	function calcMinimumBetSize(FixedPoint.Data currentGameSize, FixedPoint.Data targetGameSize) internal view returns (FixedPoint.Data) {
		return currentGameInitialMinBetSize.mul(FixedPoint.fromInt256(2).pow(FixedPoint.fromInt256(1).add(currentGameSize.div(targetGameSize)).log10()));
	}
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
}

library SafeInt {

   
  function mul(int256 a, int256 b) internal pure returns (int256) {
    if (a == 0) {
      return 0;
    }
    int256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(int256 a, int256 b) internal pure returns (int256) {
   	 
    int256 c = a / b;
    return c;
  }

   
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    if(a>0 && b<0) {
    	assert (c > a);	
    } else if(a<0 && b>0) {
    	assert (c < a);
    }
   	return c;
  }

   
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    if(a>0 && b>0) {
    	assert(c > a);
    } else if (a < 0 && b < 0) {
    	assert(c < a);
    }
    return c;
  }
}

library WrappedArray {
	using SafeMath for uint256;
	using FixedPoint for FixedPoint.Data;

	struct GameMetaDataElement {
		uint256 totalPotAmount;
		uint256 seedAmount;
		uint256 initialBet;
		uint256 coinsRemaining;
		uint256 developerMiningPower;
		uint256 percentToTakeAsSeed;
		uint256 percentToTakeAsRake;
		uint256 potSplit;
		FixedPoint.Data miningDifficulty;
		FixedPoint.Data frontWindowAdjustmentRatio;
		FixedPoint.Data backWindowAdjustmentRatio;
		bool isActive;
	}

	struct Data {
		GameMetaDataElement[] array;
	}
	
	 
	function push (Data storage self, GameMetaDataElement element) internal  {
		self.array.length = self.array.length.add(1);
		self.array[self.array.length.sub(1)] = element;
	}

	 
	function itemAtIndex (Data storage self, uint256 index) internal view returns(GameMetaDataElement elem) {
		 
		assert(index < self.array.length); 
		return self.array[index];
	}
	
	 
	function length (Data storage self) internal view returns(uint256 len) {
		return self.array.length;
	}
}


library CompactArray {
	using SafeMath for uint256;

	struct Element {
		uint256 elem;
	}
	
	struct Data {
		Element[] array;
		uint256 len;
		uint256 popNextIndex;
	}

	 
	function push (Data storage self, Element element) internal returns(uint256 index)  {
		if(self.array.length == self.len) {
			self.array.length = self.array.length.add(1);
		}
		self.array[self.len] = element;
		self.len = self.len.add(1);
		return self.len.sub(1);
	}

	 
	function removeItemAtIndex (Data storage self, uint256 index) internal {
		 
		assert(index < self.len);

		 
		if(index == self.len.sub(1)) {
			self.len = self.len.sub(1);
			return;
		}

		 
		Element storage temp = self.array[self.len.sub(1)];
		self.array[index] = temp;
		self.len = self.len.sub(1);
	}
	
	 
	function pop (Data storage self) internal returns(Element elem) {
		assert(self.len > 0);

		 
		self.len = self.len.sub(1);

		 
		return self.array[self.len];
	}

	 
	function getNext (Data storage self) internal returns(Element elem) {
		assert(self.len > 0);
			
		if(self.popNextIndex >= self.len) {
			 
			self.popNextIndex = self.len.sub(1);
		}
		Element memory nextElement = itemAtIndex(self, self.popNextIndex);
		
		if(self.popNextIndex == 0) {
			self.popNextIndex = self.len.sub(1);
		} else {
			self.popNextIndex = self.popNextIndex.sub(1);
		}
		return nextElement;
	}
	
	 
	function itemAtIndex (Data storage self, uint256 index) internal view returns(Element elem) {
		 
		assert(index < self.len);
			
		return self.array[index];
	}
	
	 
	function length (Data storage self) internal view returns(uint256 len) {
		return self.len;
	}
	
}


library UIntSet {
	using CompactArray for CompactArray.Data;

	struct SetEntry {
		uint256 index;
		bool active;  
	}
	
	struct Data {
		CompactArray.Data compactArray;
		mapping (uint256 => SetEntry) storedValues;
	}

	 
	function contains (Data storage self, uint256 element) internal view returns(bool res) {
		return self.storedValues[element].active;
	}

	 
	function insert (Data storage self, uint256 element) internal {
		 
		if(contains(self, element)) {
			return;
		}
		 
		CompactArray.Element memory newElem = CompactArray.Element(element);

		 
		uint256 index = self.compactArray.push(newElem);

		 
		SetEntry memory entry = SetEntry(index, true);

		self.storedValues[element] = entry;
	}
	
	
	 
	function removeElement (Data storage self, uint256 element) internal {
		 
		if(contains(self, element) == false) {
			return;
		}

		 
		uint256 index = self.storedValues[element].index;

		 
		self.compactArray.removeItemAtIndex(index);

		 
		self.storedValues[element].active = false;

		 
		if(index < self.compactArray.length()) {
			 
			CompactArray.Element memory swappedElem = self.compactArray.itemAtIndex(index);
			
			 
			self.storedValues[swappedElem.elem] = SetEntry(index, true);
			
		}
	}

	 
	function getNext (Data storage self) internal returns(CompactArray.Element) {
		 
		return self.compactArray.getNext();
	}

	 
	function size (Data storage self) internal view returns(uint256 res) {
		return self.compactArray.length();
	}

	function getItemAtIndex (Data storage self, uint256 index) internal view returns(CompactArray.Element) {
		return self.compactArray.itemAtIndex(index);
	}
	
}

library Player {
	using UIntSet for UIntSet.Data;
	using CompactArray for CompactArray.Data;

	struct BettingRecord {
		address playerAddress;
		uint256 gameId;
		uint256 wagerAmount;
		uint256 bettingRecordId;
		uint256 gamePotBeforeBet;
		uint256 withdrawnAmount;
		uint256 withdrawnPopAmount;
		bool isActive;
	}
	
	struct Data {
		UIntSet.Data bettingRecordIds;
		mapping (uint256 => BettingRecord) bettingRecordMapping;
	}
	
	 
	function containsBettingRecordFromId (Data storage self, uint256 bettingRecordId) internal view returns(bool containsBettingRecord) {
		return self.bettingRecordIds.contains(bettingRecordId);
	}
	

	 
	function getBettingRecordForId (Data storage self, uint256 bettingRecordId) internal view returns(BettingRecord record) {
		if(containsBettingRecordFromId(self, bettingRecordId) == false) {
			return ; 
		}
		return self.bettingRecordMapping[bettingRecordId];
	}
	

	 
	function insertBettingRecord (Data storage self, BettingRecord record) internal {
		 
		self.bettingRecordMapping[record.bettingRecordId] = record;
		self.bettingRecordIds.insert(record.bettingRecordId);
	}
	
	 
	function getNextRecord (Data storage self) internal returns(BettingRecord record) {
		if(self.bettingRecordIds.size() == 0) {
			return ; 
		}
		CompactArray.Element memory bettingRecordIdEntry = self.bettingRecordIds.getNext();
		return self.bettingRecordMapping[bettingRecordIdEntry.elem];
	}

    function getBettingRecordAtIndex (Data storage self, uint256 index) internal view returns(BettingRecord record) {
    	return self.bettingRecordMapping[self.bettingRecordIds.getItemAtIndex(index).elem];
    }
    

	 
	function deleteBettingRecordForId (Data storage self, uint256 bettingRecordId) internal {
		self.bettingRecordIds.removeElement(bettingRecordId);
	}

	 
	function unprocessedBettingRecordCount (Data storage self) internal view returns(uint256 size) {
		return self.bettingRecordIds.size();
	}
}

library BettingRecordArray {
	using Player for Player.Data;
	using SafeMath for uint256;

	struct Data {
		Player.BettingRecord[] array;
		uint256 len;
	}

	function resetIndex (Data storage self) internal {
		self.len = 0;
	}
	
	function pushRecord (Data storage self, Player.BettingRecord record) internal {
		if(self.array.length == self.len) {
			self.array.length = self.array.length.add(1);
		}
		self.array[self.len] = record;
		self.len = self.len.add(1);
	}

	function getNextRecord (Data storage self) internal view returns(Player.BettingRecord record) {
		if(self.array.length == self.len) {
			return;
		}
		return self.array[self.len];
	}	
}


library FixedPoint {
	using SafeMath for uint256;
	using SafeInt for int256;

	int256 constant fracBits = 32;
	int256 constant scale = 1 << 32;
	int256 constant halfScale = scale >> 1;
    int256 constant precision = 1000000;
	int256 constant e = 11674931554;
	int256 constant pi = 13493037704;
	int256 constant _2pi = 26986075409;

	struct Data {
		int256 val;
	}

	function fromInt256(int256 n) internal pure returns (Data) {
		return Data({val: n.mul(scale)});
	}

	function fromFraction(int256 numerator, int256 denominator) internal pure returns (Data) {
		return Data ({
			val: numerator.mul(scale).div(denominator)
		});
	}

	function toInt256(Data n) internal pure returns (int256) {
		return (n.val * precision) >> fracBits;
	}

	function toUInt256Raw(Data a) internal pure returns (uint256) {
		return uint256(a.val >> fracBits);
	}

	function add(Data a, Data b) internal pure returns (Data) {
		return Data({val: a.val.add(b.val)});
	}

	function sub(Data a, Data b) internal pure returns (Data) {
		return Data({val: a.val.sub(b.val)});
	}

	function mul(Data a, Data b) internal pure returns (Data) {
		int256 result = a.val.mul(b.val).div(scale);
		return Data({val: result});
	}

	function div(Data a, Data b) internal pure returns (Data) {
		int256 num = a.val.mul(scale);
		return Data({val: num.div(b.val)});
	}

    function neg(Data a) internal pure returns (Data) {
        return Data({val: -a.val});
    }

	function mod(Data a, Data b) internal pure returns (Data) {
		return Data({val: a.val % b.val});
	}

	function expBySquaring(Data x, Data n) internal pure returns (Data) {
		if(n.val == 0) {  
			return Data({val: scale});
		}
		Data memory extra = Data({val: scale});
		while(true) {
			if(n.val == scale) {  
				return mul(x, extra);
			} else if (n.val % (2*scale) != 0) {
				extra = mul(extra, x);
				n = sub(n, fromInt256(1));
			}
			x = mul(x, x);
			n = div(n, fromInt256(2));
		}
	}

	function sin(Data x) internal pure returns (Data) {
		int256 val = x.val % _2pi;

		if(val < -pi) {
			val += _2pi;
		} else if (val > pi) {
			val -= _2pi;
		}
        Data memory result;
		if(val < 0) {
			result = add(mul(Data({val: 5468522184}), Data({val: val})), mul(Data({val: 1740684682}), mul(Data({val: val}), Data({val: val}))));
			if(result.val < 0) {
				result = add(mul(Data({val: 966367641}), sub(mul(result, neg(result)), result)), result);
			} else {
				result = add(mul(Data({val: 966367641}), sub(mul(result, result), result)), result);
			}
			return result;
		} else {
			result = sub(mul(Data({val: 5468522184}), Data({val: val})), mul(Data({val: 1740684682}), mul(Data({val: val}), Data({val: val})))); 
			if(result.val < 0) {
				result = add(mul(Data({val: 966367641}), sub(mul(result, neg(result)), result)), result);
			} else {
				result = add(mul(Data({val: 966367641}), sub(mul(result, result), result)), result);
			}
			return result;
		}
	}

	function cmp(Data a, Data b) internal pure returns (int256) {
		if(a.val > b.val) {
			return 1;
		} else if(a.val < b.val) {
			return -1;
		} else {
			return 0;
		}
	}

	function log10(Data a) internal pure returns (Data) {
	    return div(ln(a), ln(fromInt256(10)));
	}

	function ln(Data a) internal pure returns (Data) {
		int256 LOG = 0;
		int256 prec = 1000000;
		int256 x = a.val.mul(prec) >> fracBits;

		while(x >= 1500000) {
			LOG = LOG.add(405465);
			x = x.mul(2).div(3);
		}
		x = x.sub(prec);
        int256 y = x;
        int256 i = 1;
        while (i < 10){
            LOG = LOG.add(y.div(i));
            i = i.add(1);
            y = x.mul(y).div(prec);
            LOG = LOG.sub(y.div(i));
            i = i.add(1);
            y = x.mul(y).div(prec);
        }
        LOG = LOG.mul(scale);
        LOG = LOG.div(prec);
        return Data({val: LOG});
	}

	function expRaw(Data a) internal pure returns (Data) {
		int256 l1 = scale.add(a.val.div(4));
		int256 l2 = scale.add(a.val.div(3).mul(l1).div(scale));
		int256 l3 = scale.add(a.val.div(2).mul(l2).div(scale));
		int256 l4 = scale.add(a.val.mul(l3).div(scale));

		return Data({val: l4});
	}

	function exp(Data a) internal pure returns (Data) {
		int256 pwr = a.val >> fracBits;
		int256 frac = a.val.sub(pwr << fracBits);

		return mul(expRaw(Data({val: frac})), expBySquaring(Data({val: e}), fromInt256(pwr)));
	}

	function pow(Data base, Data power) internal pure returns (Data) {
		int256 intpwr = power.val >> 32;
		int256 frac = power.val.sub(intpwr << fracBits);
		return mul(expRaw(mul(Data({val:frac}), ln(base))), expBySquaring(base, fromInt256(intpwr)));
	}
}