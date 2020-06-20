pragma solidity ^0.4.13;

contract Crowdsale {
    using SafeMath for uint256;

    address constant public TOKEN_OWNER = 0x57Cdd07287f668eC4D58f3E362b4FCC2bC54F5b8;  
    address constant public WALLET = 0x1513F644590d866e25490687AB1b3Ad262d5b6dF;  
    uint256 constant public MINSALESCAP = 200 ether;
    uint256 constant public MAXSALESCAP = 126000 ether;
    uint256 constant public STARTDATE = 1533686401;  
    uint256 constant public ENDDATE = 1543536060;  
    uint256 constant public FXRATE = 50000;
    uint256 constant public MINCONTRIBUTION = 5000000000000 wei;  

     
    address public TOKEN;
    address public owner;
    uint256 public weiRaised;

    enum State { Running, Expired, Funded }
    State public state;

    struct ContributorStruct {
        bool whitelisted;
        uint256 contributions;
    }
    mapping(address => ContributorStruct) public whitelist;

    modifier isContributor() {require(whitelist[msg.sender].contributions > 0x00); _;}
    modifier isOwner() {require(msg.sender == owner); _;}
    modifier inState(State _state) {require(state == _state); _;}
    modifier inPaymentLimits(uint256 _payment) {require(_payment >= MINCONTRIBUTION); _;}
    modifier inWhitelist(address _contributor) {require(whitelist[_contributor].whitelisted == true); _;}

    event WhitelistingLog(address indexed _contributor);
    event RefundLog(address indexed _contributor, uint256 _amount);
    event PurchaseLog(address indexed _contributor, address indexed _beneficiary, uint256 _amount);

    constructor (address _token) public {
        require(_token != address(0x00));

        owner = msg.sender;
        TOKEN = _token;
    }

    function () public payable {
        _updateStateIfExpired();
    }

     
    function buyTokens(address _beneficiary)
        public
        inState(State.Running)
        inPaymentLimits(msg.value)
        inWhitelist(_beneficiary)
        payable
        returns (bool success)
    {
        require(_beneficiary != address(0x00));

        assert(block.timestamp >= STARTDATE);  

        uint256 tokenAmount = _calculateTokenAmount(msg.value);
        YOUToken token = YOUToken(TOKEN);

        weiRaised = weiRaised.add(msg.value);
        whitelist[_beneficiary].contributions = whitelist[_beneficiary].contributions.add(msg.value);
        if (!token.mint.gas(700000)(_beneficiary, tokenAmount)) {
            return false;
        }

        if (weiRaised >= MAXSALESCAP
            || weiRaised >= MINSALESCAP && block.timestamp >= ENDDATE) {
            state = State.Funded;
        } else {
            _updateStateIfExpired();
        }

        emit PurchaseLog(msg.sender, _beneficiary, msg.value);
        return true;
    }

     
     
    function refund(address _contributor)
        public
        isContributor
        inState(State.Expired)
        returns (bool success)
    {
        require(_contributor != address(0x00));

        uint256 amount = whitelist[_contributor].contributions;
        whitelist[_contributor].contributions = 0x00;

        _contributor.transfer(amount);

        emit RefundLog(_contributor, amount);
        return true;
    }

     
    function whitelistAddr(address _contributor)
        public
        isOwner
        returns(bool)
    {
        require(_contributor != address(0x00));

         
        whitelist[_contributor].whitelisted = true;

        emit WhitelistingLog(_contributor);
        return true;
    }

     
     
    function whitelistAddrAndBuyTokens(address _contributor, uint256 _weiAmount)
        public
        isOwner
        returns(bool)
    {
        require(_contributor != address(0x00));

        uint256 tokenAmount = _calculateTokenAmount(_weiAmount);
        YOUToken token = YOUToken(TOKEN);

        whitelist[_contributor].whitelisted = true;
        weiRaised = weiRaised.add(_weiAmount);
        if (!token.mint.gas(700000)(_contributor, tokenAmount)) {
            return false;
        }

        emit WhitelistingLog(_contributor);
        return true;
    }

     
    function withdraw() public isOwner inState(State.Funded) {
        WALLET.transfer(address(this).balance);
    }

    function delistAddress(address _contributor)
        public
        isOwner
        inState(State.Running)
        returns (bool)
    {
        require(_contributor != address(0x00));
        require(whitelist[_contributor].whitelisted);

        whitelist[_contributor].whitelisted = false;

        return true;
    }

    function emergencyStop()
        public
        isOwner
        inState(State.Running)
    {
         
        state = State.Expired;
    }

    function transferOwnership()
        public
        isOwner
        inState(State.Running)
    {
         
        owner = TOKEN_OWNER;
    }

    function _updateStateIfExpired() internal {
        if ((block.timestamp >= ENDDATE && state == State.Running)
            || (block.timestamp >= ENDDATE && weiRaised < MINSALESCAP)) {
            state = State.Expired;
        }
    }

    function _calculateTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256 tokenAmount)
    {
        uint256 discount;
        if (block.timestamp <= 1535241660) {
            if (_weiAmount >= 1700 ether) {
                discount = 30;
            } else if (_weiAmount > 0.2 ether) {
                discount = 25;
            }
        } else if (block.timestamp <= 1537747260) {
            discount = 15;
        } else if (block.timestamp <= 1540339260) {
            discount = 10;
        } else if (block.timestamp <= 1543536060) {
            discount = 5;
        }

        _weiAmount = _weiAmount.mul(discount).div(100).add(_weiAmount);

        return _weiAmount.mul(FXRATE);
    }
}

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

}

contract YOUToken {
    function mint(address _to, uint256 _amount) public returns (bool);
    function transferOwnership(address _newOwner) public;
}