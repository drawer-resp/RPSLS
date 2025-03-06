// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";
import "./Convert.sol";

contract RPSLS is TimeUnit {
    CommitReveal public commitReveal;
    
    enum GameState { Inactive, CommitPhase, RevealPhase }
    GameState public gameState;
    
    struct Game {
        address[2] players;
        bytes32[2] commits;
        uint256[2] choices;
        uint256 stake;
        uint256 commitDeadline;
        uint256 revealDeadline;
        bool[2] revealed;
    }
    
    Game public currentGame;
    mapping(address => bool) public allowedPlayers;
    
    event GameStarted(address indexed player);
    event Committed(address indexed player);
    event Revealed(address indexed player);
    event Winner(address indexed winner);
    event Timeout(address indexed caller);

    constructor(address _commitReveal) {
        commitReveal = CommitReveal(_commitReveal);
        allowedPlayers[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true;
        allowedPlayers[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2] = true;
        allowedPlayers[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db] = true;
        allowedPlayers[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB] = true;
    }

    modifier onlyAllowed() {
        require(allowedPlayers[msg.sender], "Address not allowed");
        _;
    }

    function joinGame(bytes32 commitHash) external payable onlyAllowed {
        require(msg.value == 1 ether, "Stake must be 1 ETH");
        require(currentGame.players[0] == address(0) || 
               currentGame.players[1] == address(0), "Game full");
        
        if(currentGame.players[0] == address(0)) {
            currentGame.players[0] = msg.sender;
            currentGame.commits[0] = commitHash;
            currentGame.stake = msg.value;
            currentGame.commitDeadline = block.timestamp + 5 minutes;
            gameState = GameState.CommitPhase;
            emit GameStarted(msg.sender);
        } else {
            currentGame.players[1] = msg.sender;
            currentGame.commits[1] = commitHash;
            currentGame.revealDeadline = block.timestamp + 5 minutes;
            gameState = GameState.RevealPhase;
        }
        emit Committed(msg.sender);
    }

    function revealChoice(uint256 choice, bytes32 nonce) external {
        require(gameState == GameState.RevealPhase, "Not in reveal phase");
        require(choice < 5, "Invalid choice");
        
        uint256 playerIndex = currentGame.players[0] == msg.sender ? 0 : 1;
        require(!currentGame.revealed[playerIndex], "Already revealed");
        
        bytes32 computedHash = Convert.getHash(choice, nonce);
        require(computedHash == currentGame.commits[playerIndex], "Invalid reveal");
        
        currentGame.choices[playerIndex] = choice;
        currentGame.revealed[playerIndex] = true;
        
        if(currentGame.revealed[0] && currentGame.revealed[1]) {
            _determineWinner();
        }
        emit Revealed(msg.sender);
    }

    function _determineWinner() private {
        uint256 p0Choice = currentGame.choices[0];
        uint256 p1Choice = currentGame.choices[1];
        address payable[2] memory players = [
            payable(currentGame.players[0]),
            payable(currentGame.players[1])
        ];

        uint256 result = (p0Choice - p1Choice + 5) % 5;
        if(result == 1 || result == 3) {
            players[0].transfer(address(this).balance);
            emit Winner(players[0]);
        } else if(result == 2 || result == 4) {
            players[1].transfer(address(this).balance);
            emit Winner(players[1]);
        } else {
            players[0].transfer(currentGame.stake);
            players[1].transfer(currentGame.stake);
        }
        _resetGame();
    }

    function withdrawTimeout() external {
        require(block.timestamp > currentGame.commitDeadline || 
               block.timestamp > currentGame.revealDeadline, "Too early");
        
        if(gameState == GameState.CommitPhase) {
            payable(currentGame.players[0]).transfer(currentGame.stake);
        } else {
            if(currentGame.revealed[0] && !currentGame.revealed[1]) {
                payable(currentGame.players[0]).transfer(address(this).balance);
            } else if(currentGame.revealed[1] && !currentGame.revealed[0]) {
                payable(currentGame.players[1]).transfer(address(this).balance);
            } else {
                payable(currentGame.players[0]).transfer(currentGame.stake);
                payable(currentGame.players[1]).transfer(currentGame.stake);
            }
        }
        emit Timeout(msg.sender);
        _resetGame();
    }

    function _resetGame() private {
        delete currentGame;
        gameState = GameState.Inactive;
    }
}