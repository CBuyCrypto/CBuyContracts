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
        uint256 createdOn;
    }

    address cUSDAddr;
    //userWalletAddr => userListings
    mapping(address => Listing[]) userListings;

    //listingId => Listing
    mapping(uint256 => Listing) listings;

    address[] private authorizedUsers;
    mapping(address => uint256) private authorizedUserBalance;

    uint256 idCounter = 0;

    uint256 cBuyPercentage = 50000000000000000; // 5%


    constructor(address _cUSDAddr){
        cUSDAddr = _cUSDAddr;
        authorizedUsers.push(msg.sender);
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
        listing.createdOn = block.number;

        // Deploy new escrow instance
        // Set escrow contract address
        Escrow escrowContract = new Escrow(listing.price, cUSDAddr, address(this));    
        listing.escrowAddr = address(escrowContract);   
        emit newEscrow(listing.escrowAddr, listing.itemId);


        // Connect to cUSD and transfer funds to marketplace contract
        ERC20 cUSD = ERC20(cUSDAddr);
        require(cUSD.balanceOf(msg.sender) >= listing.price * 2);
        cUSD.transferFrom(msg.sender, address(this), listing.price * 2);

        // Call sellerDeposit function
        // Have to approve transfer first
        cUSD.approve(listing.escrowAddr, listing.price * 2);    
        escrowContract.sellerDeposit(listing.price * 2, msg.sender);
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

        // Get cUSD from buyer
        ERC20 cUSD = ERC20(cUSDAddr);
        require(cUSD.balanceOf(msg.sender) >= listings[listingId].price * 2);
        cUSD.transferFrom(msg.sender, address(this), listings[listingId].price * 2);

        // Call buyerDeposit
        cUSD.approve(listings[listingId].escrowAddr, listings[listingId].price * 2);    
        escrowContract.buyerDeposit(listings[listingId].price * 2, msg.sender);
        require(escrowContract.getBuyerDeposit() == listings[listingId].price * 2, "Buyer deposit failed");

        listings[listingId].sold = true;
    }

    // listing id as a parameter 
    // access it via listing id 
    function releaseEscrow( uint256 listingId) public {
        //call releaseEscrow from Escrow
        address escrow_add = listings[listingId].escrowAddr;
        Escrow escrowContract = Escrow(escrow_add);  
        escrowContract.releaseEscrow();
        _receiveFee(listings[listingId].price / cBuyPercentage);
    }

    function getListingInfo(uint256 listingId) public view returns (Listing memory) {
        return listings[listingId];
    }

    function _receiveFee(uint256 totalFee) internal {
        uint256 feePerUser = totalFee / authorizedUsers.length;
        for(uint256 i = 0; i < authorizedUsers.length; i++){
            authorizedUserBalance[authorizedUsers[i]] += feePerUser;
        }
    }

    function withdraw() public {
        require(_isAuthorized(msg.sender), "You are not an authorized user");
        ERC20 cUSD = ERC20(cUSDAddr);
        cUSD.transfer(msg.sender, authorizedUserBalance[msg.sender]);
        authorizedUserBalance[msg.sender] = 0;
    }

    function authorizeUser(address newUser) public {
        require(_isAuthorized(msg.sender), "You are not an authorized user");
        authorizedUsers.push(newUser);
    }

    function _isAuthorized(address user) internal view returns (bool){
        for(uint256 i = 0; i < authorizedUsers.length; i++){
            if(authorizedUsers[i] == user){
                return true;
            }
        }
        return false;
    }

    function checkBalance() public returns (uint256) {
        return authorizedUserBalance[msg.sender];
    }

}


