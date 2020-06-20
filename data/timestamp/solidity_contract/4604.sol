pragma solidity ^0.4.19;

 

contract CryptonomicaVerification {

     

     
     
     
     

     
     
     
     

     
     
     
     
     
     
    mapping(address => bytes20) public fingerprint;  

     
    mapping(address => string) public unverifiedFingerprint;  

    mapping(address => uint) public keyCertificateValidUntil;  
    mapping(address => bytes32) public firstName;  
    mapping(address => bytes32) public lastName;  
    mapping(address => uint) public birthDate;  
     
     
     
     
    mapping(address => bytes32) public nationality;  
    mapping(address => uint256) public verificationAddedOn;  
    mapping(address => uint256) public revokedOn;  
     
    mapping(address => string) public signedString;  

     
     
    mapping(address => uint256) public signedStringUploadedOnUnixTime;

     
     
    mapping(bytes20 => address) public addressAttached;  

     
    string public stringToSignExample = "I hereby confirm that the address <address lowercase> is my Ethereum address";

     
    mapping(address => Verification) public verification;  
    struct Verification {
         
        string fingerprint;  
        uint keyCertificateValidUntil;  
        string firstName;  
        string lastName; 
        uint birthDate;  
        string nationality;  
        uint verificationAddedOn; 
        uint revokedOn;  
        string signedString;  
         
    }

     
    address public owner;  
    mapping(address => bool) public isManager;  

    uint public priceForVerificationInWei;  

    address public withdrawalAddress;  
    bool public withdrawalAddressFixed = false;  

     
    function CryptonomicaVerification() public { 
        owner = msg.sender;
        isManager[msg.sender] = true;
        withdrawalAddress = msg.sender;
    }

     

     
     
     
     
    function stringToBytes32(string memory source) public pure returns (bytes32 result) { 
         

         
         
         
         
         
        assembly {
            result := mload(add(source, 32))
        }
    }

     
     
     
     
    function bytes32ToString(bytes32 _bytes32) public pure returns (string){ 
         
         
         
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

     

     
     
    function uploadSignedString(string _fingerprint, bytes20 _fingerprintBytes20, string _signedString) public payable {

         
         
         
         
         
         
         
         
         

         
        if (msg.value < priceForVerificationInWei) {
            revert();
             
        }

         
        if (signedStringUploadedOnUnixTime[msg.sender] != 0) {
            revert();
             
        }

         
        if (bytes(_fingerprint).length != 40) {
            revert();
             
        }

         
        if (addressAttached[_fingerprintBytes20] != 0) {
            revert();
             
        }

         
         
        unverifiedFingerprint[msg.sender] = _fingerprint;

        signedString[msg.sender] = verification[msg.sender].signedString = _signedString;

         
        signedStringUploadedOnUnixTime[msg.sender] = block.timestamp;

        SignedStringUploaded(msg.sender, _fingerprint, _signedString);

    }

    event SignedStringUploaded(address indexed fromAccount, string fingerprint, string uploadedString);

     
     
    function addVerificationData(
        address _acc,  
        string _fingerprint,  
        bytes20 _fingerprintBytes20,  
        uint _keyCertificateValidUntil,  
        string _firstName,  
        string _lastName,  
        uint _birthDate,  
        string _nationality) public {

         
        require(isManager[msg.sender]);

         
         
         
         
         
         
         
         

         
        require(signedStringUploadedOnUnixTime[_acc] != 0);
         
        require(verificationAddedOn[_acc] == 0);

        verification[_acc].fingerprint = _fingerprint;
        fingerprint[_acc] = _fingerprintBytes20;

        addressAttached[_fingerprintBytes20] = _acc;

        verification[_acc].keyCertificateValidUntil = keyCertificateValidUntil[_acc] = _keyCertificateValidUntil;
        verification[_acc].firstName = _firstName;
        firstName[_acc] = stringToBytes32(_firstName);
        verification[_acc].lastName = _lastName;
        lastName[_acc] = stringToBytes32(_lastName);
        verification[_acc].birthDate = birthDate[_acc] = _birthDate;
        verification[_acc].nationality = _nationality;
        nationality[_acc] = stringToBytes32(_nationality);
        verification[_acc].verificationAddedOn = verificationAddedOn[_acc] = block.timestamp;

        VerificationAdded(
            verification[_acc].fingerprint,
            _acc,
         
         
         
         
         
            msg.sender
        );
         
    }

    event VerificationAdded (
        string forFingerprint,
        address indexed verifiedAccount,  
     
     
     
     
     
        address verificationAddedByAccount
    );

     
    function revokeVerification(address _acc) public { 
        require(msg.sender == _acc || isManager[msg.sender]);

        verification[_acc].revokedOn = revokedOn[_acc] = block.timestamp;

         
        VerificationRevoked(
            _acc,
            verification[_acc].fingerprint,
            block.timestamp,
            msg.sender
        );
    }

    event VerificationRevoked (
        address indexed revocedforAccount,  
        string withFingerprint,
        uint revokedOnUnixTime,
        address indexed revokedBy  
    );

     

     
     
    address private newOwner;
     
    function changeOwnerStart(address _newOwner) public {
        require(msg.sender == owner);
        newOwner = _newOwner;
        ChangeOwnerStarted(msg.sender, _newOwner);
    }  
    event ChangeOwnerStarted (address indexed startedBy, address indexed newOwner);
     
    function changeOwnerAccept() public {
        require(msg.sender == newOwner);
         
        OwnerChanged(owner, newOwner);
        owner = newOwner;
    }  
    event OwnerChanged(address indexed from, address indexed to);

     
    function addManager(address _acc) public {
        require(msg.sender == owner);
        isManager[_acc] = true;
        ManagerAdded(_acc, msg.sender);
    }  
    event ManagerAdded (address indexed added, address indexed addedBy);
     
    function removeManager(address manager) public {
        require(msg.sender == owner);
        isManager[manager] = false;
        ManagerRemoved(manager, msg.sender);
    }  
    event ManagerRemoved(address indexed removed, address indexed removedBy);

     
    function setPriceForVerification(uint priceInWei) public {
         
        require(isManager[msg.sender]);
        uint oldPrice = priceForVerificationInWei;
        priceForVerificationInWei = priceInWei;
        PriceChanged(oldPrice, priceForVerificationInWei, msg.sender);
    }  
    event PriceChanged(uint from, uint to, address indexed changedBy);

     
     
     
    function withdrawAllToWithdrawalAddress() public returns (bool) { 
         
         
         
         
        uint sum = this.balance;
        if (!withdrawalAddress.send(this.balance)) { 
            Withdrawal(withdrawalAddress, sum, msg.sender, false);
            return false;
        }
        Withdrawal(withdrawalAddress, sum, msg.sender, true);
        return true;
    }  
    event Withdrawal(address indexed to, uint sumInWei, address indexed by, bool success);

     
    function setWithdrawalAddress(address _withdrawalAddress) public {
        require(msg.sender == owner);
        require(!withdrawalAddressFixed);
        WithdrawalAddressChanged(withdrawalAddress, _withdrawalAddress, msg.sender);
        withdrawalAddress = _withdrawalAddress;
    }  
    event WithdrawalAddressChanged(address indexed from, address indexed to, address indexed changedBy);

     
    function fixWithdrawalAddress(address _withdrawalAddress) public returns (bool) {
        require(msg.sender == owner);
        require(withdrawalAddress == _withdrawalAddress);

         
        require(!withdrawalAddressFixed);

        withdrawalAddressFixed = true;
        WithdrawalAddressFixed(withdrawalAddress, msg.sender);
        return true;
    }  
     
    event WithdrawalAddressFixed(address withdrawalAddressFixedAs, address fixedBy);

}