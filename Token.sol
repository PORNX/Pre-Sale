pragma solidity ^0.4.11;

contract Token {
    enum States {
        Initial, // deployment time
        PreSale, // accept funds, update balances
        Underfunded, // refund to investors
        Funded // payout to holder
    }
    string public constant name = "PORNX";
    string public constant symbol = "PORNX";
    // 29.01.2018 08:00:00 GMT+8
    uint public constant start_timestamp = 1517184000;
    // 11.02.2018 23:59:59 GMT +8
    uint public constant end_timestamp = 1518307200;
    States public state;        
    uint256 public currentCoins;
    uint256 public currentCoinsWithBonuses;
    address public initialHolder;
    mapping (address => uint256) public balances;
    mapping (address => uint256) public balances_eth;
    function Token() 
    public 
    {
        currentCoins = 0;
        currentCoinsWithBonuses = 0;
        initialHolder = msg.sender;
        state = States.Initial;
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
            if (currentCoins < 15000000) {
                state = States.PreSale;
            } else {
                state = States.Funded;
            }
        } else {
            if (currentCoins > 4500000) {
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
        uint256 coinIncrease = msg.value / 10000000000000000 * 30;
        uint256 _coinBonus = coinIncrease / 10 * 3;
        currentCoins += coinIncrease;
        currentCoinsWithBonuses += coinIncrease + _coinBonus;
        balances[msg.sender] += coinIncrease + _coinBonus;
        balances_eth[msg.sender] += msg.value/(1 ether);
        Credited(msg.sender, balances[msg.sender], msg.value, _coinBonus);
    }
}
