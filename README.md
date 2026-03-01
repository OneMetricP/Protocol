# One Metric Protocol

One Metric Protocol is a DeFi index token protocol built on BNB Smart Chain (BSC). It tracks the Crypto Metric Index (CMI) — a diversified basket of leading cryptocurrencies — as a single, collateral-backed, on-chain unit (OMP).

This repository contains the core smart contracts powering the protocol. The full protocol includes on-chain smart contracts, an automated CMI publisher, a proof-of-reserve engine, a transaction executor, and a public-facing web application.

## Technology Stack

- **Blockchain:** BNB Smart Chain (primary deployment)
- **Smart Contracts:** Solidity ^0.8.28
- **Frontend:** Next.js + wagmi + ethers.js
- **Backend:** Python (CMI publisher, PoR engine, indexer, flow tracker)
- **Infrastructure:** Google Cloud Platform (Compute Engine, Cloud Scheduler, Secret Manager)
- **Development:** Hardhat, OpenZeppelin Contracts v5
- **Verification:** BSCScan source verification

## Supported Networks

| Network | Chain ID | Status |
|---|---|---|
| BNB Smart Chain Mainnet | 56 | ✅ Live |
| BNB Smart Chain Testnet | 97 | ✅ Supported |

## Contract Addresses

### BNB Smart Chain Mainnet (Chain ID: 56)

| Contract | Address | Role |
|---|---|---|
| OMPToken | [`0x95cc1F0392BAC5212A04365c598fBC32ffE06D7d`](https://bscscan.com/address/0x95cc1F0392BAC5212A04365c598fBC32ffE06D7d) | BEP-20 index token |
| MintController v4 | [`0x55C377f62994d06134AE63A6712b311906A8FD12`](https://bscscan.com/address/0x55C377f62994d06134AE63A6712b311906A8FD12) | Mint and redemption logic |
| CMIOracle | [`0x958EDD15b23BdCdAAB1D4979536bB4cadb14306a`](https://bscscan.com/address/0x958EDD15b23BdCdAAB1D4979536bB4cadb14306a) | On-chain CMI price feed |
| BuyVault v3 | [`0xE04697EF25535688c19a99817F39692832bF1771`](https://bscscan.com/address/0xE04697EF25535688c19a99817F39692832bF1771) | USDT collateral accumulation |
| SellVault v6 | [`0x33dE87C175C20A30F79A7fe26693f5Ea3A923900`](https://bscscan.com/address/0x33dE87C175C20A30F79A7fe26693f5Ea3A923900) | USDT float for redemptions |
| PoRRegistry v2 | [`0x5cc11798179110e40a8E97F313B46062C434eA45`](https://bscscan.com/address/0x5cc11798179110e40a8E97F313B46062C434eA45) | On-chain Proof of Reserve anchoring |

All contracts are source-verified on BSCScan.

## Features

- **CMI-tracked index token** — OMP price is algorithmically set to the Crypto Metric Index, updated on-chain daily via `CMIOracle`
- **Collateral-backed mint/redeem** — Users deposit USDT to mint OMP; redeem OMP to receive USDT back at current CMI price. 0.50% protocol fee per operation
- **On-chain Proof of Reserve** — `PoRRegistry` anchors periodic reserve reports on-chain, publicly verifiable on BSCScan
- **ReentrancyGuard + SafeERC20** — `MintController` uses OpenZeppelin's ReentrancyGuard and SafeERC20 for safe token handling
- **Gas-efficient design for BNB Smart Chain** — Optimized with `solc` 200-run optimizer, targeting BSC gas costs

## Repository Structure

```
contracts/
  core/
    OMPToken.sol          — BEP-20 OMP token with controller-gated mint/burn
    CMIOracle.sol         — On-chain CMI price feed with freshness and deviation checks
    MintController.sol    — USDT → OMP mint and OMP → USDT redemption logic
    PoRRegistry.sol       — Proof of Reserve on-chain anchoring
  interfaces/
    IOracle.sol           — Oracle interface
    ISellVault.sol        — SellVault interface
hardhat.config.ts         — Hardhat config targeting BNB Smart Chain (Chain ID: 56)
```

## Protocol Components

| Component | Description |
|---|---|
| Smart Contracts | On-chain mint/redeem logic, oracle, and proof of reserve (this repo) |
| CMI Publisher | Automated service that calculates and pushes the CMI price on-chain every 10 seconds |
| Proof of Reserve Engine | Runs every 15 minutes, verifies collateral, and anchors report hashes to `PoRRegistry` |
| Transaction Executor | Handles buy/sell vault operations triggered by mint and redemption flows |
| Web Application | Public dashboard and mint/redeem interface at [app.onemetric.org](https://app.onemetric.org) |
| Indexer | Indexes on-chain events into a queryable database for analytics |

## How It Works

1. **Mint** — User deposits USDT into `MintController`. Contract reads current CMI price from `CMIOracle`, calculates OMP equivalent, and mints new OMP directly to the user's wallet. USDT is routed to `BuyVault`.
2. **Redeem** — User sends OMP to `MintController`. Contract reads current CMI price, calculates USDT equivalent, burns OMP, and releases USDT from `SellVault` to the user.
3. **Price Updates** — An authorized publisher calls `CMIOracle.updateCMI()` with the latest CMI value on BNB Smart Chain. The oracle enforces max staleness (900 seconds) and deviation bounds.
4. **Proof of Reserve** — An off-chain engine periodically verifies total collateral and calls `PoRRegistry.anchor()` with a report hash and reserve ratio, creating a permanent on-chain record.

## Links

- Website: [onemetric.org](https://onemetric.org)
- App: [app.onemetric.org](https://app.onemetric.org)
- Docs: [docs.onemetric.org](https://docs.onemetric.org)
- Twitter: [@OneMetric_P](https://x.com/OneMetric_P)
- Telegram: [t.me/+An868iqltok2Mzll](https://t.me/+An868iqltok2Mzll)

## License

MIT
