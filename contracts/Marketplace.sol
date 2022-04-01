pragma solidity ^0.8.0;

contract Marketplace{
    struct Listing{
        string name;
        string description;
        uint256 price;
        string ipfsHash;
        bool sold;
        uint256 itemId;
    }

    //userWalletAddr => userListings
    mapping(address => Listing[]) userListings;

    uint256 idCounter = 0;

    event newListing(string name, string description, uint256 price, string ipfsHash, bool sold, uint256 itemId);

    function newItem(string memory name, string memory description, uint256 price, string memory ipfsHash) public {
        Listing memory listing;
        listing.name = name;
        listing.description = description;
        listing.price = price;
        listing.ipfsHash = ipfsHash;
        listing.sold = false;
        listing.itemId = idCounter;

        idCounter++;

        //NEEDS TO CREATE A NEW ESCROW AND DO STUFF HERE!!!

        userListings[msg.sender].push(listing);
        
        emit newListing(name, description, price, ipfsHash, false, idCounter);
    }

    function getUserListings() public view returns(Listing[] memory){
        return userListings[msg.sender];
    }

}


