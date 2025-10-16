// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    struct Event {
        uint128 nextTicketToSell;
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
    }

    address public owner;
    ITicketNFT public nftContract;
    address public ERC20Address;
    uint128 public currentEventId;
    
    mapping(uint128 => Event) public events;

    constructor(address _ERC20Address) {
        console.log("=== CONSTRUCTOR: Deploying TicketMarketplace ===");
        console.log("Owner address:", msg.sender);
        console.log("ERC20 address:", _ERC20Address);
        
        owner = msg.sender;
        ERC20Address = _ERC20Address;
        currentEventId = 0;
        
        // Deploy the NFT contract
        console.log("Deploying TicketNFT contract...");
        nftContract = new TicketNFT();
        console.log("TicketNFT deployed at:", address(nftContract));
        console.log("=== CONSTRUCTOR COMPLETE ===\n");
    }

    modifier onlyOwner() {
        console.log("--- onlyOwner check ---");
        console.log("msg.sender:", msg.sender);
        console.log("owner:", owner);
        require(msg.sender == owner, "Unauthorized access");
        console.log("Authorization passed!");
        _;
    }

    function createEvent(
        uint128 maxTickets, 
        uint256 pricePerTicket, 
        uint256 pricePerTicketERC20
    ) external onlyOwner {
        console.log("\n=== CREATE EVENT ===");
        console.log("Event ID:", currentEventId);
        console.log("Max tickets:", maxTickets);
        console.log("Price per ticket (ETH):", pricePerTicket);
        console.log("Price per ticket (ERC20):", pricePerTicketERC20);
        
        events[currentEventId] = Event({
            nextTicketToSell: 0,
            maxTickets: maxTickets,
            pricePerTicket: pricePerTicket,
            pricePerTicketERC20: pricePerTicketERC20
        });
        
        console.log("Event created successfully!");
        emit EventCreated(currentEventId, maxTickets, pricePerTicket, pricePerTicketERC20);
        
        currentEventId++;
        console.log("Next event ID will be:", currentEventId);
        console.log("=== CREATE EVENT COMPLETE ===\n");
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external onlyOwner {
        console.log("\n=== SET MAX TICKETS ===");
        console.log("Event ID:", eventId);
        console.log("Current max tickets:", events[eventId].maxTickets);
        console.log("New max tickets:", newMaxTickets);
        
        require(newMaxTickets >= events[eventId].maxTickets, 
            "The new number of max tickets is too small!");
        
        events[eventId].maxTickets = newMaxTickets;
        console.log("Max tickets updated successfully!");
        emit MaxTicketsUpdate(eventId, newMaxTickets);
        console.log("=== SET MAX TICKETS COMPLETE ===\n");
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external onlyOwner {
        console.log("\n=== SET ETH PRICE ===");
        console.log("Event ID:", eventId);
        console.log("Old price:", events[eventId].pricePerTicket);
        console.log("New price:", price);
        
        events[eventId].pricePerTicket = price;
        console.log("ETH price updated successfully!");
        emit PriceUpdate(eventId, price, "ETH");
        console.log("=== SET ETH PRICE COMPLETE ===\n");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external onlyOwner {
        console.log("\n=== SET ERC20 PRICE ===");
        console.log("Event ID:", eventId);
        console.log("Old price:", events[eventId].pricePerTicketERC20);
        console.log("New price:", price);
        
        events[eventId].pricePerTicketERC20 = price;
        console.log("ERC20 price updated successfully!");
        emit PriceUpdate(eventId, price, "ERC20");
        console.log("=== SET ERC20 PRICE COMPLETE ===\n");
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external {
        console.log("\n=== BUY TICKETS (ETH) ===");
        console.log("Buyer:", msg.sender);
        console.log("Event ID:", eventId);
        console.log("Ticket count:", ticketCount);
        console.log("ETH sent:", msg.value);
        
        Event storage eventInfo = events[eventId];
        console.log("Current nextTicketToSell:", eventInfo.nextTicketToSell);
        console.log("Max tickets:", eventInfo.maxTickets);
        console.log("Price per ticket:", eventInfo.pricePerTicket);

        // Calculate total price with overflow check FIRST
        console.log("\n--- Checking for overflow ---");
        (bool success, uint256 totalPrice) = Math.tryMul(eventInfo.pricePerTicket, ticketCount);
        console.log("Overflow check success:", success);
        if (success) {
            console.log("Total price calculated:", totalPrice);
        }
        require(success, 
            "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        
        // Check if enough tickets available
        console.log("\n--- Checking ticket availability ---");
        uint128 ticketsAfterPurchase = eventInfo.nextTicketToSell + ticketCount;
        console.log("Tickets after purchase would be:", ticketsAfterPurchase);
        console.log("Max allowed:", eventInfo.maxTickets);
        require(eventInfo.nextTicketToSell + ticketCount <= eventInfo.maxTickets,
            "We don't have that many tickets left to sell!");
        console.log("Enough tickets available!");
        
        // Check if enough ETH sent
        console.log("\n--- Checking payment ---");
        console.log("Required:", totalPrice);
        console.log("Sent:", msg.value);
        require(msg.value >= totalPrice,
            "Not enough funds supplied to buy the specified number of tickets.");
        console.log("Payment sufficient!");
        
        // Mint NFTs
        console.log("\n--- Minting NFTs ---");
        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 nftId = _encodeNftId(eventId, eventInfo.nextTicketToSell + i);
            console.log("Minting NFT #", i, "with ID:", nftId);
            nftContract.mintFromMarketPlace(msg.sender, nftId);
        }
        console.log("All NFTs minted successfully!");
        
        eventInfo.nextTicketToSell += ticketCount;
        console.log("Updated nextTicketToSell:", eventInfo.nextTicketToSell);
        
        emit TicketsBought(eventId, ticketCount, "ETH");
        console.log("=== BUY TICKETS (ETH) COMPLETE ===\n");
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external {
        console.log("\n=== BUY TICKETS (ERC20) ===");
        console.log("Buyer:", msg.sender);
        console.log("Event ID:", eventId);
        console.log("Ticket count:", ticketCount);
        
        Event storage eventInfo = events[eventId];
        console.log("Current nextTicketToSell:", eventInfo.nextTicketToSell);
        console.log("Max tickets:", eventInfo.maxTickets);
        console.log("Price per ticket (ERC20):", eventInfo.pricePerTicketERC20);
        
        // Calculate total price with overflow check FIRST
        console.log("\n--- Checking for overflow ---");
        (bool success, uint256 totalPrice) = Math.tryMul(eventInfo.pricePerTicketERC20, ticketCount);
        console.log("Overflow check success:", success);
        if (success) {
            console.log("Total price calculated:", totalPrice);
        }
        require(success, 
            "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        
        // Check if enough tickets available
        console.log("\n--- Checking ticket availability ---");
        uint128 ticketsAfterPurchase = eventInfo.nextTicketToSell + ticketCount;
        console.log("Tickets after purchase would be:", ticketsAfterPurchase);
        console.log("Max allowed:", eventInfo.maxTickets);
        require(eventInfo.nextTicketToSell + ticketCount <= eventInfo.maxTickets,
            "We don't have that many tickets left to sell!");
        console.log("Enough tickets available!");
        
        // Transfer ERC20 tokens
        console.log("\n--- Transferring ERC20 tokens ---");
        console.log("ERC20 contract:", ERC20Address);
        console.log("Amount to transfer:", totalPrice);
        IERC20 token = IERC20(ERC20Address);
        require(token.transferFrom(msg.sender, address(this), totalPrice),
            "ERC20 transfer failed");
        console.log("ERC20 tokens transferred successfully!");
        
        // Mint NFTs
        console.log("\n--- Minting NFTs ---");
        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 nftId = _encodeNftId(eventId, eventInfo.nextTicketToSell + i);
            console.log("Minting NFT #", i, "with ID:", nftId);
            nftContract.mintFromMarketPlace(msg.sender, nftId);
        }
        console.log("All NFTs minted successfully!");
        
        eventInfo.nextTicketToSell += ticketCount;
        console.log("Updated nextTicketToSell:", eventInfo.nextTicketToSell);
        
        emit TicketsBought(eventId, ticketCount, "ERC20");
        console.log("=== BUY TICKETS (ERC20) COMPLETE ===\n");
    }

    function setERC20Address(address newERC20Address) external onlyOwner {
        console.log("\n=== SET ERC20 ADDRESS ===");
        console.log("Old address:", ERC20Address);
        console.log("New address:", newERC20Address);
        
        ERC20Address = newERC20Address;
        console.log("ERC20 address updated successfully!");
        emit ERC20AddressUpdate(newERC20Address);
        console.log("=== SET ERC20 ADDRESS COMPLETE ===\n");
    }

    // Helper function to encode NFT ID as (eventId << 128) + seatNumber
    function _encodeNftId(uint128 eventId, uint128 seatNumber) private pure returns (uint256) {
        console.log("--- Encoding NFT ID ---");
        console.log("Event ID:", eventId);
        console.log("Seat number:", seatNumber);
        uint256 encodedId = (uint256(eventId) << 128) | uint256(seatNumber);
        console.log("Encoded NFT ID:", encodedId);
        return encodedId;
    }
}