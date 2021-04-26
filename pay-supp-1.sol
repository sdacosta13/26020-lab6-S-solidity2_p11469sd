pragma solidity ^0.6.1;
contract Paylock{
    enum State{Working, Completed, Done_1, Delay, Done_2, Forfeit}
    struct Data {
        State st;
        int256 disc;
    }
    address timeAdd;
    int clock;
    Data data;
    address supp1Add;
    event Collect(State st, int256 disc);
    constructor() public {
        data.st = State.Working;
        data.disc = 0;
        clock = 0;
        timeAdd = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    }
    function tick() external{
        require(data.st != State.Working);
        require(msg.sender == timeAdd);
        clock += 1;
    }

    function signal() external {
        require( data.st == State.Working );
        data.st = State.Completed;
        data.disc = 10;
        supp1Add = msg.sender;
    }

    function collect_1_Y() external {
        require( data.st == State.Completed );
        require(clock < 4);
        data.st = State.Done_1;
        data.disc = 10;
        emit Collect(data.st, data.disc);
    }

    function collect_1_N() external {
        require( data.st == State.Completed );
        data.st = State.Delay;
        data.disc = 5;
        emit Collect(data.st, data.disc);
    }

    function collect_2_Y() external {
        require( data.st == State.Delay );
        require(clock < 8);
        data.st = State.Done_2;
        data.disc = 5;
        emit Collect(data.st, data.disc);
    }

    function collect_2_N() external {
        require( data.st == State.Delay );
        data.st = State.Forfeit;
        data.disc = 0;
        emit Collect(data.st, data.disc);
    }

}
contract Supplier {

    Paylock p;

    enum State { Working , Completed , Done_1 , Delay , Done_2 , Forfeit }

    State st;

    constructor(address pp) public {
        p = Paylock(pp);
        st = State.Working;
    }

    function signal_paylock() external {
        p.signal();
        st = State.Completed;
    }

    function getpaid_1_Y() external {
        p.collect_1_Y();
        st = State.Done_1;
    }

    function getpaid_1_N() external {
        p.collect_1_N();
        st = State.Delay;
    }

    function getpaid_2_Y() external {
        p.collect_2_Y();
        st = State.Done_2;
    }

    function getpaid_2_N() external {
        p.collect_2_N();
        st = State.Forfeit;
    }

}
