pragma solidity ^0.4.19;

 

contract EthKing {
	using SafeMath for uint256;

	 

	event NewRound(
		uint _timestamp,
		uint _round,
		uint _initialMainPot,
		uint _initialBonusPot
  );

	event NewKingBid(
		uint _timestamp,
		address _address,
		uint _amount,
		uint _newMainPot,
		uint _newBonusPot
	);

	event PlaceChange(
		uint _timestamp,
		address _newFirst,
		address _newSecond,
		uint _firstPoints,
		uint _secondPoints
	);

	event Winner(
		uint _timestamp,
		address _first,
		uint _firstAmount,
		address _second,
		uint _secondAmount
	);

	event EarningsWithdrawal(
		uint _timestamp,
		address _address,
		uint _amount
	);

	 

	address owner;

	 

	 
	 
	uint private constant NEXT_POT_FRAC_TOP = 1;
	uint private constant NEXT_POT_FRAC_BOT = 2;

	 
	 
	uint private constant MIN_LEADER_FRAC_TOP = 5;
	uint private constant MIN_LEADER_FRAC_BOT = 1000;

	 
	uint private constant BONUS_POT_FRAC_TOP = 20;
	uint private constant BONUS_POT_FRAC_BOT = 100;

	 
	uint private constant DEV_FEE_FRAC_TOP = 5;
	uint private constant DEV_FEE_FRAC_BOT = 100;

	 
	 
	uint private constant POINT_EXPONENT = 2;

	 
	uint private constant POINTS_TO_WIN = 1000000;
	
	 
    address null_address = address(0x0);

	 

	 
	address public king;
	uint public crownedTime;

	 
	address public first;
	address public second;

	 
	struct Player {
		uint points;
		uint roundLastPlayed;
		uint winnings;
	}

	 
	mapping (address => Player) private players;

	 
	uint public round;

	 
	uint public mainPot;
	uint public bonusPot;

	 

	function EthKing() public payable {
		 
		require(msg.value > 0);

		 
		owner = msg.sender;
		round = 1;

		 
		uint _bonusPot = msg.value.mul(BONUS_POT_FRAC_TOP).div(BONUS_POT_FRAC_BOT);
		uint _mainPot = msg.value.sub(_bonusPot);

		 
		require(_bonusPot + _mainPot <= msg.value);

		mainPot = _mainPot;
		bonusPot = _bonusPot;

		 
		 
		king = owner;
		first = null_address;
		second = null_address;
		crownedTime = now;
		players[owner].roundLastPlayed = round;
        players[owner].points = 0;
	}

	 
	 
	modifier payoutOldKingPoints {
		uint _pointsToAward = calculatePoints(crownedTime, now);
		players[king].points = players[king].points.add(_pointsToAward);

		 
		 
		 
		if (players[king].points > players[first].points) {
			second = first;
			first = king;

			PlaceChange(now, first, second, players[first].points, players[second].points);

		} else if (players[king].points > players[second].points && king != first) {
			second = king;

			PlaceChange(now, first, second, players[first].points, players[second].points);
		}

		_;
	}

	 
	 
	 
	modifier advanceRoundIfNeeded {
		if (players[first].points >= POINTS_TO_WIN) {
			 
			uint _nextMainPot = mainPot.mul(NEXT_POT_FRAC_TOP).div(NEXT_POT_FRAC_BOT);
			uint _nextBonusPot = bonusPot.mul(NEXT_POT_FRAC_TOP).div(NEXT_POT_FRAC_BOT);

			uint _firstEarnings = mainPot.sub(_nextMainPot);
			uint _secondEarnings = bonusPot.sub(_nextBonusPot);

			players[first].winnings = players[first].winnings.add(_firstEarnings);
			players[second].winnings = players[second].winnings.add(_secondEarnings);

			 
			round++;
			mainPot = _nextMainPot;
			bonusPot = _nextBonusPot;

			 
			first = null_address;
			second = null_address;
			players[owner].roundLastPlayed = round;
			players[owner].points = 0;
			players[king].roundLastPlayed = round;
			players[king].points = 0;
			king = owner;
			crownedTime = now;

			NewRound(now, round, mainPot, bonusPot);
			PlaceChange(now, first, second, players[first].points, players[second].points);
		}

		_;
	}

	 
	function calculatePoints(uint _earlierTime, uint _laterTime) private pure returns (uint) {
		 
		 
		assert(_earlierTime <= _laterTime);

		 
		if (_earlierTime == _laterTime) { return 0; }

		 
		uint timeElapsedInSeconds = _laterTime.sub(_earlierTime);
		if (timeElapsedInSeconds < 60) { return 0; }

		uint timeElapsedInMinutes = timeElapsedInSeconds.div(60);
		assert(timeElapsedInMinutes > 0);

		 
		if (timeElapsedInMinutes >= 1000) { return POINTS_TO_WIN; }

		return timeElapsedInMinutes**POINT_EXPONENT;
	}

	 
	 
	 
	 
	function becomeKing() public payable
		payoutOldKingPoints
		advanceRoundIfNeeded
	{
		 
		uint _minLeaderAmount = mainPot.mul(MIN_LEADER_FRAC_TOP).div(MIN_LEADER_FRAC_BOT);
		require(msg.value >= _minLeaderAmount);

		uint _bidAmountToDeveloper = msg.value.mul(DEV_FEE_FRAC_TOP).div(DEV_FEE_FRAC_BOT);
		uint _bidAmountToBonusPot = msg.value.mul(BONUS_POT_FRAC_TOP).div(BONUS_POT_FRAC_BOT);
		uint _bidAmountToMainPot = msg.value.sub(_bidAmountToDeveloper).sub(_bidAmountToBonusPot);

		assert(_bidAmountToDeveloper + _bidAmountToBonusPot + _bidAmountToMainPot <= msg.value);

		 
		players[owner].winnings = players[owner].winnings.add(_bidAmountToDeveloper);

		 
		mainPot = mainPot.add(_bidAmountToMainPot);
		bonusPot = bonusPot.add(_bidAmountToBonusPot);

		 
		if (players[king].roundLastPlayed != round) {
			players[king].points = 0;	
		}
		
		 
		king = msg.sender;
		players[king].roundLastPlayed = round;
		crownedTime = now;

		NewKingBid(now, king, msg.value, mainPot, bonusPot);
	}

	 
	function withdrawEarnings() public {
		require(players[msg.sender].winnings > 0);
		assert(players[msg.sender].winnings <= this.balance);

		uint _amount = players[msg.sender].winnings;
		players[msg.sender].winnings = 0;

		EarningsWithdrawal(now, msg.sender, _amount);

		msg.sender.transfer(_amount);
	}

	 
	 
	 
	function () public payable {
		if (msg.value == 0) { tryAdvance(); }
		else { becomeKing(); }
	}

	 
	function tryAdvance() public {
		 
		 
		 
		uint kingTotalPoints = calculatePoints(crownedTime, now) + players[king].points;
		if (kingTotalPoints >= POINTS_TO_WIN) { forceAdvance(); }
	}

	 
	function forceAdvance() private payoutOldKingPoints advanceRoundIfNeeded { }
	
	 
	function getPlayerInfo(address _player) public constant returns(uint, uint, uint) {
		return (players[_player].points, players[_player].roundLastPlayed, players[_player].winnings);
	}
	
	 
	function getMyInfo() public constant returns(uint, uint, uint) {
		return getPlayerInfo(msg.sender);		
	}
	
	 
	function getKingPoints() public constant returns(uint) { return players[king].points; }
	
	 
	function getFirstPoints() public constant returns(uint) { return players[first].points; }
	
	 
	function getSecondPoints() public constant returns(uint) { return players[second].points; }
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