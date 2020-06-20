pragma solidity ^0.4.23;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract ReentrancyGuard {

   
  bool private reentrancyLock = false;

   
  modifier nonReentrant() {
    require(!reentrancyLock);
    reentrancyLock = true;
    _;
    reentrancyLock = false;
  }

}

 

interface ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 

interface IERC20Token {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function decimals() public view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}


 

contract IBancorNetwork {
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256);
    function convertForPrioritized2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _block,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public payable returns (uint256);

     
    function convertForPrioritized(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _block,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public payable returns (uint256);
}

 
contract IContractRegistry {
    function getAddress(bytes32 _contractName) public view returns (address);
}

 

 







contract IndTokenPayment is Ownable, ReentrancyGuard {  
    IERC20Token[] public path;    
    address public destinationWallet;       
    uint256 public minConversionRate;
    IContractRegistry public bancorRegistry;
    bytes32 public constant BANCOR_NETWORK = "BancorNetwork";
    
    event conversionSucceded(address from,uint256 fromTokenVal,address dest,uint256 destTokenVal);    
    
    constructor(IERC20Token[] _path,
                address destWalletAddr,
                address bancorRegistryAddr,
                uint256 minConvRate){
        path = _path;
        bancorRegistry = IContractRegistry(bancorRegistryAddr);
        destinationWallet = destWalletAddr;         
        minConversionRate = minConvRate;
    }

    function setConversionPath(IERC20Token[] _path) public onlyOwner {
        path = _path;
    }
    
    function setBancorRegistry(address bancorRegistryAddr) public onlyOwner {
        bancorRegistry = IContractRegistry(bancorRegistryAddr);
    }

    function setMinConversionRate(uint256 minConvRate) public onlyOwner {
        minConversionRate = minConvRate;
    }    

    function setDestinationWallet(address destWalletAddr) public onlyOwner {
        destinationWallet = destWalletAddr;
    }    
    
    function convertToInd() internal nonReentrant {
        assert(bancorRegistry.getAddress(BANCOR_NETWORK) != address(0));
        IBancorNetwork bancorNetwork = IBancorNetwork(bancorRegistry.getAddress(BANCOR_NETWORK));   
         
        uint256 minReturn =0;
        uint256 convTokens =  bancorNetwork.convertFor.value(msg.value)(path,msg.value,minReturn,destinationWallet);        
        assert(convTokens > 0);
        emit conversionSucceded(msg.sender,msg.value,destinationWallet,convTokens);                                                                    
    }

     
     
    function withdrawToken(IERC20Token anyToken) public onlyOwner nonReentrant returns(bool){
        if( anyToken != address(0x0) ) {
            assert(anyToken.transfer(destinationWallet, anyToken.balanceOf(this)));
        }
        return true;
    }

     
     
    function withdrawEther() public onlyOwner nonReentrant returns(bool){
        if(address(this).balance > 0){
            destinationWallet.transfer(address(this).balance);
        }        
        return true;
    }
 
    function () public payable {
         
         
        convertToInd();
    }

     

    function getBancorContractAddress() public returns(address) {
        return bancorRegistry.getAddress(BANCOR_NETWORK);
    }

}