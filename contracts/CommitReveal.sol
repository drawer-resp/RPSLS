// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract CommitReveal {
    struct Commit {
        bytes32 commitHash;
        bool revealed;
    }

    mapping(address => Commit) public commits;

    function commit(bytes32 hashedChoice) external {
        commits[msg.sender].commitHash = hashedChoice;
        commits[msg.sender].revealed = false;
    }

    function reveal(uint256 choice, bytes32 nonce) external {
        require(!commits[msg.sender].revealed, "Already revealed");
        require(
            keccak256(abi.encodePacked(choice, nonce)) == commits[msg.sender].commitHash,
            "Invalid reveal"
        );
        commits[msg.sender].revealed = true;
    }
}