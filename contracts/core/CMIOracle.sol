// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IOracle.sol";

contract CMIOracle is IOracle, Ownable {

    uint256 public constant MAX_AGE = 900;


    uint256 public constant MAX_DEVIATION_BPS = 50;


    uint256 public constant MIN_CMI = 0.01e18;


    uint256 public constant MAX_CMI = 10_000_000e18;

    uint256 public latestCMI;


    uint256 public deviationBps;


    uint256 public lastUpdate;


    address public publisher;


    constructor(uint256 initialCMI) Ownable(msg.sender) {
        require(initialCMI >= MIN_CMI && initialCMI <= MAX_CMI, "CMIOracle: invalid initial CMI");

        latestCMI = initialCMI;
        deviationBps = 0;
        lastUpdate = block.timestamp;
        publisher = msg.sender;

        emit CMIUpdated(initialCMI, 0, block.timestamp, msg.sender);
    }


    function updateCMI(uint256 cmi1e18, uint256 _deviationBps) external {
        require(msg.sender == publisher, "CMIOracle: unauthorized");
        require(cmi1e18 >= MIN_CMI, "CMIOracle: CMI too low");
        require(cmi1e18 <= MAX_CMI, "CMIOracle: CMI too high");
        require(_deviationBps <= 10000, "CMIOracle: invalid deviation");

        latestCMI = cmi1e18;
        deviationBps = _deviationBps;
        lastUpdate = block.timestamp;

        emit CMIUpdated(cmi1e18, _deviationBps, block.timestamp, msg.sender);
    }


    function setPublisher(address newPublisher) external onlyOwner {
        require(newPublisher != address(0), "CMIOracle: zero address");
        address oldPublisher = publisher;
        publisher = newPublisher;
        emit PublisherUpdated(oldPublisher, newPublisher);
    }


    function getLatestCMI() external view returns (uint256 cmi, uint256 _deviationBps, uint256 _lastUpdate) {
        return (latestCMI, deviationBps, lastUpdate);
    }


    function isFresh() external view returns (bool) {
        return (block.timestamp - lastUpdate) <= MAX_AGE;
    }


    function isDeviationOk() external view returns (bool) {
        return deviationBps < MAX_DEVIATION_BPS;
    }


    function getStatus() external view returns (
        uint256 cmi,
        uint256 deviation,
        uint256 updated,
        bool fresh,
        bool deviationOk,
        address currentPublisher
    ) {
        return (
            latestCMI,
            deviationBps,
            lastUpdate,
            (block.timestamp - lastUpdate) <= MAX_AGE,
            deviationBps < MAX_DEVIATION_BPS,
            publisher
        );
    }
}
