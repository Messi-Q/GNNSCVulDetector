pragma solidity ^0.4.21;

 
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
         
         
         
        return a / b;
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

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

 
contract StandardToken {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) internal balances_;
    mapping(address => mapping(address => uint256)) internal allowed_;

    uint256 internal totalSupply_;
    string public name;
    string public symbol;
    uint8 public decimals;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances_[_owner];
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed_[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances_[msg.sender]);

        balances_[msg.sender] = balances_[msg.sender].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances_[_from]);
        require(_value <= allowed_[_from][msg.sender]);

        balances_[_from] = balances_[_from].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

 
contract EthTeamContract is StandardToken, Ownable {
    event Buy(address indexed token, address indexed from, uint256 value, uint256 weiValue);
    event Sell(address indexed token, address indexed from, uint256 value, uint256 weiValue);
    event BeginGame(address indexed team1, address indexed team2, uint64 gameTime);
    event EndGame(address indexed team1, address indexed team2, uint8 gameResult);
    event ChangeStatus(address indexed team, uint8 status);

     
    uint256 public price;
     
    uint8 public status;
     
    uint64 public gameTime;
     
    uint64 public finishTime;
     
    address public feeOwner;
     
    address public gameOpponent;

     
    function EthTeamContract(
        string _teamName, string _teamSymbol, address _gameOpponent, uint64 _gameTime, uint64 _finishTime, address _feeOwner
    ) public {
        name = _teamName;
        symbol = _teamSymbol;
        decimals = 3;
        totalSupply_ = 0;
        price = 1 szabo;
        gameOpponent = _gameOpponent;
        gameTime = _gameTime;
        finishTime = _finishTime;
        feeOwner = _feeOwner;
        owner = msg.sender;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if (_to != address(this)) {
            return super.transfer(_to, _value);
        }
        require(_value <= balances_[msg.sender] && status == 0);
         
        if (gameTime > 1514764800) {
             
            require(gameTime > block.timestamp);
        }
        balances_[msg.sender] = balances_[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        uint256 weiAmount = price.mul(_value);
        msg.sender.transfer(weiAmount);
        emit Transfer(msg.sender, _to, _value);
        emit Sell(_to, msg.sender, _value, weiAmount);
        return true;
    }

     
    function() payable public {
        require(status == 0 && price > 0);
         
        if (gameTime > 1514764800) {
             
            require(gameTime > block.timestamp);
        }
        uint256 amount = msg.value.div(price);
        balances_[msg.sender] = balances_[msg.sender].add(amount);
        totalSupply_ = totalSupply_.add(amount);
        emit Transfer(address(this), msg.sender, amount);
        emit Buy(address(this), msg.sender, amount, msg.value);
    }

     
    function changeStatus(uint8 _status) onlyOwner public {
        require(status != _status);
        status = _status;
        emit ChangeStatus(address(this), _status);
    }

     
    function changeFeeOwner(address _feeOwner) onlyOwner public {
        require(_feeOwner != feeOwner && _feeOwner != address(0));
        feeOwner = _feeOwner;
    }

     
    function finish() onlyOwner public {
        require(block.timestamp >= finishTime);
        feeOwner.transfer(address(this).balance);
    }

     
    function beginGame(address _gameOpponent, uint64 _gameTime) onlyOwner public {
        require(_gameOpponent != address(this));
         
        require(_gameTime == 0 || (_gameTime > 1514764800));
        gameOpponent = _gameOpponent;
        gameTime = _gameTime;
        status = 0;
        emit BeginGame(address(this), _gameOpponent, _gameTime);
    }

     
    function endGame(address _gameOpponent, uint8 _gameResult) onlyOwner public {
        require(gameOpponent != address(0) && gameOpponent == _gameOpponent);
        uint256 amount = address(this).balance;
        uint256 opAmount = gameOpponent.balance;
        require(_gameResult == 1 || (_gameResult == 2 && amount >= opAmount) || _gameResult == 3);
        EthTeamContract op = EthTeamContract(gameOpponent);
        if (_gameResult == 1) {
             
            if (amount > 0 && totalSupply_ > 0) {
                uint256 lostAmount = amount;
                 
                if (op.totalSupply() > 0) {
                     
                    uint256 feeAmount = lostAmount.div(20);
                    lostAmount = lostAmount.sub(feeAmount);
                    feeOwner.transfer(feeAmount);
                    op.transferFundAndEndGame.value(lostAmount)();
                } else {
                     
                    feeOwner.transfer(lostAmount);
                    op.transferFundAndEndGame();
                }
            } else {
                op.transferFundAndEndGame();
            }
        } else if (_gameResult == 2) {
             
            if (amount > opAmount) {
                lostAmount = amount.sub(opAmount).div(2);
                if (op.totalSupply() > 0) {
                     
                    feeAmount = lostAmount.div(20);
                    lostAmount = lostAmount.sub(feeAmount);
                    feeOwner.transfer(feeAmount);
                    op.transferFundAndEndGame.value(lostAmount)();
                } else {
                    feeOwner.transfer(lostAmount);
                    op.transferFundAndEndGame();
                }
            } else if (amount == opAmount) {
                op.transferFundAndEndGame();
            } else {
                 
                revert();
            }
        } else if (_gameResult == 3) {
             
            op.transferFundAndEndGame();
        } else {
             
            revert();
        }
        endGameInternal();
        if (totalSupply_ > 0) {
            price = address(this).balance.div(totalSupply_);
        }
        emit EndGame(address(this), _gameOpponent, _gameResult);
    }

     
    function endGameInternal() private {
        gameOpponent = address(0);
        gameTime = 0;
        status = 0;
    }

     
    function transferFundAndEndGame() payable public {
        require(gameOpponent != address(0) && gameOpponent == msg.sender);
        if (msg.value > 0 && totalSupply_ > 0) {
            price = address(this).balance.div(totalSupply_);
        }
        endGameInternal();
    }
}