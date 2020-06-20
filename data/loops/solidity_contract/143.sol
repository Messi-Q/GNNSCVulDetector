pragma solidity ^0.4.23;


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Crowdsale {
    using SafeMath for uint256;

     
    ERC20 public token;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = _token;
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
        msg.sender,
        _beneficiary,
        weiAmount,
        tokens
        );

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

     
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate);
    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}


 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
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


 
contract PenCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

     
    mapping(address => uint256) public balances;

     
    uint256 public tokensIssued;

     
    uint256 public bonusMultiplier;

     
    bool public closed;

     
    event TokenDelivered(address indexed receiver, uint256 amount);

     
    event TokenAdded(address indexed beneficiary, uint256 amount);

     
    function PenCrowdsale(
        uint256 _rate,
        address _wallet,
        ERC20 _token,
        uint256 _bonusMultiplier
    ) Crowdsale(
        _rate,
        _wallet,
        _token
    ) {
        bonusMultiplier = _bonusMultiplier;
    }

     
    function withdrawTokens() public {
        _withdrawTokensFor(msg.sender);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        require(!hasClosed());
        balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
        tokensIssued = tokensIssued.add(_tokenAmount);
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate).mul(bonusMultiplier).div(1000);
    }

     
    function withdrawTokensFor(address receiver_) public onlyOwner {
        _withdrawTokensFor(receiver_);
    }

     
    function hasClosed() public view returns (bool) {
        return closed;
    }

     
    function closeCrowdsale(bool closed_) public onlyOwner {
        closed = closed_;
    }

     
    function setBonusMultiplier(uint256 bonusMultiplier_) public onlyOwner {
        bonusMultiplier = bonusMultiplier_;
    }

     
    function postCrowdsaleWithdraw(uint256 _tokenAmount) public onlyOwner {
        token.transfer(wallet, _tokenAmount);
    }

     
    function addTokens(address _beneficiary, uint256 _tokenAmount) public onlyOwner {
        balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
        tokensIssued = tokensIssued.add(_tokenAmount);
        emit TokenAdded(_beneficiary, _tokenAmount);
    }

     
    function _withdrawTokensFor(address receiver_) internal {
        require(hasClosed());
        uint256 amount = balances[receiver_];
        require(amount > 0);
        balances[receiver_] = 0;
        emit TokenDelivered(receiver_, amount);
        _deliverTokens(receiver_, amount);
    }
}