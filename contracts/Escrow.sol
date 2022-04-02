pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//I havent tested this contract yet, in theory it should work tho!
contract Escrow{
    uint256 itemValue;
    IERC20 cUSD;

    constructor(uint256 _itemValue, address _cUSDAddr, address marketPlaceAddr){
        itemValue = _itemValue;
        cUSD = IERC20(_cUSDAddr);
        cBuy = marketPlaceAddr;
    }

    uint256 buyerDep = 0;
    uint256 sellerDep = 0;
    address buyer = address(0); //buyer address 
    address seller = address(0); // seller address 
    // uint256 escrowAgentPercentage = 50000000000000000; // 5%
    uint256 cBuyFraction = 40; // 5%
    uint256 feeFraction = (cBuyFraction) * 2;
    address cBuy;



    function buyerDeposit(uint256 amount, address _buyer) public {
        require(amount == itemValue*2);
        cUSD.transferFrom(msg.sender, address(this), amount);
        buyerDep+=amount;
        buyer = _buyer; 
    }

    function sellerDeposit(uint256 amount, address _seller) public {
        require(amount == itemValue*2);
        cUSD.transferFrom(msg.sender, address(this), amount);   //Note: need to approve
        sellerDep+=amount;
        seller = _seller; 
    }

    function releaseEscrow() public {
        require(seller != address(0)); //buyer address 
        require(buyer != address(0)); // seller address 

        //require both buyer and seller deposited 2x inital item value
        require(buyerDep == itemValue*2);
        require(sellerDep == itemValue*2);

        // //move .5 the buyers deposit to the seller
        // cUSD.transferFrom(buyer, seller, buyerDep / 2); //Note: make sure to approv this
        // sellerDep -= buyerDep / 2;

        // //release both buyer and seller deposits
        // cUSD.transferFrom(address(this), buyer, buyerDep);
        // cUSD.transferFrom(address(this), seller, sellerDep);

        cUSD.transfer(seller, itemValue + itemValue + itemValue - itemValue / feeFraction);   // sale + deposit - 2.5%
        cUSD.transfer(buyer, itemValue - itemValue / feeFraction);                // deposit - 2.5%
        cUSD.transfer(cBuy, itemValue / cBuyFraction);                            // 5%

        sellerDep = 0;
        buyerDep = 0;
    }

    function getSellerDeposit() public view returns (uint256) {
        return sellerDep;
    }

    function getBuyerDeposit() public view returns (uint256) {
        return buyerDep;
    }
}
