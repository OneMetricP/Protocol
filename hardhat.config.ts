import "dotenv/config";
import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/config";

const bscPrivateKey = process.env.BSC_PRIVATE_KEY
  ? (process.env.BSC_PRIVATE_KEY.startsWith("0x")
      ? process.env.BSC_PRIVATE_KEY
      : `0x${process.env.BSC_PRIVATE_KEY}`)
  : undefined;

// One Metric Protocol — BNB Smart Chain deployment config
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: { enabled: true, runs: 200 },
    },
  },
  networks: {
    // BNB Smart Chain Mainnet (Chain ID: 56) — primary deployment network
    bsc: {
      url: process.env.BSC_RPC_URL || "https://bsc-dataseed.binance.org",
      accounts: bscPrivateKey ? [bscPrivateKey] : [],
      chainId: 56,
    },
    // BNB Smart Chain Testnet (Chain ID: 97)
    bscTestnet: {
      url: process.env.BSC_TESTNET_RPC_URL || "https://bsc-testnet.publicnode.com",
      accounts: bscPrivateKey ? [bscPrivateKey] : [],
      chainId: 97,
    },
  },
  etherscan: {
    apiKey: {
      bsc: process.env.BSCSCAN_API_KEY || "",
      bscTestnet: process.env.BSCSCAN_API_KEY || "",
    },
    customChains: [
      {
        network: "bsc",
        chainId: 56,
        urls: {
          apiURL: "https://api.bscscan.com/api",
          browserURL: "https://bscscan.com",
        },
      },
      {
        network: "bscTestnet",
        chainId: 97,
        urls: {
          apiURL: "https://api-testnet.bscscan.com/api",
          browserURL: "https://testnet.bscscan.com",
        },
      },
    ],
  },
};

export default config;
