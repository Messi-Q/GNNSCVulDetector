pragma solidity ^0.4.19;

 

 
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

 

 
 

pragma solidity ^0.4.0;

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) payable returns (bytes32 _id);
    function getPrice(string _datasource) returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) returns (uint _dsprice);
    function setProofType(byte _proofType);
    function setConfig(bytes32 _config);
    function setCustomGasPrice(uint _gasPrice);
}
contract OraclizeAddrResolverI {
    function getAddress() returns (address _addr);
}
library oraclizeLib {
     
    function proofType_NONE()
    constant
    returns (byte) {
        return 0x00;
    }
     
    function proofType_TLSNotary()
    constant
    returns (byte) {
        return 0x10;
    }
     
    function proofStorage_IPFS()
    constant
    returns (byte) {
        return 0x01;
    }

     
     

     
    OraclizeAddrResolverI constant public OAR = oraclize_setNetwork();  

    function getOAR()
    constant
    returns (OraclizeAddrResolverI) {
        return OAR;
    }

    OraclizeI constant public oraclize = OraclizeI(OAR.getAddress());

    function getCON()
    constant
    returns (OraclizeI) {
        return oraclize;
    }

    function oraclize_setNetwork()
    public
    returns(OraclizeAddrResolverI){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){  
            return OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
        }
        if (getCodeSize(0xb9b00A7aE2e1D3557d7Ec7e0633e25739A6B510e)>0) {  
            return OraclizeAddrResolverI(0xb9b00A7aE2e1D3557d7Ec7e0633e25739A6B510e);
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){  
            return OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){  
            return OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){  
            return OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){  
            return OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){  
            return OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){  
            return OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
        }
    }

    function oraclize_getPrice(string datasource)
    public
    returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit)
    public
    returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg);
    }

    function oraclize_query(uint timestamp, string datasource, string arg)
    public
    returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }

    function oraclize_query(string datasource, string arg, uint gaslimit)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg, gaslimit);
    }

    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit)
    public
    returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }

    function oraclize_query(string datasource, string arg1, string arg2)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg1, arg2);
    }

    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2)
    public
    returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }

    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit)
    public
    returns (bytes32 id){
        return oraclize_query(0, datasource, arg1, arg2, gaslimit);
    }

    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit)
    public
    returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }

    function oraclize_query(string datasource, string[] argN)
    internal
    returns (bytes32 id){
        return oraclize_query(0, datasource, argN);
    }

    function oraclize_query(uint timestamp, string datasource, string[] argN)
    internal
    returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }

    function oraclize_query(string datasource, string[] argN, uint gaslimit)
    internal
    returns (bytes32 id){
        return oraclize_query(0, datasource, argN, gaslimit);
    }

    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit)
    internal
    returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }

    function oraclize_cbAddress()
    public
    constant
    returns (address){
        return oraclize.cbAddress();
    }

    function oraclize_setProof(byte proofP)
    public {
        return oraclize.setProofType(proofP);
    }

    function oraclize_setCustomGasPrice(uint gasPrice)
    public {
        return oraclize.setCustomGasPrice(gasPrice);
    }

    function oraclize_setConfig(bytes32 config)
    public {
        return oraclize.setConfig(config);
    }

    function getCodeSize(address _addr)
    public
    returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function parseAddr(string _a)
    public
    returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

    function strCompare(string _a, string _b)
    public
    returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function indexOf(string _haystack, string _needle)
    public
    returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
            return -1;
        else if(h.length > (2**128 -1))
            return -1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e)
    internal
    returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d)
    internal
    returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c)
    internal
    returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b)
    internal
    returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

     
    function parseInt(string _a)
    public
    constant
    returns (uint) {
        return parseInt(_a, 0);
    }

     
    function parseInt(string _a, uint _b)
    public
    constant
    returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    function uint2str(uint i)
    internal
    returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] arr)
    internal
    returns (bytes) {
        uint arrlen = arr.length;

         
        uint outputlen = 0;
        bytes[] memory elemArray = new bytes[](arrlen);
        for (uint i = 0; i < arrlen; i++) {
            elemArray[i] = (bytes(arr[i]));
            outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3;  
        }
        uint ctr = 0;
        uint cborlen = arrlen + 0x80;
        outputlen += byte(cborlen).length;
        bytes memory res = new bytes(outputlen);

        while (byte(cborlen).length > ctr) {
            res[ctr] = byte(cborlen)[ctr];
            ctr++;
        }
        for (i = 0; i < arrlen; i++) {
            res[ctr] = 0x5F;
            ctr++;
            for (uint x = 0; x < elemArray[i].length; x++) {
                 
                if (x % 23 == 0) {
                    uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                    elemcborlen += 0x40;
                    uint lctr = ctr;
                    while (byte(elemcborlen).length > ctr - lctr) {
                        res[ctr] = byte(elemcborlen)[ctr - lctr];
                        ctr++;
                    }
                }
                res[ctr] = elemArray[i][x];
                ctr++;
            }
            res[ctr] = 0xFF;
            ctr++;
        }
        return res;
    }

    function b2s(bytes _b)
    internal
    returns (string) {
        bytes memory output = new bytes(_b.length * 2);
        uint len = output.length;

        assembly {
            let i := 0
            let mem := 0
            loop:
                 
                0x1000000000000000000000000000000000000000000000000000000000000000
                exp(0x10, mod(i, 0x40))
                 
                jumpi(skip, gt(mod(i, 0x40), 0))
                 
                mem := mload(add(_b, add(mul(0x20, div(i, 0x40)), 0x20)))
            skip:
                mem
                mul
                div
                dup1
                 
                0x0a
                swap1
                lt
                num
                jumpi
                 
                0x0a
                swap1
                sub
            alp:
                0x61
                add
                jump(end)
            num:
                0x30
                add
            end:
                add(output, add(0x20, i))
                mstore8
                i := add(i, 1)
                jumpi(loop, gt(len, i))
        }

        return string(output);
    }
}
 

 

 
contract DogRace {
    using SafeMath for uint256; 

    string public constant version = "0.0.5";

    uint public constant min_bet = 0.1 ether;
    uint public constant max_bet = 1 ether;
    uint public constant house_fee_pct = 5;
    uint public constant claim_period = 30 days;

    address public owner;    

     
    uint8 constant dogs_count = 5;

     
    struct chronus_struct {
        bool  betting_open;      
        bool  race_start;        
        bool  race_end;          
        bool  race_voided;       
        uint  starting_time;     
        uint  betting_duration;  
        uint  race_duration;     
    }
    
     
    struct bet_info {
        uint8 dog;        
        uint amount;     
    }

     
    struct pool_info {
        uint bets_total;        
        uint pre;               
        uint post;              
        int delta;              
        bool post_check;        
        bool winner;            
    }

     
    struct bettor_info {
        uint bets_total;        
        bool rewarded;          
        bet_info[] bets;        
    }

    mapping (bytes32 => uint) oraclize_query_ids;         
    mapping (address => bettor_info) bettors;        
    
    pool_info[dogs_count] pools;                     

    chronus_struct chronus;                          

    uint public bets_total = 0;                      
    uint public reward_total = 0;                    
    uint public winning_bets_total = 0;              
    uint prices_remaining = dogs_count;              
    int max_delta = int256((uint256(1) << 255));     

     
    event OraclizeQuery(string description);
    event PriceTicker(uint dog, uint price);
    event Bet(address from, uint256 _value, uint dog);
    event Reward(address to, uint256 _value);
    event HouseFee(uint256 _value);

     
    function DogRace() public {
        owner = msg.sender;
        oraclizeLib.oraclize_setCustomGasPrice(20000000000 wei);  
    }

     
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    modifier duringBetting {
        require(chronus.betting_open);
        _;
    }
    
    modifier beforeBetting {
        require(!chronus.betting_open && !chronus.race_start);
        _;
    }

    modifier afterRace {
        require(chronus.race_end);
        _;
    }

     

     
    function place_bet(uint8 dog) external duringBetting payable  {
        require(msg.value >= min_bet && msg.value <= max_bet && dog < dogs_count);

        bet_info memory current_bet;

         
        current_bet.amount = msg.value;
        current_bet.dog = dog;
        bettors[msg.sender].bets.push(current_bet);
        bettors[msg.sender].bets_total = bettors[msg.sender].bets_total.add(msg.value);

         
        pools[dog].bets_total = pools[dog].bets_total.add(msg.value);

        bets_total = bets_total.add(msg.value);

        Bet(msg.sender, msg.value, dog);
    }

     
    function () private payable {}

     
    function check_reward() afterRace external constant returns (uint) {
        return bettor_reward(msg.sender);
    }

     
    function claim_reward() afterRace external {
        require(!bettors[msg.sender].rewarded);
        
        uint reward = bettor_reward(msg.sender);
        require(reward > 0 && this.balance >= reward);
        
        bettors[msg.sender].rewarded = true;
        msg.sender.transfer(reward);

        Reward(msg.sender, reward);
    }

     

     
    function __callback(bytes32 myid, string result) public {
        require (msg.sender == oraclizeLib.oraclize_cbAddress());

        chronus.race_start = true;
        chronus.betting_open = false;
        uint dog_index = oraclize_query_ids[myid];
        require(dog_index > 0);                  
        dog_index--;
        oraclize_query_ids[myid] = 0;                 

        if (!pools[dog_index].post_check) {
            pools[dog_index].pre = oraclizeLib.parseInt(result, 3);  
            pools[dog_index].post_check = true;         

            PriceTicker(dog_index, pools[dog_index].pre);
        } else {
            pools[dog_index].post = oraclizeLib.parseInt(result, 3);  
             
            pools[dog_index].delta = int(pools[dog_index].post - pools[dog_index].pre) * 10000 / int(pools[dog_index].pre);
            if (max_delta < pools[dog_index].delta) {
                max_delta = pools[dog_index].delta;
            }
            
            PriceTicker(dog_index, pools[dog_index].post);
            
            prices_remaining--;                     
            if (prices_remaining == 0) {            
                end_race();
            }
        }
    }

     
    function bettor_reward(address candidate) internal afterRace constant returns(uint reward) {
        bettor_info storage bettor = bettors[candidate];

        if (chronus.race_voided) {
            reward = bettor.bets_total;
        } else {
            if (reward_total == 0) {
                return 0;
            }
            uint winning_bets = 0;
            for (uint i = 0; i < bettor.bets.length; i++) {
                if (pools[bettor.bets[i].dog].winner) {
                    winning_bets = winning_bets.add(bettor.bets[i].amount);
                }
            }
            reward = reward_total.mul(winning_bets).div(winning_bets_total);
        }
    }

     

     
    function get_pool(uint dog) external constant returns (uint, uint, uint, int, bool, bool) {
        return (pools[dog].bets_total, pools[dog].pre, pools[dog].post, pools[dog].delta, pools[dog].post_check, pools[dog].winner);
    }

     
    function get_chronus() external constant returns (bool, bool, bool, bool, uint, uint, uint) {
        return (chronus.betting_open, chronus.race_start, chronus.race_end, chronus.race_voided, chronus.starting_time, chronus.betting_duration, chronus.race_duration);
    }

     
    function get_bettor_nfo() external constant returns (uint, uint, bool) {
        bettor_info info = bettors[msg.sender];
        return (info.bets_total, info.bets.length, info.rewarded);
    }

     
    function get_bet_nfo(uint bet_num) external constant returns (uint, uint) {
        bettor_info info = bettors[msg.sender];
        bet_info b_info = info.bets[bet_num];
        return (b_info.dog, b_info.amount);
    }

     

     
    function setup_race(uint betting_period, uint racing_period) public onlyOwner beforeBetting payable returns(bool) {
         
        require (oraclizeLib.oraclize_getPrice("URL", 500000) * 2 * dogs_count < this.balance);

        chronus.starting_time = block.timestamp;
        chronus.betting_open = true;
        
        uint delay = betting_period.add(60);  
        chronus.betting_duration = delay;

        oraclize_query_ids[oraclizeLib.oraclize_query(delay, "URL", "json(https://api.coinmarketcap.com/v1/ticker/bitcoin/).0.price_usd", 500000)] = 1;
        oraclize_query_ids[oraclizeLib.oraclize_query(delay, "URL", "json(https://api.coinmarketcap.com/v1/ticker/ethereum/).0.price_usd", 500000)] = 2;
        oraclize_query_ids[oraclizeLib.oraclize_query(delay, "URL", "json(https://api.coinmarketcap.com/v1/ticker/litecoin/).0.price_usd", 500000)] = 3;
        oraclize_query_ids[oraclizeLib.oraclize_query(delay, "URL", "json(https://api.coinmarketcap.com/v1/ticker/bitcoin-cash/).0.price_usd", 500000)] = 4;
        oraclize_query_ids[oraclizeLib.oraclize_query(delay, "URL", "json(https://api.coinmarketcap.com/v1/ticker/ripple/).0.price_usd", 500000)] = 5;

        delay = delay.add(racing_period);

        oraclize_query_ids[oraclizeLib.oraclize_query(delay, "URL", "json(https://api.coinmarketcap.com/v1/ticker/bitcoin/).0.price_usd", 500000)] = 1;
        oraclize_query_ids[oraclizeLib.oraclize_query(delay, "URL", "json(https://api.coinmarketcap.com/v1/ticker/ethereum/).0.price_usd", 500000)] = 2;
        oraclize_query_ids[oraclizeLib.oraclize_query(delay, "URL", "json(https://api.coinmarketcap.com/v1/ticker/litecoin/).0.price_usd", 500000)] = 3;
        oraclize_query_ids[oraclizeLib.oraclize_query(delay, "URL", "json(https://api.coinmarketcap.com/v1/ticker/bitcoin-cash/).0.price_usd", 500000)] = 4;
        oraclize_query_ids[oraclizeLib.oraclize_query(delay, "URL", "json(https://api.coinmarketcap.com/v1/ticker/ripple/).0.price_usd", 500000)] = 5;

        OraclizeQuery("Oraclize queries were sent");
        
        chronus.race_duration = delay;

        return true;
    }

     
    function end_race() internal {

        chronus.race_end = true;

         
        for (uint dog = 0; dog < dogs_count; dog++) {
            if (pools[dog].delta == max_delta) {
                pools[dog].winner = true;
                winning_bets_total = winning_bets_total.add(pools[dog].bets_total);
            }
        }

         
        uint house_fee;

        if (winning_bets_total == 0) {               
            reward_total = 0;
            house_fee = this.balance;
        } else {
            if (winning_bets_total == bets_total) {      
                chronus.race_voided = true;
                house_fee = 0;
            } else {
                house_fee = bets_total.mul(house_fee_pct).div(100);          
            }
            reward_total = bets_total.sub(house_fee);                        
            house_fee = this.balance.sub(reward_total);                     
        }

        HouseFee(house_fee);
        owner.transfer(house_fee);
    }

     
    function void_race() external onlyOwner {
        require(now > chronus.starting_time + chronus.race_duration);
        require((chronus.betting_open && !chronus.race_start)
            || (chronus.race_start && !chronus.race_end));
        chronus.betting_open = false;
        chronus.race_voided = true;
        chronus.race_end = true;
    }

     
    function recover_unclaimed_bets() external onlyOwner {
        require(now > chronus.starting_time + chronus.race_duration + claim_period);
        require(chronus.race_end);
        owner.transfer(this.balance);
    }

     
    function kill() external onlyOwner {
        selfdestruct(msg.sender);
    }
}