//SPDX-License-Identifier: unlincesed;
pragma solidity ^0.7.4;
 
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Escrow {
 
    using SafeMath for uint;
    
    mapping(address=> uint) balances;

    address payable public escrowOwner;
    address payable public buyer;
    address payable public seller;
 
    uint public ID;
    uint public escrowCharges;

    bool public sellerApproval;
    bool public buyerApproval;

    bool public sellerCancel;
    bool public buyerCancel;

    uint[] public deposites;

    uint public feePercent;
    uint public feeAmount;
    uint public sellerAmount;

    enum State{ unInitialized, initialized, buyerDeposited, serviceApproved, complete, cancelled}

    State public escrowState = State.unInitialized;

    event Deposite (address depositor, uint deposited);
    event ServicePayment (uint blockNumber, uint contractBalance); 

    modifier onlyEscrowOwner(){
        require(msg.sender == escrowOwner, "Only Escrow owner can perform this operation");
            _;
    }

    modifier onlyBuyer(){
        require(msg.sender == buyer, "Only buyer can perform this operation");
            _;
    }
 
    modifier ifApprovedOrCancelled() {
        require((escrowState == State.serviceApproved) || (escrowState == State.cancelled));
            _;
    }

    //Constructor is called from EscrowFactory contract
    constructor(
        address payable _factoryOwner,
        uint _ID
    ){
        escrowOwner = _factoryOwner;
        ID = _ID;
    }

    //Initializes the escrow contract
    function initEscrow(
        address payable _buyer, 
        address payable _seller,
        uint _feePercent
    ) public onlyEscrowOwner{
        
        buyer = _buyer;
        seller = _seller;
        feePercent = _feePercent;
        escrowState = State.initialized;

        balances[buyer] = 0;
        balances[seller] = 0;
    }

    //Buyer deposites amount to escrow contract
    function depositeToEscrow()
    public 
    payable
    onlyBuyer
    {
        balances[buyer] = balances[buyer].add(msg.value);
        deposites.push(msg.value);
        escrowCharges += msg.value;
        escrowState = State.buyerDeposited;

        emit Deposite(msg.sender, msg.value);
    }

    //Buyer and Seller approve the deal
    function approveEscrow()
    public{
        if(msg.sender == buyer){
            buyerApproval = true;
        }else if(msg.sender == seller){
            sellerApproval = true;
        }

        if(buyerApproval && sellerApproval){
            escrowState = State.serviceApproved;
            deductFee();
            payToSeller();
        }
    }

    //Deduct and transfer escrow fees to escrow owner
    function deductFee() private{
        uint fee = (address(this).balance * feePercent)/100;
        feeAmount = fee;
        escrowOwner.transfer(fee);
        balances[buyer] = balances[buyer].sub(fee);
    }

    //Trasnfer remaining balance to seller
    function payToSeller() private{
        balances[buyer] = balances[buyer].sub(address(this).balance);
        balances[seller] = balances[seller].add(address(this).balance);

        escrowState = State.complete;
        sellerAmount = address(this).balance;
        seller.transfer(sellerAmount);
    }

    //Buyer and seller cancel the deal and buyer gets the refund
    function cancelEscrow() public  {
        if (msg.sender == seller) {
            sellerCancel = true;
        } else if (msg.sender == buyer) {
            buyerCancel = true;
        }
        if (sellerCancel && buyerCancel) {
            escrowState = State.cancelled;
            refund();
        }
    }

    //Buyer gets the refund
    function refund() private {
        buyer.transfer(address(this).balance);
    }

    //Destruct the escrow
    function endEscrow() public onlyEscrowOwner {
        selfdestruct(escrowOwner);
    }

    //A fallback function to avoid any other payment to this contract
    fallback() external{
        revert();
    }

}

contract EscrowFactory {
    address[] public escrowContracts;
    uint public escrowCount;
    address payable owner;

    //Factory contructor
    constructor(){
        owner = msg.sender;
        escrowCount = 0;
    }

    // Creates new Escrow smart contract
    function createEscrow() public {
        Escrow newEscrow = new Escrow(owner, escrowCount++);
        escrowContracts.push(address(newEscrow));
    }

    // Returns all escrow contracts list
    function getAllEscrows() public view returns(address[] memory){
        return escrowContracts;
    }

    // Returns single contract address for given ID
    function getByID(uint _ID) public view returns(address){
        return escrowContracts[_ID];
    }
}