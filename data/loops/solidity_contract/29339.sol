pragma solidity ^0.4.11;

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

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) tokenBalances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(tokenBalances[msg.sender]>=_value);
    tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return tokenBalances[_owner];
  }

}
contract ERD is BasicToken,Ownable {

   using SafeMath for uint256;
   
   string public constant name = "ERD";
   string public constant symbol = "ERD";
   uint256 public constant decimals = 18;  
   address public ethStore = 0xDcbFE8d41D4559b3EAD3179fa7Bb3ad77EaDa564;
   uint256 public REMAINING_SUPPLY = 100000000000  * (10 ** uint256(decimals));
   event Debug(string message, address addr, uint256 number);
   event Message(string message);
    string buyMessage;
  
  address wallet;
    
    function ERD(address _wallet) public {
        owner = msg.sender;
        totalSupply = REMAINING_SUPPLY;
        wallet = _wallet;
        tokenBalances[wallet] = totalSupply;    
    }
    
     function mint(address from, address to, uint256 tokenAmount) public onlyOwner {
      require(tokenBalances[from] >= tokenAmount);                
      tokenBalances[to] = tokenBalances[to].add(tokenAmount);                   
      tokenBalances[from] = tokenBalances[from].sub(tokenAmount);                         
      REMAINING_SUPPLY = tokenBalances[wallet];
      Transfer(from, to, tokenAmount); 
    }
    
    function getTokenBalance(address user) public view returns (uint256 balance) {
        balance = tokenBalances[user];  
        return balance;
    }
}
contract ERDTokenTransaction {
    using SafeMath for uint256;
    struct Transaction {
         
        address entityId;
        uint transactionId;
        uint transactionType;        
        uint amount;
        string transactionDate;
        uint256 transactionTimeStamp;
        string currency;
        string accountingPeriod;
    }
    
    struct AccountChart {
         
        address entityId;
        uint accountsPayable;
        uint accountsReceivable;
        uint sales;
        uint isEntityInitialized;
    }
    
    address[] entities;
    uint[] allTransactionIdsList;
    
    uint[] allTransactionIdsAgainstAnEntityList;
    mapping(address=>uint[])  entityTransactionsIds;
    mapping(address=>Transaction[])  entityTransactions;
    mapping(address=>AccountChart)  entityAccountChart;
    mapping(address=>bool) freezedTokens;
    address wallet;
    ERD public token;   
    uint256 transactionIdSequence = 0;
     
    uint256 public ratePerWei = 100;
    uint256 public perTransactionRate = 1 * 10 ** 14;    
    
     
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event EmitAccountChartDetails (address entityId, uint accountsPayable,uint accountsReceivable,uint sales);
  event EmitTransactionDetails (address entityId, uint transactionId, uint transactionType,uint amount,string transactionDate,string currency, string accountingPeriod);
  event EmitTransactionIds (uint[] ids);
  event EmitEntityIds (address[] ids);
     

    Transaction transObj;
    AccountChart AccountChartObj;
    
    function ERDTokenTransaction(address _wallet) public {
        wallet = _wallet;
        token = createTokenContract(wallet);
        
         
         entities.push(0);
         
        AccountChartObj = AccountChart({
            entityId : wallet,
            accountsPayable: 0,
            accountsReceivable: 0,
            sales:0,
            isEntityInitialized:1 
        });
        entityAccountChart[wallet] = AccountChartObj;
    }
    
    function createTokenContract(address wall) internal returns (ERD) {
    return new ERD(wall);
   }
    
     
    function () public payable {
     buyTokens(msg.sender);
    }
    
     
    
  
   function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(ratePerWei);
   
    token.mint(wallet, beneficiary, tokens); 
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
    
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
     
    function AddTransactionAgainstExistingEntity(address entId,uint transType,uint amt,string curr, string accPr) public 
    {
        require (entityAccountChart[entId].isEntityInitialized == 1);
        transactionIdSequence = transactionIdSequence + 1;
         transObj = Transaction({
            entityId : entId,
            transactionId : transactionIdSequence,
            transactionType: transType,
            amount: amt,
            transactionDate : "NA",
            transactionTimeStamp: now,
            currency : curr,
            accountingPeriod : accPr
          });
          
          entityTransactions[entId].push(transObj);
          allTransactionIdsList.push(transactionIdSequence);
          entityTransactionsIds[entId].push(transactionIdSequence);
          MakeTokenCreditAndDebitEntry(msg.sender);
    }
    function MakeTokenCreditAndDebitEntry(address entId) internal {
    
          transactionIdSequence = transactionIdSequence + 1;
          
         transObj = Transaction({
            entityId : wallet,    
            transactionId : transactionIdSequence,
            transactionType: 0,  
            amount: perTransactionRate,
            transactionDate : "NA",
            transactionTimeStamp: now,
            currency : "ERD",
            accountingPeriod : ""
          });
          entityTransactions[entId].push(transObj);
          allTransactionIdsList.push(transactionIdSequence);
          entityTransactionsIds[entId].push(transactionIdSequence);
          
          
          transactionIdSequence = transactionIdSequence + 1;
          
         transObj = Transaction({
            entityId : entId,
            transactionId : transactionIdSequence,
            transactionType: 1,      
            amount: perTransactionRate,
            transactionDate : "NA",
            transactionTimeStamp: now,
            currency : "ERD",
            accountingPeriod : ""
          });
          
          entityTransactions[entId].push(transObj);
          allTransactionIdsList.push(transactionIdSequence);
          entityTransactionsIds[entId].push(transactionIdSequence);
    }
     
    function updateAccountChartAgainstExistingEntity(address entId, uint accPayable, uint accReceivable,uint sale) public
    {
        require(token.getTokenBalance(msg.sender)>=perTransactionRate);
        require(freezedTokens[entId] == false);
        require (entityAccountChart[entId].isEntityInitialized == 1);
        token.mint(msg.sender, wallet, perTransactionRate);
        require(freezedTokens[entId] == false);
    
       
        AccountChartObj = AccountChart({
            entityId : entId,
            accountsPayable: accPayable,
            accountsReceivable: accReceivable,
            sales:sale,
            isEntityInitialized:1
        });
        
        entityAccountChart[entId] = AccountChartObj;
        
         MakeTokenCreditAndDebitEntry(msg.sender);
    }
    function addEntity(address entId) public
    {
        require(token.getTokenBalance(msg.sender)>=perTransactionRate);
        require(freezedTokens[entId] == false);
        require (entityAccountChart[entId].isEntityInitialized == 0);
        token.mint(msg.sender, wallet, perTransactionRate);
       
        entities.push(entId);
         
        AccountChartObj = AccountChart({
            entityId : entId,
            accountsPayable: 0,
            accountsReceivable: 0,
            sales:0,
            isEntityInitialized:1 
        });
        entityAccountChart[entId] = AccountChartObj;
        MakeTokenCreditAndDebitEntry(msg.sender);
    }
    
    function getAllEntityIds() public returns (address[] entityList) 
    {
        require(token.getTokenBalance(msg.sender)>=perTransactionRate);
        token.mint(msg.sender, wallet, perTransactionRate);
        require(freezedTokens[msg.sender] == false);
        MakeTokenCreditAndDebitEntry(msg.sender);
        EmitEntityIds(entities);
        return entities;
    }
    
    function getAllTransactionIdsByEntityId(address entId) public returns (uint[] transactionIds)
    {
        require(token.getTokenBalance(msg.sender)>=perTransactionRate);
        require(freezedTokens[entId] == false);
        token.mint(msg.sender, wallet, perTransactionRate);
        MakeTokenCreditAndDebitEntry(msg.sender);
        EmitTransactionIds(entityTransactionsIds[entId]);
        return entityTransactionsIds[entId];
    }
    
    function getAllTransactionIds() public returns (uint[] transactionIds)
    {
        require(token.getTokenBalance(msg.sender)>=perTransactionRate);
        require(freezedTokens[msg.sender] == false);
        token.mint(msg.sender,wallet,perTransactionRate);
        MakeTokenCreditAndDebitEntry(msg.sender);
        EmitTransactionIds(allTransactionIdsList);
        return allTransactionIdsList;
    }
    
    function getTransactionByTransactionId(uint transId) public 
    {
        require(token.getTokenBalance(msg.sender)>=perTransactionRate);
        require(freezedTokens[msg.sender] == false);
        token.mint(msg.sender, wallet, perTransactionRate);
        MakeTokenCreditAndDebitEntry(msg.sender);
        for(uint i=0; i<entities.length;i++)
        {
             
            Transaction[] storage transactionsListByEntityId = entityTransactions[entities[i]];
            for (uint j=0;j<transactionsListByEntityId.length;j++)
            {
                 
                 
                if(transactionsListByEntityId[j].transactionId==transId)
                {
                    EmitTransactionDetails (transactionsListByEntityId[j].entityId,transactionsListByEntityId[j].transactionId,
                            transactionsListByEntityId[j].transactionType,transactionsListByEntityId[j].amount,
                            transactionsListByEntityId[j].transactionDate,transactionsListByEntityId[j].currency,
                            transactionsListByEntityId[j].accountingPeriod);
                }
               
            }
        }
        EmitTransactionDetails (0,0,0,0,"NA","NA","NA");
    }
    
    function getTransactionByTransactionAndEntityId(address entId, uint transId) public 
    {
        require(token.getTokenBalance(msg.sender)>=perTransactionRate);
        require(freezedTokens[msg.sender] == false);
        token.mint(msg.sender, wallet, perTransactionRate);
        MakeTokenCreditAndDebitEntry(msg.sender);
         
        Transaction[] storage transactionsListByEntityId = entityTransactions[entId];
        for (uint j=0;j<transactionsListByEntityId.length;j++)
        {
             
             
            if(transactionsListByEntityId[j].transactionId==transId)
            {
                EmitTransactionDetails (transactionsListByEntityId[j].entityId,transactionsListByEntityId[j].transactionId,
                            transactionsListByEntityId[j].transactionType,transactionsListByEntityId[j].amount,
                            transactionsListByEntityId[j].transactionDate,transactionsListByEntityId[j].currency,
                            transactionsListByEntityId[j].accountingPeriod);
            }
        }
        EmitTransactionDetails (0,0,0,0,"NA","NA","NA");
    }
    
    function getAccountChartDetailsByEntityId(address entId) public
    {
        require(token.getTokenBalance(msg.sender)>=perTransactionRate);
        require(freezedTokens[msg.sender] == false);
        token.mint(msg.sender, wallet, perTransactionRate);
        MakeTokenCreditAndDebitEntry(msg.sender);
        EmitAccountChartDetails (entityAccountChart[entId].entityId,entityAccountChart[entId].accountsPayable,
                entityAccountChart[entId].accountsReceivable,entityAccountChart[entId].sales);
    }
     function showMyTokenBalance() public constant returns (uint256 tokenBalance) {
        tokenBalance = token.getTokenBalance(msg.sender);
        return tokenBalance;
    }
    
     function freezeTokensOfOneUser(address entityId) public {
        require(msg.sender == wallet);
        freezedTokens[entityId] = true;
    }
    
    function UnfreezeTokensOfOneUser(address entityId) public {
        require(msg.sender == wallet);
        freezedTokens[entityId] = false;
    }
}