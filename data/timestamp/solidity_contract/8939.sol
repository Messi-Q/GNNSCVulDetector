pragma solidity ^0.4.18;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        uint256 c = a * b;

        assert(a == 0 || c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        assert(b <= a);

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure
        returns (uint256)
    {
        uint256 c = a + b;

        assert(c >= a);

        return c;
    }
}

 
contract Ownable
{
    address owner;

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

interface tokenRecipient
{
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

contract TokenERC20 is Ownable
{
    using SafeMath for uint;

     
    string public name;
    string public symbol;
    uint256 public decimals = 18;
    uint256 DEC = 10 ** uint256(decimals);
    uint256 public totalSupply;
    uint256 public avaliableSupply;
    uint256 public buyPrice = 1000000000000000000 wei;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public
    {
        totalSupply = initialSupply.mul(DEC);   
        balanceOf[this] = totalSupply;          
        avaliableSupply = balanceOf[this];      
        name = tokenName;                       
        symbol = tokenSymbol;                   
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal
    {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
         
        balanceOf[_from] = balanceOf[_from].sub(_value);
         
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public
    {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public
        returns (bool success)
    {
        require(_value <= allowance[_from][msg.sender]);      

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;

        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public onlyOwner
        returns (bool success)
    {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);

            return true;
        }
    }

     
    function increaseApproval (address _spender, uint _addedValue) public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public
        returns (bool success)
    {
        uint oldValue = allowance[msg.sender][_spender];

        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

     
    function burn(uint256 _value) public onlyOwner
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value);    

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);   
        totalSupply = totalSupply.sub(_value);                       
        avaliableSupply = avaliableSupply.sub(_value);

        emit Burn(msg.sender, _value);

        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public onlyOwner
        returns (bool success)
    {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     

        balanceOf[_from] = balanceOf[_from].sub(_value);     
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);     
        totalSupply = totalSupply.sub(_value);               
        avaliableSupply = avaliableSupply.sub(_value);

        emit Burn(_from, _value);

        return true;
    }
}

contract ERC20Extending is TokenERC20
{
    using SafeMath for uint;

     
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner
    {
        _to.transfer(amount);
    }

     
    function transferTokensFromContract(address _to, uint256 _value) public onlyOwner
    {
        avaliableSupply = avaliableSupply.sub(_value);
        _transfer(this, _to, _value);
    }
}

contract Pauseble is TokenERC20
{
    event EPause();
    event EUnpause();

    bool public paused = true;
    uint public startIcoDate = 0;

    modifier whenNotPaused()
    {
        require(!paused);
        _;
    }

    modifier whenPaused()
    {
        require(paused);
        _;
    }

    function pause() public onlyOwner
    {
        paused = true;
        emit EPause();
    }

    function pauseInternal() internal
    {
        paused = true;
        emit EPause();
    }

    function unpause() public onlyOwner
    {
        paused = false;
        emit EUnpause();
    }

    function unpauseInternal() internal
    {
        paused = false;
        emit EUnpause();
    }
}

contract StreamityCrowdsale is Pauseble
{
    using SafeMath for uint;

    uint public stage = 0;

    event CrowdSaleFinished(string info);

    struct Ico {
        uint256 tokens;              
        uint startDate;              
        uint endDate;                
        uint8 discount;              
        uint8 discountFirstDayICO;   
    }

    Ico public ICO;

     
    function changeRate(uint256 _numerator, uint256 _denominator) public onlyOwner
        returns (bool success)
    {
        if (_numerator == 0) _numerator = 1;
        if (_denominator == 0) _denominator = 1;

        buyPrice = (_numerator.mul(DEC)).div(_denominator);

        return true;
    }

     
    function crowdSaleStatus() internal constant
        returns (string)
    {
        if (1 == stage) {
            return "Pre-ICO";
        } else if(2 == stage) {
            return "ICO first stage";
        } else if (3 == stage) {
            return "ICO second stage";
        } else if (4 >= stage) {
            return "feature stage";
        }

        return "there is no stage at present";
    }

     
    function sell(address _investor, uint256 amount) internal
    {
        uint256 _amount = (amount.mul(DEC)).div(buyPrice);

        if (1 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }
        else if (2 == stage)
        {
            if (now <= ICO.startDate + 1 days)
            {
                  if (0 == ICO.discountFirstDayICO) {
                      ICO.discountFirstDayICO = 20;
                  }

                  _amount = _amount.add(withDiscount(_amount, ICO.discountFirstDayICO));
            } else {
                _amount = _amount.add(withDiscount(_amount, ICO.discount));
            }
        } else if (3 == stage) {
            _amount = _amount.add(withDiscount(_amount, ICO.discount));
        }

        if (ICO.tokens < _amount)
        {
            emit CrowdSaleFinished(crowdSaleStatus());
            pauseInternal();

            revert();
        }

        ICO.tokens = ICO.tokens.sub(_amount);
        avaliableSupply = avaliableSupply.sub(_amount);

        _transfer(this, _investor, _amount);
    }

     
    function startCrowd(uint256 _tokens, uint _startDate, uint _endDate, uint8 _discount, uint8 _discountFirstDayICO) public onlyOwner
    {
        require(_tokens * DEC <= avaliableSupply);   
        startIcoDate = _startDate;
        ICO = Ico (_tokens * DEC, _startDate, _startDate + _endDate * 1 days , _discount, _discountFirstDayICO);
        stage = stage.add(1);
        unpauseInternal();
    }

     
    function transferWeb3js(address _investor, uint256 _amount) external onlyOwner
    {
        sell(_investor, _amount);
    }

     
    function withDiscount(uint256 _amount, uint _percent) internal pure
        returns (uint256)
    {
        return (_amount.mul(_percent)).div(100);
    }
}

contract StreamityContract is ERC20Extending, StreamityCrowdsale
{
    using SafeMath for uint;

    uint public weisRaised;   

     
    function StreamityContract() public TokenERC20(130000000, "Streamity", "STM") {}  

     
    function () public payable
    {
        assert(msg.value >= 1 ether / 10);
        require(now >= ICO.startDate);

        if (now >= ICO.endDate) {
            pauseInternal();
            emit CrowdSaleFinished(crowdSaleStatus());
        }


        if (0 != startIcoDate) {
            if (now < startIcoDate) {
                revert();
            } else {
                startIcoDate = 0;
            }
        }

        if (paused == false) {
            sell(msg.sender, msg.value);
            weisRaised = weisRaised.add(msg.value);
        }
    }
}

 
contract ReentrancyGuard {

   
  bool private reentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}

contract ContractToken {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
}

contract StreamityEscrow is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using ECRecovery for bytes32;

    uint8 constant public STATUS_NO_DEAL = 0x0;
    uint8 constant public STATUS_DEAL_WAIT_CONFIRMATION = 0x01;
    uint8 constant public STATUS_DEAL_APPROVE = 0x02;
    uint8 constant public STATUS_DEAL_RELEASE = 0x03;

    TokenERC20 public streamityContractAddress;
    
    uint256 public availableForWithdrawal;

    uint32 public requestCancelationTime;

    mapping(bytes32 => Deal) public streamityTransfers;

    function StreamityEscrow(address streamityContract) public {
        owner = msg.sender; 
        requestCancelationTime = 2 hours;
        streamityContractAddress = TokenERC20(streamityContract);
    }

    struct Deal {
        uint256 value;
        uint256 cancelTime;
        address seller;
        address buyer;
        uint8 status;
        uint256 commission;
        bool isAltCoin;
    }

    event StartDealEvent(bytes32 _hashDeal, address _seller, address _buyer);
    event ApproveDealEvent(bytes32 _hashDeal, address _seller, address _buyer);
    event ReleasedEvent(bytes32 _hashDeal, address _seller, address _buyer);
    event SellerCancelEvent(bytes32 _hashDeal, address _seller, address _buyer);
    
    function pay(bytes32 _tradeID, address _seller, address _buyer, uint256 _value, uint256 _commission, bytes _sign) 
    external 
    payable 
    {
        require(msg.value > 0);
        require(msg.value == _value);
        require(msg.value > _commission);
        bytes32 _hashDeal = keccak256(_tradeID, _seller, _buyer, msg.value, _commission);
        verifyDeal(_hashDeal, _sign);
        startDealForUser(_hashDeal, _seller, _buyer, _commission, msg.value, false);
    }

    function () public payable {
        availableForWithdrawal = availableForWithdrawal.add(msg.value);
    }

    function payAltCoin(bytes32 _tradeID, address _seller, address _buyer, uint256 _value, uint256 _commission, bytes _sign) 
    external 
    {
        bytes32 _hashDeal = keccak256(_tradeID, _seller, _buyer, _value, _commission);
        verifyDeal(_hashDeal, _sign);
        bool result = streamityContractAddress.transferFrom(msg.sender, address(this), _value);
        require(result == true);
        startDealForUser(_hashDeal, _seller, _buyer, _commission, _value, true);
    }

    function verifyDeal(bytes32 _hashDeal, bytes _sign) private view {
        require(_hashDeal.recover(_sign) == owner);
        require(streamityTransfers[_hashDeal].status == STATUS_NO_DEAL); 
    }

    function startDealForUser(bytes32 _hashDeal, address _seller, address _buyer, uint256 _commission, uint256 _value, bool isAltCoin) 
    private returns(bytes32) 
    {
        Deal storage userDeals = streamityTransfers[_hashDeal];
        userDeals.seller = _seller;
        userDeals.buyer = _buyer;
        userDeals.value = _value; 
        userDeals.commission = _commission; 
        userDeals.cancelTime = block.timestamp.add(requestCancelationTime); 
        userDeals.status = STATUS_DEAL_WAIT_CONFIRMATION;
        userDeals.isAltCoin = isAltCoin;
        emit StartDealEvent(_hashDeal, _seller, _buyer);
        
        return _hashDeal;
    }

    function withdrawCommisionToAddress(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= availableForWithdrawal); 
        availableForWithdrawal = availableForWithdrawal.sub(_amount);
        _to.transfer(_amount);
    }

    function withdrawCommisionToAddressAltCoin(address _to, uint256 _amount) external onlyOwner {
        streamityContractAddress.transfer(_to, _amount);
    }

    function getStatusDeal(bytes32 _hashDeal) external view returns (uint8) {
        return streamityTransfers[_hashDeal].status;
    }
    
     
    uint256 constant GAS_releaseTokens = 60000;
    function releaseTokens(bytes32 _hashDeal, uint256 _additionalGas) 
    external 
    nonReentrant
    returns(bool) 
    {
        Deal storage deal = streamityTransfers[_hashDeal];

        if (deal.status == STATUS_DEAL_APPROVE) {
            deal.status = STATUS_DEAL_RELEASE; 
            bool result = false;

            if (deal.isAltCoin == false)
                result = transferMinusComission(deal.buyer, deal.value, deal.commission.add((msg.sender == owner ? (GAS_releaseTokens.add(_additionalGas)).mul(tx.gasprice) : 0)));
            else 
                result = transferMinusComissionAltCoin(streamityContractAddress, deal.buyer, deal.value, deal.commission);

            if (result == false) {
                deal.status = STATUS_DEAL_APPROVE; 
                return false;   
            }

            emit ReleasedEvent(_hashDeal, deal.seller, deal.buyer);
            delete streamityTransfers[_hashDeal];
            return true;
        }
        
        return false;
    }

    function releaseTokensForce(bytes32 _hashDeal) 
    external onlyOwner
    nonReentrant
    returns(bool) 
    {
        Deal storage deal = streamityTransfers[_hashDeal];
        uint8 prevStatus = deal.status; 
        if (deal.status != STATUS_NO_DEAL) {
            deal.status = STATUS_DEAL_RELEASE; 
            bool result = false;

            if (deal.isAltCoin == false)
                result = transferMinusComission(deal.buyer, deal.value, deal.commission);
            else 
                result = transferMinusComissionAltCoin(streamityContractAddress, deal.buyer, deal.value, deal.commission);

            if (result == false) {
                deal.status = prevStatus; 
                return false;   
            }

            emit ReleasedEvent(_hashDeal, deal.seller, deal.buyer);
            delete streamityTransfers[_hashDeal];
            return true;
        }
        
        return false;
    }

    uint256 constant GAS_cancelSeller = 30000;
    function cancelSeller(bytes32 _hashDeal, uint256 _additionalGas) 
    external onlyOwner
    nonReentrant	
    returns(bool)   
    {
        Deal storage deal = streamityTransfers[_hashDeal];

        if (deal.cancelTime > block.timestamp)
            return false;

        if (deal.status == STATUS_DEAL_WAIT_CONFIRMATION) {
            deal.status = STATUS_DEAL_RELEASE; 

            bool result = false;
            if (deal.isAltCoin == false)
                result = transferMinusComission(deal.seller, deal.value, GAS_cancelSeller.add(_additionalGas).mul(tx.gasprice));
            else 
                result = transferMinusComissionAltCoin(streamityContractAddress, deal.seller, deal.value, _additionalGas);

            if (result == false) {
                deal.status = STATUS_DEAL_WAIT_CONFIRMATION; 
                return false;   
            }

            emit SellerCancelEvent(_hashDeal, deal.seller, deal.buyer);
            delete streamityTransfers[_hashDeal];
            return true;
        }
        
        return false;
    }

    function approveDeal(bytes32 _hashDeal) 
    external 
    onlyOwner 
    nonReentrant	
    returns(bool) 
    {
        Deal storage deal = streamityTransfers[_hashDeal];
        
        if (deal.status == STATUS_DEAL_WAIT_CONFIRMATION) {
            deal.status = STATUS_DEAL_APPROVE;
            emit ApproveDealEvent(_hashDeal, deal.seller, deal.buyer);
            return true;
        }
        
        return false;
    }

    function transferMinusComission(address _to, uint256 _value, uint256 _commission) 
    private returns(bool) 
    {
        uint256 _totalComission = _commission; 
        
        require(availableForWithdrawal.add(_totalComission) >= availableForWithdrawal);  

        availableForWithdrawal = availableForWithdrawal.add(_totalComission); 

        _to.transfer(_value.sub(_totalComission));
        return true;
    }

    function transferMinusComissionAltCoin(TokenERC20 _contract, address _to, uint256 _value, uint256 _commission) 
    private returns(bool) 
    {
        uint256 _totalComission = _commission; 
        _contract.transfer(_to, _value.sub(_totalComission));
        return true;
    }

    function setStreamityContractAddress(address newAddress) 
    external onlyOwner 
    {
        streamityContractAddress = TokenERC20(newAddress);
    }

     
    function transferToken(ContractToken _tokenContract, address _transferTo, uint256 _value) onlyOwner external {
        _tokenContract.transfer(_transferTo, _value);
    }
    function transferTokenFrom(ContractToken _tokenContract, address _transferTo, address _transferFrom, uint256 _value) onlyOwner external {
        _tokenContract.transferFrom(_transferTo, _transferFrom, _value);
    }
    function approveToken(ContractToken _tokenContract, address _spender, uint256 _value) onlyOwner external {
        _tokenContract.approve(_spender, _value);
    }
}