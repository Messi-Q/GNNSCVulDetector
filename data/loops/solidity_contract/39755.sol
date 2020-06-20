pragma solidity ^0.4.6;

contract Presale {
    mapping (address => uint) public balances;
    uint public transfered_total = 0;
    
    uint public constant min_goal_amount = 5 ether;
    uint public constant max_goal_amount = 10 ether;
    
     
    address public project_wallet;

    uint public presale_start_block;
    uint public presale_end_block;
    
     
     
     
    uint constant blocks_in_one_months = 100;
    
     
     
    uint public refund_window_end_block;
    
    function Presale(uint _start_block, uint _end_block, address _project_wallet) {
        if (_start_block <= block.number) throw;
        if (_end_block <= _start_block) throw;
        if (_project_wallet == 0) throw;
        
        presale_start_block = _start_block;
        presale_end_block = _end_block;
        project_wallet = _project_wallet;
	refund_window_end_block = presale_end_block + blocks_in_one_months;
    }
	
    function has_presale_started() private constant returns (bool) {
	return block.number >= presale_start_block;
    }
    
    function has_presale_time_ended() private constant returns (bool) {
        return block.number > presale_end_block;
    }
    
    function is_min_goal_reached() private constant returns (bool) {
        return transfered_total >= min_goal_amount;
    }
    
    function is_max_goal_reached() private constant returns (bool) {
        return transfered_total >= max_goal_amount;
    }
    
     
    function () payable {
	 
        if (!has_presale_started()) throw;
	    
	 
	if (has_presale_time_ended()) throw;
	    
	 
	if (msg.value == 0) throw;

         
	if (is_max_goal_reached()) throw;
        
        if (transfered_total + msg.value > max_goal_amount) {
             
	    var change_to_return = transfered_total + msg.value - max_goal_amount;
	    if (!msg.sender.send(change_to_return)) throw;
            
            var to_add = max_goal_amount - transfered_total;
            balances[msg.sender] += to_add;
	    transfered_total += to_add;
        } else {
             
	    balances[msg.sender] += msg.value;
	    transfered_total += msg.value;
        }
    }
    
     
    function transfer_funds_to_project() {
        if (!is_min_goal_reached()) throw;
        if (this.balance == 0) throw;
        
         
        if (!project_wallet.send(this.balance)) throw;
    }
    
     
     
    function refund() {
        if (!has_presale_time_ended()) throw;
        if (is_min_goal_reached()) throw;
        if (block.number > refund_window_end_block) throw;
        
        var amount = balances[msg.sender];
         
        if (amount == 0) throw;
        
         
        balances[msg.sender] = 0;
        
         
        if (!msg.sender.send(amount)) throw;
    }
    
     
    function transfer_left_funds_to_project() {
        if (!has_presale_time_ended()) throw;
        if (is_min_goal_reached()) throw;
        if (block.number <= refund_window_end_block) throw;
        
        if (this.balance == 0) throw;
         
        if (!project_wallet.send(this.balance)) throw;
    }
}