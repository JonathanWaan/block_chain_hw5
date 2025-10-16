# CSC2125 – Solidity Assignment: Ticket Marketplace

This repository is for the University of Toronto CSC2125 (Fall 2025) assignment.  
You will implement a Ticket Marketplace smart contract using Solidity and Hardhat.



## 🧩 Overview

Create a decentralized ticket marketplace that:

- Allows users to buy tickets using Ether or an ERC-20 token
- Represents tickets as ERC-1155 NFTs, encoded as `(eventId, seatNumber)`
- Lets only the contract owner update prices, limits, or token addresses
- Emits an event after every state-changing action

All logic must pass the provided Hardhat test suite.  
Do not modify any test files.



## ⚙️ Setup

1. Install [Node.js](https://nodejs.org/en/download)
2. In the project directory, run:

   ```bash
   npm install
   npx hardhat compile
   npx hardhat test
   ```

## 📁 Project Structure

```
- contracts/ # Solidity contracts
- test/      # Provided test suite (do NOT edit)
- scripts/   # Deployment scripts
- hardhat.config.ts
- package.json
- README.md
```

## 💡 Tips

- Read and understand the tests — they define expected behavior  
- Use `console.log` in Solidity for debugging (`hardhat console`)  
- Docs:  
  - [Solidity](https://docs.soliditylang.org/)  
  - [Hardhat](https://hardhat.org/docs/)  
  - [OpenZeppelin](https://docs.openzeppelin.com/contracts)
