// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ISellVault {

    function payout(address user, uint256 netAmount, address feeRecipient, uint256 feeAmount) external;


    function getBalance() external view returns (uint256);


    function needsRefill() external view returns (bool);
}
