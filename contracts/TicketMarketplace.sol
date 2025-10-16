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
        owner = msg.sender;
        ERC20Address = _ERC20Address;
        currentEventId = 0;
        
        // Deploy the NFT contract
        nftContract = new TicketNFT();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access");
        _;
    }

    function createEvent(
        uint128 maxTickets, 
        uint256 pricePerTicket, 
        uint256 pricePerTicketERC20
    ) external onlyOwner {
        events[currentEventId] = Event({
            nextTicketToSell: 0,
            maxTickets: maxTickets,
            pricePerTicket: pricePerTicket,
            pricePerTicketERC20: pricePerTicketERC20
        });
        
        emit EventCreated(currentEventId, maxTickets, pricePerTicket, pricePerTicketERC20);
        currentEventId++;
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external onlyOwner {
        require(newMaxTickets >= events[eventId].maxTickets, 
            "The new number of max tickets is too small!");
        
        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external onlyOwner {
        events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external onlyOwner {
        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external {
        Event storage eventInfo = events[eventId];
        
        // Check if enough tickets available
        require(eventInfo.nextTicketToSell + ticketCount <= eventInfo.maxTickets,
            "We don't have that many tickets left to sell!");
        
        // Calculate total price with overflow check
        (bool success, uint256 totalPrice) = Math.tryMul(eventInfo.pricePerTicket, ticketCount);
        require(success, 
            "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        
        // Check if enough ETH sent
        require(msg.value >= totalPrice,
            "Not enough funds supplied to buy the specified number of tickets.");
        
        // Mint NFTs
        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 nftId = _encodeNftId(eventId, eventInfo.nextTicketToSell + i);
            nftContract.mintFromMarketPlace(msg.sender, nftId);
        }
        
        eventInfo.nextTicketToSell += ticketCount;
        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external {
        Event storage eventInfo = events[eventId];
        
        // Check if enough tickets available
        require(eventInfo.nextTicketToSell + ticketCount <= eventInfo.maxTickets,
            "We don't have that many tickets left to sell!");
        
        // Calculate total price with overflow check
        (bool success, uint256 totalPrice) = Math.tryMul(eventInfo.pricePerTicketERC20, ticketCount);
        require(success, 
            "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        
        // Transfer ERC20 tokens
        IERC20 token = IERC20(ERC20Address);
        require(token.transferFrom(msg.sender, address(this), totalPrice),
            "ERC20 transfer failed");
        
        // Mint NFTs
        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 nftId = _encodeNftId(eventId, eventInfo.nextTicketToSell + i);
            nftContract.mintFromMarketPlace(msg.sender, nftId);
        }
        
        eventInfo.nextTicketToSell += ticketCount;
        emit TicketsBought(eventId, ticketCount, "ERC20");
    }

    function setERC20Address(address newERC20Address) external onlyOwner {
        ERC20Address = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }

    // Helper function to encode NFT ID as (eventId << 128) + seatNumber
    function _encodeNftId(uint128 eventId, uint128 seatNumber) private pure returns (uint256) {
        return (uint256(eventId) << 128) | uint256(seatNumber);
    }
}