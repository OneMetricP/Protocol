// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PoRRegistry is Ownable {

    event PoRAnchored(
        uint256 indexed timestamp,
        bytes32 indexed reportHash,
        address indexed publisher,
        uint256 porRatio
    );

    event PublisherUpdated(
        address indexed oldPublisher,
        address indexed newPublisher
    );

    address public publisher;

    mapping(uint256 => bytes32) public snapshots;

    mapping(uint256 => uint256) public ratios;

    uint256 public totalAnchors;

    uint256 public latestTimestamp;

    constructor(address _publisher) Ownable(msg.sender) {
        require(_publisher != address(0), "Invalid publisher");
        publisher = _publisher;
        emit PublisherUpdated(address(0), _publisher);
    }

    function anchor(bytes32 reportHash, uint256 porRatio) external {
        require(msg.sender == publisher, "Not authorized");
        require(reportHash != bytes32(0), "Invalid hash");
        require(porRatio > 0, "Invalid ratio");

        uint256 timestamp = block.timestamp;

        snapshots[timestamp] = reportHash;
        ratios[timestamp] = porRatio;
        totalAnchors++;
        latestTimestamp = timestamp;

        emit PoRAnchored(timestamp, reportHash, msg.sender, porRatio);
    }

    function setPublisher(address _publisher) external onlyOwner {
        require(_publisher != address(0), "Invalid publisher");
        address oldPublisher = publisher;
        publisher = _publisher;
        emit PublisherUpdated(oldPublisher, _publisher);
    }

    function getSnapshot(uint256 timestamp) external view returns (bytes32) {
        return snapshots[timestamp];
    }

    function getRatio(uint256 timestamp) external view returns (uint256) {
        return ratios[timestamp];
    }

    function getLatest() external view returns (
        uint256 timestamp,
        bytes32 reportHash,
        uint256 porRatio
    ) {
        timestamp = latestTimestamp;
        reportHash = snapshots[timestamp];
        porRatio = ratios[timestamp];
    }

    function verify(uint256 timestamp, bytes32 reportHash) external view returns (bool) {
        return snapshots[timestamp] == reportHash && reportHash != bytes32(0);
    }
}
