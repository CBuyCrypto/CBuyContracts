pragma solidity ^0.8.0;

import './Escrow.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Marketplace{
    enum ListingStatus{ AVAILABLE, SOLD, RECEIVED, INACTIVE }
    struct Listing{
        string name;
        string description;
        uint256 price;
        string ipfsHash;
        ListingStatus status;
        uint256 itemId;
        address escrowAddr;
    }

    constructor(address _cUSDAddr){
        cUSDAddr = _cUSDAddr;
    }

    address cUSDAddr;

    //userWalletAddr => userListings
    mapping(address => Listing[]) userListings;

    //listingId => Listing
    mapping(uint256 => Listing) listingsMap;

    mapping(address => Listing[]) userPurchases;

    Listing[] listingsArr;

    uint256 idCounter = 0;

    event newListing(string name, string description, uint256 price, string ipfsHash, bool sold, uint256 itemId);

    event newEscrow(address contractAddr, uint256 itemId);

    function newItem(string memory name, string memory description, uint256 price, string memory ipfsHash) public {
        Listing memory listing;
        listing.name = name;
        listing.description = description;
        listing.price = price;
        listing.ipfsHash = ipfsHash;
        listing.status = ListingStatus.AVAILABLE;
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

        listingsMap[idCounter] = listing;
        userListings[msg.sender].push(listing);
        listingsArr.push(listing);

        idCounter++;
        
        emit newListing(name, description, price, ipfsHash, false, idCounter);
    }

    function getUserListings() public view returns(Listing[] memory){
        return userListings[msg.sender];
    }

    function purchase(uint256 listingId) public{
        Escrow escrowContract = Escrow(listingsMap[listingId].escrowAddr);
        ERC20 cUSD = ERC20(cUSDAddr);

        // Get cUSD from buyer
        require(cUSD.balanceOf(msg.sender) >= listingsMap[listingId].price * 2);
        cUSD.transferFrom(msg.sender, address(this), listingsMap[listingId].price * 2);

        // Call buyerDeposit
        cUSD.approve(listingsMap[listingId].escrowAddr, listingsMap[listingId].price * 2);    
        escrowContract.buyerDeposit(listingsMap[listingId].price * 2);
        userPurchases[msg.sender].push(listingsMap[listingId]);
        require(escrowContract.getBuyerDeposit() == listingsMap[listingId].price * 2, "Buyer deposit failed");

    }

    // listing id as a parameter 
    // access it via listing id 
    function releaseEscrow( uint256 listingid) public {
        //call releaseEscrow from Escrow
        address escrow_add = listingsMap[listingid].escrowAddr;
        Escrow escrowContract = Escrow(escrow_add);  
        escrowContract.releaseEscrow();
    }

    function getListingInfo(uint256 listingId) public view returns (Listing memory) {
        return listingsMap[listingId];
    }

    function getListings() public view returns(Listing[] memory){
        return listingsArr;
    }

    function deactivateListing(uint256 itemId) public {
        listingsMap[itemId].status = ListingStatus.INACTIVE;
    }

    function getUserListings(address wallet) public view returns(Listing[] memory){
        return userPurchases[wallet];
    }

}
