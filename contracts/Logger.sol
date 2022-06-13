// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";

/**
 * @title Furio Logger
 * @author Steve Harmeyer
 * @notice This contract collects all the logs.
 */

/// @custom:security-contact security@furio.io
contract Logger is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    /**
     * Message struct.
     */
    struct Message {
        address source;
        string message;
        uint256 timestamp;
    }

    /**
     * Log event.
     * @param message_ Log message.
     */
    event LogEvent(Message message_);

    /**
     * Log.
     * @param message_ Message to log.
     * @dev Emits LogEvent
     */
    function log(string memory message_) external
    {
        Message memory _message_;
        _message_.source = msg.sender;
        _message_.message = message_;
        _message_.timestamp = block.timestamp;
        emit LogEvent(_message_);
    }
}
