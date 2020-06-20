pragma solidity ^0.4.6;


 

 
 
 
 
 
 
 

 
 
contract Owned {
     
     
    modifier onlyOwner { if (msg.sender != owner) throw; _; }

    address public owner;

     
    function Owned() { owner = msg.sender;}

     
     
     
    function changeOwner(address _newOwner) onlyOwner {
        owner = _newOwner;
        NewOwner(msg.sender, _newOwner);
    }

    event NewOwner(address indexed oldOwner, address indexed newOwner);
}
 
 
 
 
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;

     
     
     
     
     
     
     
     
    function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

     
     
    modifier onlyEscapeHatchCallerOrOwner {
        if ((msg.sender != escapeHatchCaller)&&(msg.sender != owner))
            throw;
        _;
    }

     
     
    function escapeHatch() onlyEscapeHatchCallerOrOwner {
        uint total = this.balance;
         
        if (!escapeHatchDestination.send(total)) {
            throw;
        }
        EscapeHatchCalled(total);
    }
     
     
     
     
     
    function changeEscapeCaller(address _newEscapeHatchCaller) onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchCalled(uint amount);
}

 
 
contract Vault is Escapable {

     
     
     
    struct Payment {
        string name;      
        bytes32 reference;   
        address spender;         
        uint earliestPayTime;    
        bool canceled;          
        bool paid;               
        address recipient;       
        uint amount;             
        uint securityGuardDelay; 
    }

    Payment[] public authorizedPayments;

    address public securityGuard;
    uint public absoluteMinTimeLock;
    uint public timeLock;
    uint public maxSecurityGuardDelay;

     
     
    mapping (address => bool) public allowedSpenders;

     
     
    modifier onlySecurityGuard { if (msg.sender != securityGuard) throw; _; }

     
    event PaymentAuthorized(uint indexed idPayment, address indexed recipient, uint amount);
    event PaymentExecuted(uint indexed idPayment, address indexed recipient, uint amount);
    event PaymentCanceled(uint indexed idPayment);
    event EtherReceived(address indexed from, uint amount);
    event SpenderAuthorization(address indexed spender, bool authorized);

 
 
 

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function Vault(
        address _escapeHatchCaller,
        address _escapeHatchDestination,
        uint _absoluteMinTimeLock,
        uint _timeLock,
        address _securityGuard,
        uint _maxSecurityGuardDelay) Escapable(_escapeHatchCaller, _escapeHatchDestination)
    {
        absoluteMinTimeLock = _absoluteMinTimeLock;
        timeLock = _timeLock;
        securityGuard = _securityGuard;
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }

 
 
 

     
     
    function numberOfAuthorizedPayments() constant returns (uint) {
        return authorizedPayments.length;
    }

 
 
 

     
     
    function receiveEther() payable {
        EtherReceived(msg.sender, msg.value);
    }

     
     
    function () payable {
        receiveEther();
    }

 
 
 

     
     
     
     
     
     
     
     
    function authorizePayment(
        string _name,
        bytes32 _reference,
        address _recipient,
        uint _amount,
        uint _paymentDelay
    ) returns(uint) {

         
        if (!allowedSpenders[msg.sender] ) throw;
        uint idPayment = authorizedPayments.length;        
        authorizedPayments.length++;

         
        Payment p = authorizedPayments[idPayment];
        p.spender = msg.sender;

         
        if (_paymentDelay > 10**18) throw;

         
        p.earliestPayTime = _paymentDelay >= timeLock ?
                                now + _paymentDelay :
                                now + timeLock;
        p.recipient = _recipient;
        p.amount = _amount;
        p.name = _name;
        p.reference = _reference;
        PaymentAuthorized(idPayment, p.recipient, p.amount);
        return idPayment;
    }

     
     
     
     
    function collectAuthorizedPayment(uint _idPayment) {

         
        if (_idPayment >= authorizedPayments.length) throw;

        Payment p = authorizedPayments[_idPayment];

         
        if (msg.sender != p.recipient) throw;
        if (!allowedSpenders[p.spender]) throw;
        if (now < p.earliestPayTime) throw;
        if (p.canceled) throw;
        if (p.paid) throw;
        if (this.balance < p.amount) throw;

        p.paid = true;  
        if (!p.recipient.send(p.amount)) {   
            throw;
        }
        PaymentExecuted(_idPayment, p.recipient, p.amount);
     }

 
 
 

     
     
     
    function delayPayment(uint _idPayment, uint _delay) onlySecurityGuard {
        if (_idPayment >= authorizedPayments.length) throw;

         
        if (_delay > 10**18) throw;

        Payment p = authorizedPayments[_idPayment];

        if ((p.securityGuardDelay + _delay > maxSecurityGuardDelay) ||
            (p.paid) ||
            (p.canceled))
            throw;

        p.securityGuardDelay += _delay;
        p.earliestPayTime += _delay;
    }

 
 
 

     
     
    function cancelPayment(uint _idPayment) onlyOwner {
        if (_idPayment >= authorizedPayments.length) throw;

        Payment p = authorizedPayments[_idPayment];


        if (p.canceled) throw;
        if (p.paid) throw;

        p.canceled = true;
        PaymentCanceled(_idPayment);
    }

     
     
     
    function authorizeSpender(address _spender, bool _authorize) onlyOwner {
        allowedSpenders[_spender] = _authorize;
        SpenderAuthorization(_spender, _authorize);
    }

     
     
    function setSecurityGuard(address _newSecurityGuard) onlyOwner {
        securityGuard = _newSecurityGuard;
    }

     
     
     
     
    function setTimelock(uint _newTimeLock) onlyOwner {
        if (_newTimeLock < absoluteMinTimeLock) throw;
        timeLock = _newTimeLock;
    }

     
     
     
     
    function setMaxSecurityGuardDelay(uint _maxSecurityGuardDelay) onlyOwner {
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }
}