// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice The Whitelist Access Control module
 *
 * This is a simple abstract contract that implements whitelisting logic.
 *
 * The contract is based on a Merkle tree, which allows for the huge whitelists to be cheaply validated courtesy of
 * O(log(n)) tree complexity. The whitelist itself is stored in the tree leaves and only the root of the tree is saved on-chain.
 *
 * To validate the whitelist belonging, the tree leaf (the whitelist element) has to be computed and passed to the
 * "root-construction" function together with the corresponding tree branches. The function will then check the
 * roots equality. If the roots match, the element belongs to the whitelist.
 *
 * Note: the branch nodes are sorted numerically.
 */
abstract contract AMerkleWhitelisted {
    using MerkleProof for bytes32[];

    struct AMerkleWhitelistedStorage {
        bytes32 merkleRoot;
    }

    // bytes32(uint256(keccak256("solarity.contract.AMerkleWhitelisted")) - 1)
    bytes32 private constant A_MERKLE_WHITELISTED_STORAGE =
        0x655e174042e5ffc37fc1cb8b514e651c61ae9bb4dd4f6ce06d8f229ee9767b24;

    error LeafNotWhitelisted(bytes data);
    error UserNotWhitelisted(address user);

    modifier onlyWhitelisted(bytes memory data_, bytes32[] memory merkleProof_) {
        if (!_isWhitelisted(keccak256(data_), merkleProof_)) revert LeafNotWhitelisted(data_);
        _;
    }

    modifier onlyWhitelistedUser(address user_, bytes32[] memory merkleProof_) {
        if (!_isWhitelistedUser(user_, merkleProof_)) revert UserNotWhitelisted(user_);
        _;
    }

    /**
     * @notice The function to get the current Merkle root
     * @return the current Merkle root or zero bytes if it has not been set
     */
    function getMerkleRoot() public view returns (bytes32) {
        AMerkleWhitelistedStorage storage $ = _getAMerkleWhitelistedStorage();

        return $.merkleRoot;
    }

    /**
     * @notice The function to check if the leaf belongs to the Merkle tree
     * @param leaf_ the leaf to be checked
     * @param merkleProof_ the path from the leaf to the Merkle tree root
     * @return true if the leaf belongs to the Merkle tree, false otherwise
     */
    function _isWhitelisted(
        bytes32 leaf_,
        bytes32[] memory merkleProof_
    ) internal view returns (bool) {
        AMerkleWhitelistedStorage storage $ = _getAMerkleWhitelistedStorage();

        return merkleProof_.verify($.merkleRoot, leaf_);
    }

    /**
     * @notice The function to check if the user belongs to the Merkle tree
     * @param user_ the user to be checked
     * @param merkleProof_ the path from the user to the Merkle tree root
     * @return true if the user belongs to the Merkle tree, false otherwise
     */
    function _isWhitelistedUser(
        address user_,
        bytes32[] memory merkleProof_
    ) internal view returns (bool) {
        return _isWhitelisted(keccak256(abi.encodePacked(user_)), merkleProof_);
    }

    /**
     * @notice The function that should be called from the child contract to set the Merkle root
     * @param merkleRoot_ the Merkle root to be set
     */
    function _setMerkleRoot(bytes32 merkleRoot_) internal {
        AMerkleWhitelistedStorage storage $ = _getAMerkleWhitelistedStorage();

        $.merkleRoot = merkleRoot_;
    }

    /**
     * @dev Returns a pointer to the storage namespace
     */
    function _getAMerkleWhitelistedStorage()
        private
        pure
        returns (AMerkleWhitelistedStorage storage $)
    {
        assembly {
            $.slot := A_MERKLE_WHITELISTED_STORAGE
        }
    }
}
