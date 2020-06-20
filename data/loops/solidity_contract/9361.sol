pragma solidity ^0.4.13;

contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract IInvestorList {
    string public constant ROLE_REGD = "regd";
    string public constant ROLE_REGCF = "regcf";
    string public constant ROLE_REGS = "regs";
    string public constant ROLE_UNKNOWN = "unknown";

    function inList(address addr) public view returns (bool);
    function addAddress(address addr, string role) public;
    function getRole(address addr) public view returns (string);
    function hasRole(address addr, string role) public view returns (bool);
}

contract Ownable {
    address public owner;
    address public newOwner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
            newOwner = 0;
        }
    }

}

contract InvestorList is Ownable, IInvestorList {
    event AddressAdded(address addr, string role);
    event AddressRemoved(address addr, string role);

    mapping (address => string) internal investorList;

     
    modifier validRole(string role) {
        require(
            keccak256(bytes(role)) == keccak256(bytes(ROLE_REGD)) ||
            keccak256(bytes(role)) == keccak256(bytes(ROLE_REGCF)) ||
            keccak256(bytes(role)) == keccak256(bytes(ROLE_REGS)) ||
            keccak256(bytes(role)) == keccak256(bytes(ROLE_UNKNOWN))
        );
        _;
    }

     
    function inList(address addr)
        public
        view
        returns (bool)
    {
        if (bytes(investorList[addr]).length != 0) {
            return true;
        } else {
            return false;
        }
    }

     
    function getRole(address addr)
        public
        view
        returns (string)
    {
        require(inList(addr));
        return investorList[addr];
    }

     
    function hasRole(address addr, string role)
        public
        view
        returns (bool)
    {
        return keccak256(bytes(role)) == keccak256(bytes(investorList[addr]));
    }

     
    function addAddress(address addr, string role)
        onlyOwner
        validRole(role)
        public
    {
        investorList[addr] = role;
        emit AddressAdded(addr, role);
    }

     
    function addAddresses(address[] addrs, string role)
        onlyOwner
        validRole(role)
        public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            addAddress(addrs[i], role);
        }
    }

     
    function removeAddress(address addr)
        onlyOwner
        public
    {
         
        require(inList(addr));
        string memory role = investorList[addr];
        investorList[addr] = "";
        emit AddressRemoved(addr, role);
    }

     
    function removeAddresses(address[] addrs)
        onlyOwner
        public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (inList(addrs[i])) {
                removeAddress(addrs[i]);
            }
        }
    }

}

interface ISecuritySale {
    function setLive(bool newLiveness) external;
    function setInvestorList(address _investorList) external;
}

contract SecuritySale is Ownable {

    bool public live;         
    IInvestorList public investorList;  

    event SaleLive(bool liveness);
    event EtherIn(address from, uint amount);
    event StartSale();
    event EndSale();

    constructor() public {
        live = false;
    }

    function setInvestorList(address _investorList) public onlyOwner {
        investorList = IInvestorList(_investorList);
    }

    function () public payable {
        require(live);
        require(investorList.inList(msg.sender));
        emit EtherIn(msg.sender, msg.value);
    }

     
    function setLive(bool newLiveness) public onlyOwner {
        if(live && !newLiveness) {
            live = false;
            emit EndSale();
        }
        else if(!live && newLiveness) {
            live = true;
            emit StartSale();
        }
    }

     
    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

     
    function withdrawSome(uint value) public onlyOwner {
        require(value <= address(this).balance);
        msg.sender.transfer(value);
    }

     
    function withdrawTokens(address token) public onlyOwner {
        ERC20Basic t = ERC20Basic(token);
        require(t.transfer(msg.sender, t.balanceOf(this)));
    }

     
    function sendReceivedTokens(address token, address sender, uint amount) public onlyOwner {
        ERC20Basic t = ERC20Basic(token);
        require(t.transfer(sender, amount));
    }
}