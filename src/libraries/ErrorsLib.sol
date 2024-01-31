// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title ErrorsLib
/// @author Morpho Labs
/// @custom:contact security@morpho.org
/// @notice Library exposing error messages.
library ErrorsLib {
    /// @notice Thrown when the start timestamp of the rewards emission is set in the past.
    string internal constant START_TIMESTAMP_OUTDATED = "start timestamp outdated";

    /// @notice Thrown when the end timestamp of the rewards emission is set earlier than the start timestamp.
    string internal constant END_TIMESTAMP_INVALID = "end timestamp invalid";

    /// @notice Thrown when the rewards emission is already set.
    string internal constant REWARDS_EMISSION_ALREADY_SET = "rewards emission already set";
}
