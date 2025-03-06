# Rock-Paper-Scissors-Lizard-Spock (RPSLS) Game

[![Solidity Version](https://img.shields.io/badge/Solidity-^0.8.0-blue)](https://soliditylang.org)

A secure, decentralized implementation of the RPSLS game (from *The Big Bang Theory*) on Ethereum blockchain, featuring commit-reveal pattern and timeout protection.

## Features
✅ RPSLS game rules (5 choices)  
✅ Commit-reveal pattern for front-running prevention  
✅ Whitelisted players (4 allowed addresses)  
✅ Timeout-based fund recovery  
✅ 1 ETH stake per player  
✅ Automatic winner determination  

## Game Rules
Choices: 0 = Rock, 1 = Paper, 2 = Scissors, 3 = Lizard, 4 = Spock  

Winning combinations:  
- Scissors cuts Paper  
- Paper covers Rock  
- Rock crushes Lizard  
- Lizard poisons Spock  
- Spock smashes Scissors  
- Scissors decapitates Lizard  
- Lizard eats Paper  
- Paper disproves Spock  
- Spock vaporizes Rock  
- Rock crushes Scissors  

## Contract Structure
contracts/
├── RPSLS.sol # Main game logic
├── CommitReveal.sol # Commit-reveal pattern
├── TimeUnit.sol # Timeout management
└── Convert.sol # Hash generation library


## Key Mechanisms

### 💸 Fund Lock Prevention
- **Timeouts**: 
  - Commit phase: 5 minutes 
  - Reveal phase: 5 minutes
- Automatic refunds if:
  - Player doesn't commit within timeframe
  - Player doesn't reveal after commit
- Withdrawal function (`withdrawTimeout`) for stuck games

### 🔒 Commit-Reveal Process
1. Player generates hash: `keccak256(choice + nonce)`
2. Submit hash via `joinGame()`
3. After both commit, reveal actual choice with `revealChoice()`
4. Contract verifies hash matches commit

### ⏳ Timeout Handling
```solidity
function withdrawTimeout() external {
    require(block.timestamp > deadlines, "Too early");
    // Automatically refunds based on game state
}