# MagicMint Contracts — BNB Chain Token Factory

> **The sovereign BEP-20 token launcher for BNB Chain.**
> Launch a verified, professional token in one transaction — anti-bot, anti-whale, and auditable by design.

[![BSC Mainnet](https://img.shields.io/badge/BSC-Mainnet-F0B90B?logo=binance&logoColor=white)](https://bscscan.com/address/0xCCb8F444B2e3a0dFD1F5f91AAED75c114F6B8514#code)
[![Verified](https://img.shields.io/badge/BscScan-Verified-2ecc71?logo=ethereum&logoColor=white)](https://bscscan.com/address/0xCCb8F444B2e3a0dFD1F5f91AAED75c114F6B8514#code)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Twitter Follow](https://img.shields.io/twitter/follow/MagicMintApp?style=social)](https://x.com/MagicMintApp)

---

## What is MagicMint?

**[MagicMint](https://magicmint.app)** is the leading **BNB Chain token creator** and **BSC meme coin launcher** — built for founders, creators, and communities who want to launch a token without giving up supply, paying predatory listing fees, or writing a single line of Solidity.

🔗 **Website**: [magicmint.app](https://magicmint.app)  
🐦 **Twitter / X**: [@MagicMintApp](https://x.com/MagicMintApp)  

This repository contains the verified smart contracts that power every token created on the platform.

---

## Deployed Contracts

| Contract | Network | Address |
|---|---|---|
| **TokenFactory** | BSC Mainnet | [`0xCCb8F444B2e3a0dFD1F5f91AAED75c114F6B8514`](https://bscscan.com/address/0xCCb8F444B2e3a0dFD1F5f91AAED75c114F6B8514#code) |

---

## How It Works

Anyone can use the [MagicMint BNB token creator](https://magicmint.app) to call `createToken()` on the factory. The factory:

1. Validates the inputs and collects the flat BNB fee
2. Deploys a fresh `BEP20Token` contract owned **100% by the caller**
3. Mints the full supply directly to the creator's wallet
4. Refunds any excess BNB sent

MagicMint never takes custody of your tokens, never holds your liquidity, and never demands a percentage of your supply.

---

## Smart Contracts

### `TokenFactory.sol`
The main entry point. Users pay a flat BNB fee to deploy a fully-configured BEP-20 token in a single transaction. This is the [Binance token creator](https://magicmint.app) contract — deployed, verified, and live on BSC Mainnet.

**Key functions:**
| Function | Description |
|---|---|
| `createToken()` | Deploy a new BEP-20 token. All features included in the flat fee. |
| `calculateFee()` | Preview the fee before transacting. MINT holders receive a discount. |
| `getFees()` | Read current fee configuration. |

### `BEP20Token.sol`
The token template deployed by the factory. Each token is a standalone, independently-owned contract. No proxy patterns, no admin backdoors.

**Optional features (all included at no extra cost):**

| Feature | How it works |
|---|---|
| **Anti-Bot** | Temporary blacklist active for the first ~50 blocks after launch (~2.5 min on BSC). Self-destructs automatically — no re-enabling possible. |
| **Anti-Whale** | Enforces max transaction (1% of supply) and max wallet size (2% of supply). Owner can adjust or disable. |
| **Airdrop-Ready** | Built-in flag enabling use with MagicMint's batch distribution tooling. |

---

## Why BSC / BNB Chain?

> "We don't do 20 chains. We do one better than anyone else."

The [MagicMint BSC token creator](https://magicmint.app) is optimised specifically for BNB Chain:

- ⚡ Contracts tuned for 3-second BSC block times
- ✅ Automatic BscScan verification (the green checkmark on day one)
- 🥞 Native PancakeSwap V3 compatibility
- ⛽ Gas-efficient deployment using OpenZeppelin v5

---

## Compiler Settings

Matching the verified contract on BscScan exactly:

```
Solidity:   0.8.24
Optimizer:  enabled, 200 runs
OpenZeppelin: ^5.4.0
```

---

## Local Setup

```bash
# Install dependencies
npm install

# Compile contracts
npm run compile

# Run tests
npm run test
```

### Verify on BscScan

```bash
cp .env.example .env
# Add your ETHERSCAN_API_KEY and PRIVATE_KEY to .env

npx hardhat verify --network bsc 0xCCb8F444B2e3a0dFD1F5f91AAED75c114F6B8514 \
  150000000000000000 \
  0x0000000000000000000000000000000000000000
```

Constructor arguments:
- `150000000000000000` — 0.15 BNB initial base fee
- `0x000...000` — MINT token address (not deployed at factory launch)

---

## Links

| | |
|---|---|
| 🌐 **Launch a token** | [magicmint.app](https://magicmint.app) |
| 🐦 **Follow updates** | [@MagicMintApp on X](https://x.com/MagicMintApp) |
| 🔍 **Verified contract** | [BscScan](https://bscscan.com/address/0xCCb8F444B2e3a0dFD1F5f91AAED75c114F6B8514#code) |

---

## License

MIT — see [LICENSE](LICENSE) for details.
