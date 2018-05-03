pragma solidity ^0.4.18;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);123
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
contract Presale {
    using SafeMath for uint256;
    enum States {
        Initial, // deployment time
        PreSale, // accept funds, update balances
        Underfunded, // refund to investors
        Funded // payout to holder
    }
    string public constant name = "PORNX";
    string public constant symbol = "PORNX";
    // 02/11/2018 10:00:00 GMT+8
    uint public constant start_timestamp = 1518314400;
    // 02/25/2018 23:59:59 GMT+8
    uint public constant end_timestamp = 1519574399;
    States public state;        
    uint256 public currentEth;
    uint256 public currentCoins;
    uint256 public currentCoinsWithBonuses;
    uint256 public maxCoinsWithBonuses;
    uint256 public minCoinsCap;
    address public initialHolder;
    mapping (address => uint256) public balances;
    mapping (address => uint256) public balances_eth;
    function Presale() 
    public 
    {
        currentEth = 0;
        currentCoins = 0;
        currentCoinsWithBonuses = 0;
        initialHolder = msg.sender;
        state = States.Initial;
        maxCoinsWithBonuses = 15000000;
        minCoinsCap = 4500000;
    }
    event Credited(address addr, uint balance, uint txAmount, uint bonusWas);
    event StateTransition(States oldState, States newState);
    modifier requireState(States _requiredState) {
        require(state == _requiredState);
        _;
    }
    modifier minAmount(uint256 amount) {
        require(amount >= 50000000000000000);
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == initialHolder);
        _;
    }
    function requestRefund()
    requireState(States.Underfunded)
    public
    {
        require(balances_eth[msg.sender] > 0);
        uint256 payout = balances_eth[msg.sender];
        balances_eth[msg.sender] = 0;
        balances[msg.sender] = 0;
        msg.sender.transfer(payout);
    }
    function requestPayout(uint256 _amount)
    onlyOwner
    requireState(States.Funded)
    public
    {
        msg.sender.transfer(_amount);
    }
    function check()
    public 
    {
        if (now < start_timestamp) {
            state = States.Initial;
        } else if (now < end_timestamp) {
            if (currentCoins < maxCoinsWithBonuses) {
                state = States.PreSale;
            } else {
                state = States.Funded;
            }
        } else {
            if (currentCoins > minCoinsCap) {
                state = States.Funded;   
            } else {
                state = States.Initial;    
            }
        }
    }
    function moveToState(States _newState)
    onlyOwner
    requireState(States.Initial)
    public
    {
        StateTransition(state, _newState);
        state = _newState;
    }
    function() payable
    requireState(States.PreSale)
    minAmount(msg.value)
    public
    {
        uint256 _coinIncrease = msg.value * 3000 / 1000000000000000000 ;
        uint256 _coinBonus = _coinIncrease * 30 / 100;
        require (maxCoinsWithBonuses - currentCoinsWithBonuses >= _coinIncrease + _coinBonus);
        currentEth += msg.value;
        currentCoins += _coinIncrease;
        currentCoinsWithBonuses += _coinIncrease + _coinBonus;
        balances[msg.sender] += _coinIncrease + _coinBonus;
        balances_eth[msg.sender] += msg.value;
        Credited(msg.sender, _coinIncrease + _coinBonus, msg.value, _coinBonus);
    }
}
