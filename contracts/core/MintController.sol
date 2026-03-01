// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/ISellVault.sol";
import "./OMPToken.sol";

interface IBuyVault {
    function deposit(uint256 amount) external;
}

contract MintController is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Deployed on BNB Smart Chain (Chain ID: 56)

    OMPToken public immutable ompToken;
    IOracle public immutable oracle;
    IERC20 public immutable usdt;

    address public buyVault;
    address public sellVault;
    address public treasury;

    uint256 public constant FEE_BPS = 50;
    uint256 public constant MIN_AMOUNT = 10e18;
    uint256 public constant MIN_REDEEM_OMP = 10e18;
    uint256 public constant MAX_MINT_PER_USER = 50_000e18;
    uint256 public constant BPS_DENOMINATOR = 10000;

    event MintExecuted(
        address indexed user,
        uint256 usdtCollateral,
        uint256 ompMinted,
        uint256 feeAmount,
        uint256 netToVault,
        uint256 cmiPrice,
        uint256 timestamp
    );

    event RedeemExecuted(
        address indexed user,
        uint256 ompBurned,
        uint256 usdtReturned,
        uint256 feeAmount,
        uint256 cmiPrice,
        uint256 timestamp
    );

    event BuyVaultUpdated(address indexed oldVault, address indexed newVault);
    event SellVaultUpdated(address indexed oldVault, address indexed newVault);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);

    error ZeroAddress();
    error ZeroAmount();
    error AmountTooLow(uint256 amount, uint256 minimum);
    error AmountTooHigh(uint256 amount, uint256 maximum);
    error OracleStale(uint256 age, uint256 maxAge);
    error OracleDeviationTooHigh(uint256 deviation, uint256 maxDeviation);
    error InsufficientCollateral(uint256 required, uint256 provided);
    error BuyVaultNotSet();
    error SellVaultNotSet();
    error TreasuryNotSet();

    constructor(
        address _ompToken,
        address _oracle,
        address _usdt,
        address _buyVault,
        address _sellVault,
        address _treasury
    ) Ownable(msg.sender) {
        if (_ompToken == address(0)) revert ZeroAddress();
        if (_oracle == address(0)) revert ZeroAddress();
        if (_usdt == address(0)) revert ZeroAddress();
        if (_buyVault == address(0)) revert ZeroAddress();
        if (_sellVault == address(0)) revert ZeroAddress();
        if (_treasury == address(0)) revert ZeroAddress();

        ompToken = OMPToken(_ompToken);
        oracle = IOracle(_oracle);
        usdt = IERC20(_usdt);
        buyVault = _buyVault;
        sellVault = _sellVault;
        treasury = _treasury;
    }

    function setBuyVault(address _buyVault) external onlyOwner {
        if (_buyVault == address(0)) revert ZeroAddress();
        address oldVault = buyVault;
        buyVault = _buyVault;
        emit BuyVaultUpdated(oldVault, _buyVault);
    }

    function setSellVault(address _sellVault) external onlyOwner {
        if (_sellVault == address(0)) revert ZeroAddress();
        address oldVault = sellVault;
        sellVault = _sellVault;
        emit SellVaultUpdated(oldVault, _sellVault);
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ZeroAddress();
        address oldTreasury = treasury;
        treasury = _treasury;
        emit TreasuryUpdated(oldTreasury, _treasury);
    }

    function mint(uint256 usdtAmount) external nonReentrant {
        if (usdtAmount == 0) revert ZeroAmount();
        if (usdtAmount < MIN_AMOUNT) revert AmountTooLow(usdtAmount, MIN_AMOUNT);
        if (usdtAmount > MAX_MINT_PER_USER) revert AmountTooHigh(usdtAmount, MAX_MINT_PER_USER);
        if (buyVault == address(0)) revert BuyVaultNotSet();
        if (treasury == address(0)) revert TreasuryNotSet();

        (uint256 cmiPrice, uint256 deviation, uint256 lastUpdate) = oracle.getLatestCMI();
        _validateOracle(lastUpdate, deviation);

        uint256 feeAmount = _calculateFee(usdtAmount);
        uint256 netToVault = usdtAmount - feeAmount;
        uint256 ompAmount = (netToVault * 1e18 * 1e18) / (cmiPrice * 1e18);

        usdt.safeTransferFrom(msg.sender, address(this), usdtAmount);

        if (feeAmount > 0) {
            usdt.safeTransfer(treasury, feeAmount);
        }

        usdt.safeIncreaseAllowance(buyVault, netToVault);
        IBuyVault(buyVault).deposit(netToVault);

        ompToken.mint(msg.sender, ompAmount);

        emit MintExecuted(
            msg.sender,
            usdtAmount,
            ompAmount,
            feeAmount,
            netToVault,
            cmiPrice,
            block.timestamp
        );
    }

    function redeem(uint256 ompAmount) external nonReentrant {
        if (ompAmount == 0) revert ZeroAmount();
        if (sellVault == address(0)) revert SellVaultNotSet();
        if (treasury == address(0)) revert TreasuryNotSet();

        (uint256 cmiPrice, uint256 deviation, uint256 lastUpdate) = oracle.getLatestCMI();
        _validateOracle(lastUpdate, deviation);

        uint256 usdtValue = (ompAmount * cmiPrice * 1e18) / (1e18 * 1e18);
        uint256 feeAmount = _calculateFee(usdtValue);

        if (ompAmount < MIN_REDEEM_OMP) {
            revert AmountTooLow(ompAmount, MIN_REDEEM_OMP);
        }

        uint256 netToUser = usdtValue - feeAmount;

        ompToken.burn(msg.sender, ompAmount);

        ISellVault(sellVault).payout(msg.sender, netToUser, treasury, feeAmount);

        emit RedeemExecuted(
            msg.sender,
            ompAmount,
            netToUser,
            feeAmount,
            cmiPrice,
            block.timestamp
        );
    }

    function _validateOracle(uint256 lastUpdate, uint256 deviation) internal view {
        if (!oracle.isFresh()) {
            uint256 age = block.timestamp - lastUpdate;
            revert OracleStale(age, 300);
        }
        if (deviation >= 50) {
            revert OracleDeviationTooHigh(deviation, 50);
        }
    }

    function _calculateFee(uint256 usdtAmount) internal pure returns (uint256) {
        return (usdtAmount * FEE_BPS) / BPS_DENOMINATOR;
    }

    function previewMint(uint256 usdtAmount) external view returns (
        uint256 ompAmount,
        uint256 feeAmount,
        uint256 netToVault
    ) {
        (uint256 cmiPrice,,) = oracle.getLatestCMI();
        feeAmount = _calculateFee(usdtAmount);
        netToVault = usdtAmount - feeAmount;
        ompAmount = (netToVault * 1e18 * 1e18) / (cmiPrice * 1e18);
    }

    function previewRedeem(uint256 ompAmount) external view returns (
        uint256 usdtAmount,
        uint256 feeAmount
    ) {
        (uint256 cmiPrice,,) = oracle.getLatestCMI();
        uint256 usdtValue = (ompAmount * cmiPrice * 1e18) / (1e18 * 1e18);
        feeAmount = _calculateFee(usdtValue);
        usdtAmount = usdtValue - feeAmount;
    }

    function calculateFee(uint256 usdtAmount) external pure returns (uint256) {
        return _calculateFee(usdtAmount);
    }
}
