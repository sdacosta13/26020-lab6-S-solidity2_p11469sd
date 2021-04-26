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
    Rental r;
    enum State { Working , Completed , Done_1 , Delay , Done_2 , Forfeit }
    enum ResourceState { Untouched, Acquired, Released }
    event Paid(uint256 bal);
    State st;
    ResourceState rSt;
    constructor(address pp, address payable rent) public payable{
        p = Paylock(pp);
        r = Rental(rent);
        st = State.Working;
        rSt = ResourceState.Untouched;
    }

    function signal_paylock() external {
        require(rSt == ResourceState.Released && st == State.Working);
        p.signal();
        st = State.Completed;
    }

    function getpaid_1_Y() external {
        require(st == State.Completed);
        p.collect_1_Y();
        st = State.Done_1;
    }

    function getpaid_1_N() external {
        require(st == State.Completed);
        p.collect_1_N();
        st = State.Delay;
    }

    function getpaid_2_Y() external {
        require(st == State.Delay);
        p.collect_2_Y();
        st = State.Done_2;
    }

    function getpaid_2_N() external {
        require(st == State.Delay);
        p.collect_2_N();
        st = State.Forfeit;
    }
    function acquire_resource() external payable{
        require(rSt == ResourceState.Untouched);
        r.rent_out_resource.value(1 wei)();
        rSt = ResourceState.Acquired;
    }
    function return_resource() external{
        require(rSt == ResourceState.Acquired);
        r.retrieve_resource();
        rSt = ResourceState.Released;
    }

    fallback() payable external {
        emit Paid(address(this).balance);
        if(address(r).balance > 1 wei){
            r.retrieve_resource();
        }
    }

}
contract Rental {

    uint256 public deposit = 1 wei;
    address resource_owner;
    bool resource_available;

    constructor() public payable {
        resource_available = true;
    }

    function rent_out_resource() external payable {
        require(resource_available == true);
        require(msg.value == deposit);
        resource_owner = msg.sender;
        resource_available = false;
    }

    function retrieve_resource() external {
        require(resource_available == false && msg.sender == resource_owner);
        resource_available = true;
        (bool sucess,) = resource_owner.call.value(deposit)("");
        require(sucess);

    }

    function report_balance() external view returns(uint256) {
        return address(this).balance;
    }

    receive() external payable {
    }
}
