 

pragma solidity >=0.4.10;

 
contract Token {
	function balanceOf(address addr) returns(uint);
	function transfer(address to, uint amount) returns(bool);
}

contract Sale {
	address public owner;     
	address public newOwner;  
	string public notice;     
	uint public start;        
	uint public end;          
	uint public cap;          
	bool public live;         

	event StartSale();
	event EndSale();
	event EtherIn(address from, uint amount);

	function Sale() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function () payable {
		require(block.timestamp >= start);

		if (block.timestamp > end || this.balance > cap) {
			require(live);
			live = false;
			EndSale();
		} else if (!live) {
			live = true;
			StartSale();
		}
		EtherIn(msg.sender, msg.value);
	}

	function init(uint _start, uint _end, uint _cap) onlyOwner {
		start = _start;
		end = _end;
		cap = _cap;
	}

	function softCap(uint _newend) onlyOwner {
		require(_newend >= block.timestamp && _newend >= start && _newend <= end);
		end = _newend;
	}

	 
	function changeOwner(address next) onlyOwner {
		newOwner = next;
	}

	 
	function acceptOwnership() {
		require(msg.sender == newOwner);
		owner = msg.sender;
		newOwner = 0;
	}

	 
	function setNotice(string note) onlyOwner {
		notice = note;
	}

	 
	function withdraw() onlyOwner {
		msg.sender.transfer(this.balance);
	}

	 
	function withdrawSome(uint value) onlyOwner {
		require(value <= this.balance);
		msg.sender.transfer(value);
	}

	 
	function withdrawToken(address token) onlyOwner {
		Token t = Token(token);
		require(t.transfer(msg.sender, t.balanceOf(this)));
	}

	 
	function refundToken(address token, address sender, uint amount) onlyOwner {
		Token t = Token(token);
		require(t.transfer(sender, amount));
	}
}