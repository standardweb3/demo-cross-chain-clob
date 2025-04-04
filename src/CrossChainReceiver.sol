// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/wormhole-solidity-sdk/src/WormholeRelayerSDK.sol";
import "lib/wormhole-solidity-sdk/src/interfaces/IERC20.sol";
import "@standardweb3/exchange/interfaces/IMatchingEngine.sol";

contract CrossChainReceiver is TokenReceiver {
    // The wormhole relayer and registeredSenders are inherited from the Base.sol contract.
    address public matchingEngine;

    constructor(address _wormholeRelayer, address _tokenBridge, address _wormhole, address _matchingEngine)
        TokenBase(_wormholeRelayer, _tokenBridge, _wormhole)
    {
        matchingEngine = _matchingEngine;
    }

    // Function to receive the cross-chain payload and tokens with emitter validation
    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 // deliveryHash (not used in this implementation)
    ) internal override onlyWormholeRelayer isRegisteredSender(sourceChain, sourceAddress) {
        require(receivedTokens.length == 1, "Expected 1 token transfer");

        // Decode the recipient address from the payload
        address recipient = abi.decode(payload, (address));

        // Transfer the received tokens to the intended recipient
        IERC20(receivedTokens[0].tokenAddress).transfer(recipient, receivedTokens[0].amount);
    }

    function receiveCrossChainOrder(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 // deliveryHash (not used in this implementation)
    ) internal override onlyWormholeRelayer isRegisteredSender(sourceChain, sourceAddress) {
        require(receivedTokens.length == 1, "Expected 1 token transfer");

        // call the matching engine to submit the order
        (bool success, bytes memory data) = matchingEngine.call(payload);
        require(success, "MatchingEngine call failed");
    }
}
