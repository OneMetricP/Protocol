// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IOracle {

    event CMIUpdated(
        uint256 indexed newCMI,
        uint256 deviationBps,
        uint256 timestamp,
        address indexed publisher
    );


    event PublisherUpdated(address indexed oldPublisher, address indexed newPublisher);


    function updateCMI(uint256 cmi1e18, uint256 deviationBps) external;


    function getLatestCMI() external view returns (uint256 cmi, uint256 deviationBps, uint256 lastUpdate);


    function isFresh() external view returns (bool);


    function isDeviationOk() external view returns (bool);
}
