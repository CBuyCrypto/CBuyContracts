pragma solidity ^0.8.0;

import './Escrow.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Marketplace{
    struct Listing{
        string name;
        string description;
        uint256 price;
        string ipfsHash;
        bool sold;
        uint256 itemId;
        address escrowAddr;
    }

    address cUSDAddr;

    //userWalletAddr => userListings
    mapping(address => Listing[]) userListings;

    //listingId => Listing
    mapping(uint256 => Listing) listings;

    uint256 idCounter = 0;

    constructor(address _cUSDAddr){
        cUSDAddr = _cUSDAddr;
    }

    event newListing(string name, string description, uint256 price, string ipfsHash, bool sold, uint256 itemId);

    event newEscrow(address contractAddr, uint256 itemId);

    function newItem(string memory name, string memory description, uint256 price, string memory ipfsHash) public {
        Listing memory listing;
        listing.name = name;
        listing.description = description;
        listing.price = price;
        listing.ipfsHash = ipfsHash;
        listing.sold = false;
        listing.itemId = idCounter;

        // Deploy new escrow instance
        // Set escrow contract address
        Escrow escrowContract = new Escrow(listing.price, cUSDAddr);    
        listing.escrowAddr = address(escrowContract);   
        emit newEscrow(listing.escrowAddr, listing.itemId);


        // Connect to cUSD and transfer funds to marketplace contract
        ERC20 cUSD = ERC20(cUSDAddr);
        require(cUSD.balanceOf(msg.sender) >= listing.price * 2);
        cUSD.transferFrom(msg.sender, address(this), listing.price * 2);

        // Call sellerDeposit function
        // Have to approve transfer first
        cUSD.approve(listing.escrowAddr, listing.price * 2);    
        escrowContract.sellerDeposit(listing.price * 2);
        require(escrowContract.getSellerDeposit() == listing.price * 2, "Seller deposit failed");

        listings[idCounter] = listing;
        userListings[msg.sender].push(listing);

        idCounter++;
        
        emit newListing(name, description, price, ipfsHash, false, idCounter);
    }

    function getUserListings() public view returns(Listing[] memory){
        return userListings[msg.sender];
    }

    function purchase(uint256 listingId) public{
        Escrow escrowContract = Escrow(listings[listingId].escrowAddr);
        ERC20 cUSD = ERC20(cUSDAddr);

        // Get cUSD from buyer
        require(cUSD.balanceOf(msg.sender) >= listings[listingId].price * 2);
        cUSD.transferFrom(msg.sender, address(this), listings[listingId].price * 2);

        // Call buyerDeposit
        cUSD.approve(listings[listingId].escrowAddr, listings[listingId].price * 2);    
        escrowContract.buyerDeposit(listings[listingId].price * 2);
        require(escrowContract.getBuyerDeposit() == listings[listingId].price * 2, "Buyer deposit failed");
    }

    function releaseEscrow() public {
        //call releaseEscrow from Escrow
    }

    function getListingInfo(uint256 listingId) public returns (listing) {
        return listings[listingId];
    }

}


