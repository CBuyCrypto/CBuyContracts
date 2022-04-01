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

    function buyerDeposit(uint256 amount) public {
        require(amount == itemValue*2);
        cUSD.transferFrom(msg.sender, address(this), amount);
        buyerDep+=amount;
    }

    function sellerDeposit(uint256 amount) public {
        require(amount == itemValue*2);
        cUSD.transferFrom(msg.sender, address(this), amount);
        sellerDep+=amount;
    }

    function releaseEscrow() public {
        //require both buyer and seller deposited 2x inital item value
        //move .5 the buyers deposit to the seller
        //release both buyer and seller deposits
    }
}


