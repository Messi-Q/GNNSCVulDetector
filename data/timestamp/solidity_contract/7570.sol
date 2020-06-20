pragma solidity ^0.4.18;

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
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

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

contract WhitelistedCrowdsale is Crowdsale, Ownable {

    mapping(address => bool) public whitelist;

     
    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }

     
    function addToWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = true;
    }

     
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

     
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

}


contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
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

}


contract GStarToken is StandardToken, Ownable {
    using SafeMath for uint256;

    string public constant name = "GSTAR Token";
    string public constant symbol = "GSTAR";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1600000000 * ((10 ** uint256(decimals)));
    uint256 public currentTotalSupply = 0;

    event Burn(address indexed burner, uint256 value);


     
    function GStarToken() public {
        owner = msg.sender;
        totalSupply_ = INITIAL_SUPPLY;
        balances[owner] = INITIAL_SUPPLY;
        currentTotalSupply = INITIAL_SUPPLY;
        emit Transfer(address(0), owner, INITIAL_SUPPLY);
    }

     
    function burn(uint256 value) public onlyOwner {
        require(value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(value);
        currentTotalSupply = currentTotalSupply.sub(value);
        emit Burn(burner, value);
    }
}


 
contract GStarCrowdsale is WhitelistedCrowdsale {
    using SafeMath for uint256;

     
     
    uint256 constant public presaleStartTime = 1531051200;  
    uint256 constant public startTime = 1532260800;  
    uint256 constant public endTime = 1534593600;  

     
    mapping (address => uint256) public depositedTokens;

     
     
    uint256 constant public MINIMUM_PRESALE_PURCHASE_AMOUNT_IN_WEI = 1 ether;
    uint256 constant public MINIMUM_PURCHASE_AMOUNT_IN_WEI = 0.1 ether;

     
    uint256 public tokensWeiRaised = 0;

     
    uint256 constant public fundingGoal = 76000 ether;
    uint256 constant public presaleFundingGoal = 1000 ether;
    bool public fundingGoalReached = false;
    bool public presaleFundingGoalReached = false;

     
    uint256 public privateContribution = 0;

     
    bool public crowdsaleActive = false;
    bool public isCrowdsaleClosed = false;

    uint256 public tokensReleasedAmount = 0;


     
     
     

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event GoalReached(uint256 totalEtherAmountRaised);
    event PresaleGoalReached(uint256 totalEtherAmountRaised);
    event StartCrowdsale();
    event StopCrowdsale();
    event ReleaseTokens(address[] _beneficiaries);
    event Close();

     
    function GStarCrowdsale (
        uint256 _rate,
        address _wallet,
        GStarToken token
        ) public Crowdsale(_rate, _wallet, token) {
    }


     
     
     

     
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);
        
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _processPurchase(_beneficiary, weiAmount);
    }

     
    function getRate() public view returns (uint256) {
         
        if (block.timestamp <= startTime) { return ((rate / 100) * 120); }  
        if (block.timestamp <= startTime.add(1 days)) {return ((rate / 100) * 108);}  

        return rate;
    }


     
     
     

     
    function changePrivateContribution(uint256 etherWeiAmount) external onlyOwner {
        privateContribution = etherWeiAmount;
    }

     
    function startCrowdsale() external onlyOwner {
        require(!crowdsaleActive);
        require(!isCrowdsaleClosed);

        crowdsaleActive = true;
        emit StartCrowdsale();
    }

     
    function stopCrowdsale() external onlyOwner {
        require(crowdsaleActive);
        crowdsaleActive = false;
        emit StopCrowdsale();
    }

     
    function releaseTokens(address[] contributors) external onlyOwner {

        for (uint256 j = 0; j < contributors.length; j++) {

             
            uint256 tokensAmount = depositedTokens[contributors[j]];

            if (tokensAmount > 0) {
                super._deliverTokens(contributors[j], tokensAmount);

                depositedTokens[contributors[j]] = 0;

                 
                tokensReleasedAmount = tokensReleasedAmount.add(tokensAmount);
            }
        }
    }

     
    function close() external onlyOwner {
        crowdsaleActive = false;
        isCrowdsaleClosed = true;
        
        token.transfer(owner, token.balanceOf(address(this)));
        emit Close();
    }


     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        bool withinPeriod = now >= presaleStartTime && now <= endTime;

        bool atLeastMinimumAmount = false;

        if(block.timestamp <= startTime) {
             

            require(_weiAmount.add(weiRaised.add(privateContribution)) <= presaleFundingGoal);
            atLeastMinimumAmount = _weiAmount >= MINIMUM_PRESALE_PURCHASE_AMOUNT_IN_WEI;
            
        } else {
             
            atLeastMinimumAmount = _weiAmount >= MINIMUM_PURCHASE_AMOUNT_IN_WEI;
        }

        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(msg.sender == _beneficiary);
        require(_weiAmount.add(weiRaised.add(privateContribution)) <= fundingGoal);
        require(withinPeriod);
        require(atLeastMinimumAmount);
        require(crowdsaleActive);
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(getRate());
    }

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        tokensWeiRaised = tokensWeiRaised.add(_getTokenAmount(_weiAmount));
        _updateFundingGoal();
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        depositedTokens[_beneficiary] = depositedTokens[_beneficiary].add(_getTokenAmount(_tokenAmount));
    }

     
    function _updateFundingGoal() internal {
        if (weiRaised.add(privateContribution) >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(weiRaised.add(privateContribution));
        }

        if(block.timestamp <= startTime) {
            if(weiRaised.add(privateContribution) >= presaleFundingGoal) {
                
                presaleFundingGoalReached = true;
                emit PresaleGoalReached(weiRaised.add(privateContribution));
            }
        }
    }



}