# MagicMint Contracts

Smart contracts powering [MagicMint](https://magicmint.app) — the sovereign BEP-20 token factory on BNB Chain.

## Deployed Contract

| Contract | Network | Address |
|---|---|---|
| **TokenFactory** | BSC Mainnet | [`0xCCb8F444B2e3a0dFD1F5f91AAED75c114F6B8514`](https://bscscan.com/address/0xCCb8F444B2e3a0dFD1F5f91AAED75c114F6B8514#code) |

## Overview

### TokenFactory
The main entry point. Users call `createToken()` and pay a flat BNB fee to deploy their own fully-configured BEP-20 token in a single transaction.

### BEP20Token
The token template deployed by the factory. Each token is independently owned by its creator — MagicMint never holds custody.

**Optional features (all included in the flat fee):**

| Feature | What it does |
|---|---|
| **Anti-Bot** | Temporary blacklist for the first ~50 blocks after launch (~2.5 min). Self-destructs automatically to keep trust scores clean. |
| **Anti-Whale** | Enforces max transaction (1% of supply) and max wallet (2% of supply) limits. Owner can adjust or disable at any time. |
| **Airdrop** | Flags the token as airdrop-enabled for use with MagicMint's distribution tooling. |

## Compiler Settings

- **Solidity**: `0.8.24`
- **Optimizer**: Enabled, 200 runs
- **OpenZeppelin**: `^5.4.0`

These settings exactly match the verified contract on BscScan.

## Local Setup

```bash
# Install dependencies
npm install

# Compile contracts
npm run compile

# Run tests
npm run test
```

## Verify on BscScan

```bash
cp .env.example .env
# Fill in ETHERSCAN_API_KEY in .env

npx hardhat verify --network bsc 0xCCb8F444B2e3a0dFD1F5f91AAED75c114F6B8514 \
  150000000000000000 \
  0x0000000000000000000000000000000000000000
```

Constructor arguments:
- `150000000000000000` — 0.15 BNB initial base fee
- `0x000...000` — MINT token address (not deployed at factory launch)

## License

MIT
