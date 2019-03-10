//
//Author: Mansoor Ahmed
//
pragma solidity ^0.5.5;
//The first contract, this will establish the admin accounts and other "God" functions
//Install truffle and run using Remix
contract GenesisContract {
    address GlobalAdmin;    //Only global admin can secondary managers
    mapping(address => bool) public SecondaryManagers;  //There may be multiple managers
    constructor() public payable {
        //Constructor; therefore, set the global admin here
        GlobalAdmin = msg.sender; 
    }

    //Modifiers are used to limit access to functions
    modifier onlyGlobalAdmin() {
        if (msg.sender != GlobalAdmin)
            revert();
        _; //The actual function will expand inline instead of the _;
    }

    modifier onlySecondaryManagers() {
        if (!SecondaryManagers[msg.sender]) //If sender is not a secondary admin
            revert();
        _;
    }

    function addSecondaryManager (address newSM) public onlyGlobalAdmin returns (bool success) {
        if (SecondaryManagers[newSM]) //if user already exists return false
            return false;
        SecondaryManagers[newSM] = true;
        return true;
    }

    function isSecondaryManager (address checkadd) public view returns (bool result) { 
        return SecondaryManagers[checkadd];
    }
}

contract UBISciFi {    
    GenesisContract gencon;
    address GenconAddress;
    address GlobalAdmin; 
    uint time_between_payoffs; //Minimum time between payoffs
    //uint currentpot; //This is place holder currency; in production we'll use wei or whatever currency we decide
    uint num_payees; 
    string payees;
    uint timestamp_lastpayoff;
    uint timestamp_lastreceipt;
    mapping(address => bool) public payeemap;
    address[] public payeearr;
    constructor() public payable {
        timestamp_lastpayoff = block.timestamp;
        timestamp_lastreceipt = block.timestamp;
        time_between_payoffs = 10; //10 seconds
        GlobalAdmin = msg.sender;
        num_payees = 0;
        payees = "";
    }
        //Modifiers are used to limit access to functions
    modifier onlyGlobalAdmin() {
        if (msg.sender != GlobalAdmin)
            revert();
        _; //The actual function will expand inline instead of the _;
    }
    function registerGenesis (address genAd) public onlyGlobalAdmin returns (bool) { //The address should be of the already deployed genesis
        GenconAddress = genAd;
        gencon = GenesisContract(GenconAddress);
        return true;
    }
    function isReadyToPayoff () public view returns (bool){
        if (!(block.timestamp > timestamp_lastpayoff + time_between_payoffs))
            return false;
        if (address(this).balance < num_payees) //if we can't pay at least one wei to each payee, we wait.
            return false;
        return true;
    }
    function addPayee (address toadd) public returns (bool){
        if(!(gencon.isSecondaryManager(msg.sender)))
            return false;
        if(payeemap[toadd])
            return false; //Trying to add two times.
        payeemap[toadd] = true;
        num_payees = num_payees + 1;
        payeearr.push(toadd);
        return true;
    }
    function removePayee (address toremove) public returns (bool){
        if(!(gencon.isSecondaryManager(msg.sender)))
            return false;
        if(!payeemap[toremove])
            return false;
        payeemap[toremove] = false;
        num_payees = num_payees - 1;
        uint i = 0;
        while (payeearr[i] != toremove){
            i++;
        }
        payeearr[i] = payeearr[num_payees];
        delete payeearr[num_payees];
        payeearr.length--;
        return true;
    }
    event paymentrecvd(
        bool received
    );
    function () external payable {
        timestamp_lastreceipt = block.timestamp;
        emit paymentrecvd(true);
    }
    function triggerPayoff () public returns (bool){
        if(!isReadyToPayoff())
            return false;
        uint amount_to_send = (address(this).balance - (address(this).balance % num_payees)) / num_payees;
        for(uint i = 0; i < num_payees; i++){
            if(payeemap[payeearr[i]]){
                address(uint160(payeearr[i])).transfer(amount_to_send);
            }
        }
        timestamp_lastpayoff = block.timestamp;
        return true;
    }  
    function numberPayees () public view returns (uint){
        return num_payees;
    }
    function returnCurrentPot () public view returns (uint){
        return address(this).balance;
    }
}