// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OMPToken is ERC20, Ownable {



    address public controller;



    event ControllerUpdated(address indexed oldController, address indexed newController);
    event Minted(address indexed to, uint256 amount, address indexed controller);
    event Burned(address indexed from, uint256 amount, address indexed controller);



    error OnlyController();
    error ZeroAddress();
    error ZeroAmount();




    modifier onlyController() {
        if (msg.sender != controller) revert OnlyController();
        _;
    }




    constructor() ERC20("One Metric Protocol", "OMP") Ownable(msg.sender) {

        controller = address(0);
    }




    function setController(address newController) external onlyOwner {
        if (newController == address(0)) revert ZeroAddress();

        address oldController = controller;
        controller = newController;

        emit ControllerUpdated(oldController, newController);
    }




    function mint(address to, uint256 amount) external onlyController {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        _mint(to, amount);

        emit Minted(to, amount, msg.sender);
    }


    function burn(address from, uint256 amount) external onlyController {
        if (from == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        _burn(from, amount);

        emit Burned(from, amount, msg.sender);
    }




    function isController(address account) external view returns (bool) {
        return account == controller;
    }
}
