// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

library Convert {
    function getHash(uint256 choice, bytes32 nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(choice, nonce));
    }
}