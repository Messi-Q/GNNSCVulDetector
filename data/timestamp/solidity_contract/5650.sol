pragma solidity ^0.4.21;
 
 

    
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
 
contract Owned {
    address public owner;
    address public newOwner;
    address internal admin;

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
     
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event AdminChanged(address indexed _from, address indexed _to);

     
    function Owned() public {
        owner = msg.sender;
        admin = msg.sender;
    }

    function setAdmin(address newAdmin) public onlyOwner{
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function showAdmin() public view onlyAdmin returns(address _admin){
        _admin = admin;
        return _admin;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract Redenom is ERC20Interface, Owned{
    using SafeMath for uint;
    
     
    string      public name;  
    string      public symbol;  
    uint        private _totalSupply;  
    uint        public decimals = 8;  


     
    uint public round = 1; 
    uint public epoch = 1; 

    bool public frozen = false;

     
    uint[8] private dec = [0,0,0,0,0,0,0,0];
     
    uint[9] private mul = [1,10,100,1000,10000,100000,1000000,10000000,100000000];
     
    uint[9] private weight = [uint(0),0,0,0,0,5,10,30,55];
     
    uint[9] private current_toadd = [uint(0),0,0,0,0,0,0,0,0];
   

     
    uint public total_fund;  
    uint public epoch_fund;  
    uint public team_fund;  
    uint public redenom_dao_fund;  

    struct Account {
        uint balance;
        uint lastRound;  
        uint lastEpoch;  
        uint lastVotedBallotId;  
        uint bitmask;
             
             
             
             
             
    }
    
    mapping(address=>Account) accounts; 
    mapping(address => mapping(address => uint)) allowed;

     
    event Redenomination(uint indexed round);
    event Epoch(uint indexed epoch);
    event VotingOn(uint indexed _ballotId);
    event VotingOff(uint indexed winner);
    event Vote(address indexed voter, uint indexed propId, uint voterBalance, uint indexed curentBallotId);

    function Redenom() public {
        symbol = "NOMT";
        name = "Redenom_test";
        _totalSupply = 0;  

        total_fund = 10000000 * 10**decimals;  
        epoch_fund = 100000 * 10**decimals;  
        total_fund = total_fund.sub(epoch_fund);  

    }




     
     
     
    function StartNewEpoch() public onlyAdmin returns(bool succ){
        require(frozen == false); 
        require(round == 9);
        require(epoch < 100);

        dec = [0,0,0,0,0,0,0,0];  
        round = 1;
        epoch++;

        epoch_fund = 100000 * 10**decimals;  
        total_fund = total_fund.sub(epoch_fund);  


        emit Epoch(epoch);
        return true;
    }




     

     
    bool public votingActive = false;
    uint public curentBallotId = 0;
    uint public curentWinner;

     
    modifier onlyVoter {
        require(votingActive == true);
        require(bitmask_check(msg.sender, 4) == true);  
        require(bitmask_check(msg.sender, 1024) == false);  
        require((accounts[msg.sender].lastVotedBallotId < curentBallotId)); 
        _;
    }

     
    struct Project {
        uint id;    
        uint votesWeight;  
        bool active;  
    }
    Project[] public projects;

    struct Winner {
        uint id;
        uint projId;
    }
    Winner[] public winners;


    function addWinner(uint projId) internal {
        winners.push(Winner({
            id: curentBallotId,
            projId: projId
        }));
    }
    function findWinner(uint _ballotId) public constant returns (uint winner){
        for (uint p = 0; p < winners.length; p++) {
            if (winners[p].id == _ballotId) {
                return winners[p].projId;
            }
        }
    }



     
    function addProject(uint _id) public onlyAdmin {
        require(votingActive == true);
        projects.push(Project({
            id: _id,
            votesWeight: 0,
            active: true
        }));
    }

     
    function swapProject(uint _id) public onlyAdmin {
        for (uint p = 0; p < projects.length; p++){
            if(projects[p].id == _id){
                if(projects[p].active == true){
                    projects[p].active = false;
                }else{
                    projects[p].active = true;
                }
            }
        }
    }

     
    function projectWeight(uint _id) public constant returns(uint PW){
        for (uint p = 0; p < projects.length; p++){
            if(projects[p].id == _id){
                return projects[p].votesWeight;
            }
        }
    }

     
    function projectActive(uint _id) public constant returns(bool PA){
        for (uint p = 0; p < projects.length; p++){
            if(projects[p].id == _id){
                return projects[p].active;
            }
        }
    }

     
    function vote(uint _id) public onlyVoter returns(bool success){
        require(frozen == false);

        for (uint p = 0; p < projects.length; p++){
            if(projects[p].id == _id && projects[p].active == true){
                projects[p].votesWeight += sqrt(accounts[msg.sender].balance);
                accounts[msg.sender].lastVotedBallotId = curentBallotId;
            }
        }
        emit Vote(msg.sender, _id, accounts[msg.sender].balance, curentBallotId);

        return true;
    }

     
    function winningProject() public constant returns (uint _winningProject){
        uint winningVoteWeight = 0;
        for (uint p = 0; p < projects.length; p++) {
            if (projects[p].votesWeight > winningVoteWeight && projects[p].active == true) {
                winningVoteWeight = projects[p].votesWeight;
                _winningProject = projects[p].id;
            }
        }
    }

     
     
    function enableVoting() public onlyAdmin returns(uint ballotId){ 
        require(votingActive == false);
        require(frozen == false);

        curentBallotId++;
        votingActive = true;

        delete projects;

        emit VotingOn(curentBallotId);
        return curentBallotId;
    }

     
    function disableVoting() public onlyAdmin returns(uint winner){
        require(votingActive == true);
        require(frozen == false);
        votingActive = false;

        curentWinner = winningProject();
        addWinner(curentWinner);
        
        emit VotingOff(curentWinner);
        return curentWinner;
    }


     
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

     




     
     
     

     
     
     
    function pay1(address to) public onlyAdmin returns(bool success){
        require(bitmask_check(to, 4) == false);
        uint new_amount = 100000000;
        payout(to,new_amount);
        bitmask_add(to, 4);
        return true;
    }

     
     
     
    function pay055(address to) public onlyAdmin returns(bool success){
        require(bitmask_check(to, 2) == false);
        uint new_amount = 55566600 + (block.timestamp%100);       
        payout(to,new_amount);
        bitmask_add(to, 2);
        return true;
    }

     
     
     
    function pay055loyal(address to) public onlyAdmin returns(bool success){
        require(epoch > 1);
        require(bitmask_check(to, 4) == true);
        uint new_amount = 55566600 + (block.timestamp%100);       
        payout(to,new_amount);
        return true;
    }

     
     
    function payCustom(address to, uint amount) public onlyOwner returns(bool success){
        payout(to,amount);
        return true;
    }

     
     
     
     
     
     
    function payout(address to, uint amount) private returns (bool success){
        require(to != address(0));
        require(amount>=current_mul());
        require(bitmask_check(to, 1024) == false);  
        require(frozen == false); 
        
         
        updateAccount(to);
         
        uint fixedAmount = fix_amount(amount);

        renewDec( accounts[to].balance, accounts[to].balance.add(fixedAmount) );

        uint team_part = (fixedAmount/100)*16;
        uint dao_part = (fixedAmount/10)*6;
        uint total = fixedAmount.add(team_part).add(dao_part);

        epoch_fund = epoch_fund.sub(total);
        team_fund = team_fund.add(team_part);
        redenom_dao_fund = redenom_dao_fund.add(dao_part);
        accounts[to].balance = accounts[to].balance.add(fixedAmount);
        _totalSupply = _totalSupply.add(total);

        emit Transfer(address(0), to, fixedAmount);
        return true;
    }
     




     

     
    function withdraw_team_fund(address to, uint amount) public onlyOwner returns(bool success){
        require(amount <= team_fund);
        accounts[to].balance = accounts[to].balance.add(amount);
        team_fund = team_fund.sub(amount);
        return true;
    }
     
    function withdraw_dao_fund(address to, uint amount) public onlyOwner returns(bool success){
        require(amount <= redenom_dao_fund);
        accounts[to].balance = accounts[to].balance.add(amount);
        redenom_dao_fund = redenom_dao_fund.sub(amount);
        return true;
    }

    function freeze_contract() public onlyOwner returns(bool success){
        require(frozen == false);
        frozen = true;
        return true;
    }
    function unfreeze_contract() public onlyOwner returns(bool success){
        require(frozen == true);
        frozen = false;
        return true;
    }
     


     
     
     
     
    function renewDec(uint initSum, uint newSum) internal returns(bool success){

        if(round < 9){
            uint tempInitSum = initSum; 
            uint tempNewSum = newSum; 
            uint cnt = 1;

            while( (tempNewSum > 0 || tempInitSum > 0) && cnt <= decimals ){

                uint lastInitSum = tempInitSum%10;  
                tempInitSum = tempInitSum/10;  

                uint lastNewSum = tempNewSum%10;  
                tempNewSum = tempNewSum/10;  

                if(cnt >= round){
                    if(lastNewSum >= lastInitSum){
                         
                        dec[decimals-cnt] = dec[decimals-cnt].add(lastNewSum - lastInitSum);
                    }else{
                         
                        dec[decimals-cnt] = dec[decimals-cnt].sub(lastInitSum - lastNewSum);
                    }
                }

                cnt = cnt+1;
            }
        } 

        return true;
    }



     
     
     
    function bitmask_add(address user, uint _bit) internal returns(bool success){  
        require(bitmask_check(user, _bit) == false);
        accounts[user].bitmask = accounts[user].bitmask.add(_bit);
        return true;
    }
     
     
    function bitmask_rm(address user, uint _bit) internal returns(bool success){
        require(bitmask_check(user, _bit) == true);
        accounts[user].bitmask = accounts[user].bitmask.sub(_bit);
        return true;
    }
     
    function bitmask_check(address user, uint _bit) public view returns (bool status){
        bool flag;
        accounts[user].bitmask & _bit == 0 ? flag = false : flag = true;
        return flag;
    }
     

    function ban_user(address user) public onlyAdmin returns(bool success){
        bitmask_add(user, 1024);
        return true;
    }
    function unban_user(address user) public onlyAdmin returns(bool success){
        bitmask_rm(user, 1024);
        return true;
    }
    function is_banned(address user) public view onlyAdmin returns (bool result){
        return bitmask_check(user, 1024);
    }
     



     
    function redenominate() public onlyAdmin returns(uint current_round){
        require(frozen == false); 
        require(round<9);  

         
        _totalSupply = _totalSupply.sub( team_fund%mul[round] ).sub( redenom_dao_fund%mul[round] ).sub( dec[8-round]*mul[round-1] );

         
        _totalSupply = ( _totalSupply / mul[round] ) * mul[round];
        team_fund = ( team_fund / mul[round] ) * mul[round];  
        redenom_dao_fund = ( redenom_dao_fund / mul[round] ) * mul[round];  

        if(round>1){
             
            uint superold = dec[(8-round)+1]; 

             
            epoch_fund = epoch_fund.add(superold * mul[round-2]);
            dec[(8-round)+1] = 0;
        }

        
        if(round<8){  

            uint unclimed = dec[8-round];  
             
            uint total_current = dec[8-1-round];  
             

             
            if(total_current==0){
                current_toadd = [0,0,0,0,0,0,0,0,0]; 
                round++;
                emit Redenomination(round);
                return round;
            }

             
            uint[9] memory numbers  =[uint(1),2,3,4,5,6,7,8,9];  
            uint[9] memory ke9  =[uint(0),0,0,0,0,0,0,0,0];  
            uint[9] memory k2e9  =[uint(0),0,0,0,0,0,0,0,0];  

            uint k05summ = 0;

                for (uint k = 0; k < ke9.length; k++) {
                     
                    ke9[k] = numbers[k]*1e9/total_current;
                    if(k<5) k05summ += ke9[k];
                }             
                for (uint k2 = 5; k2 < k2e9.length; k2++) {
                    k2e9[k2] = uint(ke9[k2])+uint(k05summ)*uint(weight[k2])/uint(100);
                }
                for (uint n = 5; n < current_toadd.length; n++) {
                    current_toadd[n] = k2e9[n]*unclimed/10/1e9;
                }
                 
                
        }else{
            if(round==8){
                 
                epoch_fund = epoch_fund.add(dec[0] * 10000000);  
                dec[0] = 0;
            }
            
        }

        round++;
        emit Redenomination(round);
        return round;
    }


    function actual_balance(address user) public constant returns(uint actual_balance){
        if(epoch > 1 && accounts[user].lastEpoch < epoch){
            return (accounts[user].balance/100000000)*100000000;
        }else{
            return (accounts[user].balance/current_mul())*current_mul();
        }
    }
   
     
     
    function updateAccount(address account) public returns(uint new_balance){
        require(frozen == false); 
        require(round<=9);
        require(bitmask_check(account, 1024) == false);  

        if(epoch > 1 && accounts[account].lastEpoch < epoch){
            uint entire = accounts[account].balance/100000000;
            accounts[account].balance = entire*100000000;
            return accounts[account].balance;
        }

        if(round > accounts[account].lastRound){

            if(round >1 && round <=8){


                 
                uint tempDividedBalance = accounts[account].balance/current_mul();
                 
                uint newFixedBalance = tempDividedBalance*current_mul();
                 
                uint lastActiveDigit = tempDividedBalance%10;
                  
                uint diff = accounts[account].balance - newFixedBalance;
                 

                if(diff > 0){
                    accounts[account].balance = newFixedBalance;
                    emit Transfer(account, address(0), diff);
                }

                uint toBalance = 0;
                if(lastActiveDigit>0 && current_toadd[lastActiveDigit-1]>0){
                    toBalance = current_toadd[lastActiveDigit-1] * current_mul();
                }


                if(toBalance > 0 && toBalance < dec[8-round+1]){  

                    renewDec( accounts[account].balance, accounts[account].balance.add(toBalance) );
                    emit Transfer(address(0), account, toBalance);
                     
                    accounts[account].balance = accounts[account].balance.add(toBalance);
                     
                    dec[8-round+1] = dec[8-round+1].sub(toBalance);
                     
                    _totalSupply = _totalSupply.add(toBalance);
                     
                }

                accounts[account].lastRound = round;
                 
                if(accounts[account].lastEpoch != epoch){
                    accounts[account].lastEpoch = epoch;
                }


                return accounts[account].balance;
                 
            }else{
                if( round == 9){  

                    uint newBalance = fix_amount(accounts[account].balance);
                    uint _diff = accounts[account].balance.sub(newBalance);

                    if(_diff > 0){
                        renewDec( accounts[account].balance, newBalance );
                        accounts[account].balance = newBalance;
                        emit Transfer(account, address(0), _diff);
                    }

                    accounts[account].lastRound = round;
                     
                    if(accounts[account].lastEpoch != epoch){
                        accounts[account].lastEpoch = epoch;
                    }


                    return accounts[account].balance;
                     
                }
            }
        }
    }

     
     
    function current_mul() internal view returns(uint _current_mul){
        return mul[round-1];
    }
     
     
    function fix_amount(uint amount) public view returns(uint fixed_amount){
        return ( amount / current_mul() ) * current_mul();
    }
     
    function get_rest(uint amount) internal view returns(uint fixed_amount){
        return amount % current_mul();
    }



     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return accounts[tokenOwner].balance;
    }
     
     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
     
     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(frozen == false); 
        require(to != address(0));
        require(bitmask_check(to, 1024) == false);  

         
        tokens = fix_amount(tokens);
         
        require(tokens>0);

         
        updateAccount(to);
        updateAccount(msg.sender);

        uint fromOldBal = accounts[msg.sender].balance;
        uint toOldBal = accounts[to].balance;

        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);

        require(renewDec(fromOldBal, accounts[msg.sender].balance));
        require(renewDec(toOldBal, accounts[to].balance));

        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        require(frozen == false); 
        require(bitmask_check(msg.sender, 1024) == false);  
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(frozen == false); 
        require(bitmask_check(to, 1024) == false);  
        updateAccount(from);
        updateAccount(to);

        uint fromOldBal = accounts[from].balance;
        uint toOldBal = accounts[to].balance;

        accounts[from].balance = accounts[from].balance.sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);

        require(renewDec(fromOldBal, accounts[from].balance));
        require(renewDec(toOldBal, accounts[to].balance));

        emit Transfer(from, to, tokens);
        return true; 
    }
     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        require(frozen == false); 
        require(bitmask_check(msg.sender, 1024) == false);  
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
     
     
     
    function () public payable {
        revert();
    }  

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        require(frozen == false); 
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }




}  