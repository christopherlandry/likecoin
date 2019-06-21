pragma solidity >=0.4.25 <0.6.0;

import "./ConvertLib.sol";

contract Wuffie {
	uint moneyPool; //pooled money to pay out
	uint uncollectedVotes; //total as-yet uncollected votes in system
	uint totalReputation; //grand total reputation 
	mapping (address => uint) reputation;
	mapping (address => uint) balance;
	mapping (address => Vote[]) upvotes;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Upvote(address indexed _from, address indexed _to);
	event CollectMoney(address _user, uint value);

	struct Vote {
		address voter;
		uint timestamp; 
	}

	constructor() public {
		uncollectedVotes = 0;
		reputation[tx.origin] = 1;
		totalReputation = 1;
		balance[tx.origin] = 20000; //have some money, creator
		moneyPool = 0;
	}

	function upVote(address user) public returns(bool success) {
		if (user == msg.sender) return false;
		moneyPool += 1000; //add some money to the pool
		reputation[user] += 1;
		totalReputation += 1;
		upvotes[user].push(Vote(msg.sender, now));
		uncollectedVotes += 1;
		emit Upvote(msg.sender, user);
		_payout(msg.sender); //user now collects their votes
		return true;
	}

	function _payout(address user) private {
		uint amount = 0;
		uint votes = 0;
		for(uint i=0; i < upvotes[user].length; i++) {
			address voter = upvotes[user][i].voter;
			//fraction of total money proportial to reputation of voter and number of votes tallied
			//in a theoreticaly ideal world, this would equal the whole money pool if everyone
			//collected simultaneously.  it won't, because of time decay and the fact that there's
			//at least one uncollected upvote: the one you just made.
			amount += (moneyPool * reputation[voter]) / (totalReputation * uncollectedVotes);
			amount -= (now - upvotes[user][i].timestamp) / 3600; //time decay
			votes += 1;
		}

		//clear votes
		uncollectedVotes -= votes;
		delete upvotes[user];
		balance[user] += amount;
		moneyPool -= amount;
		emit CollectMoney(user, amount);
	}

	/*function sendRep(address receiver, uint amount) public returns(bool sufficient) {
		if (reputation[msg.sender] < amount) return false;
		reputation[msg.sender] -= amount;
		reputation[receiver] += amount;
		emit Transfer(msg.sender, receiver, amount);
		return true;
	}*/

	function getBalance(address addr) public view returns(uint) {
		return balance[addr];
	}
}
