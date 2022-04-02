pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//I havent tested this contract yet, in theory it should work tho!
contract Escrow{
    uint256 itemValue;
    IERC20 cUSD;

    constructor(uint256 _itemValue, address _cUSDAddr){
        itemValue = _itemValue;
        cUSD = IERC20(_cUSDAddr);
    }

    uint256 buyerDep = 0;
    uint256 sellerDep = 0;
    address buyer = address(0); //buyer address 
    address seller = address(0); // seller address 


    function buyerDeposit(uint256 amount) public {
        require(amount == itemValue*2);
        cUSD.transferFrom(msg.sender, address(this), amount);
        buyerDep+=amount;
        buyer = msg.sender; 
    }

    function sellerDeposit(uint256 amount) public {
        require(amount == itemValue*2);
        cUSD.transferFrom(msg.sender, address(this), amount);   //Note: need to approve
        sellerDep+=amount;
        seller = msg.sender; 
    }

    function releaseEscrow() public {
        require(seller != address(0)); //buyer address 
        require(buyer != address(0)); // seller address 

        //require both buyer and seller deposited 2x inital item value
        require(buyerDep == itemValue*2);
        require(sellerDep == itemValue*2);

        //move .5 the buyers deposit to the seller
        cUSD.transferFrom(buyer, seller, buyerDep / 2);
        sellerDep -= buyerDep / 2;

        //release both buyer and seller deposits
        cUSD.transferFrom(address(this), buyer, buyerDep);
        cUSD.transferFrom(address(this), seller, sellerDep);
    }

    function getSellerDeposit() public view returns (uint256) {
        return sellerDep;
    }

    function getBuyerDeposit() public view returns (uint256) {
        return buyerDep;
    }
}