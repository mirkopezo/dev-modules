// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @notice This library is used to simplify the interaction with autogenerated contracts
 * that use [hardhat-zkit](https://github.com/dl-solarity/hardhat-zkit) to verify Plonk ZK proofs.
 *
 * The main problem with the ZK verifier contracts is that the verification function always has the same signature, except for one parameter.
 * The `input` parameter is a static array `uint256`, the size of which depends on the number of public outputs of ZK proof,
 * therefore the signatures of the verification functions may be different for different schemes.
 *
 * With this library there is no need to create many different interfaces for each circuit.
 * Moreover, the library functions accept dynamic arrays of public signals, so you don't need to convert them manually to static ones.
 */
library PlonkVerifierHelper {
    using Strings for uint256;

    /**
     * @notice Structure representing a Plonk proof.
     * @param proofPoints The proof data points
     * @param publicSignals The public signals associated with the proof
     */
    struct PlonkProof {
        ProofPoints proofPoints;
        uint256[] publicSignals;
    }

    /**
     * @notice Structure holding the proof data points.
     * @param proofData The array of proof-related data
     */
    struct ProofPoints {
        uint256[24] proofData;
    }

    error InvalidPublicSignalsCount(uint256 arrayLength, uint256 pubSignalsCount);
    error FailedToCallVerifyProof();

    /**
     * @notice Function to call the `verifyProof` function on the `verifier` contract.
     * The Plonk ZK proof is wrapped in a structure for convenience
     * @param verifier_ The address of the verifier contract
     * @param plonkProof_ The Plonk proof to be verified
     * @return true if the proof is valid, false - otherwise
     */
    function verifyProof(
        address verifier_,
        PlonkProof memory plonkProof_
    ) internal view returns (bool) {
        return
            _verifyProof(
                verifier_,
                plonkProof_.proofPoints.proofData,
                plonkProof_.publicSignals,
                plonkProof_.publicSignals.length
            );
    }

    /**
     * @notice Function to call the `verifyProof` function on the `verifier` contract.
     * The Plonk ZK proof points are wrapped in a structure for convenience
     * @param verifier_ the address of the autogenerated `Verifier` contract
     * @param proofPoints_ the ProofPoints struct with Plonk ZK proof points
     * @param pubSignals_ the array of the Plonk ZK proof public signals
     * @return true if the proof is valid, false - otherwise
     */
    function verifyProof(
        address verifier_,
        ProofPoints memory proofPoints_,
        uint256[] memory pubSignals_
    ) internal view returns (bool) {
        return _verifyProof(verifier_, proofPoints_.proofData, pubSignals_, pubSignals_.length);
    }

    /**
     * @notice Function to call the `verifyProof` function on the `verifier` contract
     * @param verifier_ the address of the autogenerated `Verifier` contract
     * @param proofData_ the Plonk proof data
     * @param pubSignals_ the array of the Plonk ZK proof public signals
     * @return true if the proof is valid, false - otherwise
     */
    function verifyProof(
        address verifier_,
        uint256[24] memory proofData_,
        uint256[] memory pubSignals_
    ) internal view returns (bool) {
        return _verifyProof(verifier_, proofData_, pubSignals_, pubSignals_.length);
    }

    /**
     * @notice Function to call the `verifyProof` function on the `verifier` contract.
     * The Plonk ZK proof is wrapped in a structure for convenience.
     * The length of the `plonkProof_.publicSignals` arr must be strictly equal to `pubSignalsCount_`
     * @param verifier_ The address of the verifier contract
     * @param plonkProof_ The Plonk proof to be verified
     * @param pubSignalsCount_ The expected number of public signals
     * @return true if the proof is valid, false - otherwise
     */
    function verifyProofSafe(
        address verifier_,
        PlonkProof memory plonkProof_,
        uint256 pubSignalsCount_
    ) internal view returns (bool) {
        return
            _verifyProofSafe(
                verifier_,
                plonkProof_.proofPoints.proofData,
                plonkProof_.publicSignals,
                pubSignalsCount_
            );
    }

    /**
     * @notice Function to call the `verifyProof` function on the `verifier` contract.
     * The Plonk proof data are wrapped in a structure for code consistency
     * The length of the `pubSignals_` arr must be strictly equal to `pubSignalsCount_`
     * @param verifier_ the address of the autogenerated `Verifier` contract
     * @param proofPoints_ the ProofPoints struct with the Plonk proof data
     * @param pubSignals_ the array of the Plonk ZK proof public signals
     * @param pubSignalsCount_ the number of public signals
     * @return true if the proof is valid, false - otherwise
     */
    function verifyProofSafe(
        address verifier_,
        ProofPoints memory proofPoints_,
        uint256[] memory pubSignals_,
        uint256 pubSignalsCount_
    ) internal view returns (bool) {
        return _verifyProofSafe(verifier_, proofPoints_.proofData, pubSignals_, pubSignalsCount_);
    }

    /**
     * @notice Function to call the `verifyProof` function on the `verifier` contract
     * The length of the `pubSignals_` arr must be strictly equal to `pubSignalsCount_`
     * @param verifier_ the address of the autogenerated `Verifier` contract
     * @param proofData_ the Plonk proof data
     * @param pubSignals_ the array of the Plonk ZK proof public signals
     * @param pubSignalsCount_ the number of public signals
     * @return true if the proof is valid, false - otherwise
     */
    function verifyProofSafe(
        address verifier_,
        uint256[24] memory proofData_,
        uint256[] memory pubSignals_,
        uint256 pubSignalsCount_
    ) internal view returns (bool) {
        return _verifyProofSafe(verifier_, proofData_, pubSignals_, pubSignalsCount_);
    }

    function _verifyProofSafe(
        address verifier_,
        uint256[24] memory proofData_,
        uint256[] memory pubSignals_,
        uint256 pubSignalsCount_
    ) private view returns (bool) {
        _checkPublicSignalsLength(pubSignals_, pubSignalsCount_);

        return _verifyProof(verifier_, proofData_, pubSignals_, pubSignalsCount_);
    }

    function _verifyProof(
        address verifier_,
        uint256[24] memory proofData_,
        uint256[] memory pubSignals_,
        uint256 pubSignalsCount_
    ) private view returns (bool) {
        string memory funcSign_ = string(
            abi.encodePacked("verifyProof(uint256[24],uint256[", pubSignalsCount_.toString(), "])")
        );

        /// @dev We have to use abi.encodePacked to encode a dynamic array as a static array (without offset and length)
        (bool success_, bytes memory returnData_) = verifier_.staticcall(
            abi.encodePacked(abi.encodeWithSignature(funcSign_, proofData_), pubSignals_)
        );

        if (!success_) revert FailedToCallVerifyProof();

        return abi.decode(returnData_, (bool));
    }

    function _checkPublicSignalsLength(
        uint256[] memory pubSignals_,
        uint256 expectedPubSignalsCount_
    ) private pure {
        if (pubSignals_.length != expectedPubSignalsCount_)
            revert InvalidPublicSignalsCount(pubSignals_.length, expectedPubSignalsCount_);
    }
}
