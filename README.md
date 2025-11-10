# Zama Swap - Confidential DEX on Telegram

![Zama Swap Banner](https://img.shields.io/badge/Zama-FHE%20Powered-purple?style=for-the-badge)
![Telegram](https://img.shields.io/badge/Telegram-Mini%20App-blue?style=for-the-badge)
![Solidity](https://img.shields.io/badge/Solidity-0.8.24-363636?style=for-the-badge&logo=solidity)

**A privacy-preserving decentralized exchange built with Zama's fhEVM, deployed as a Telegram Mini App for the Zama Developer Program November 2025.**

## 🌟 Overview

Zama Swap is a confidential token swap application that leverages **Fully Homomorphic Encryption (FHE)** to keep swap amounts and balances encrypted on-chain. Built as a Telegram Mini App, it combines privacy-preserving DeFi with Telegram's massive user base for a seamless trading experience.

### Core Features

- **🔐 Private Trading**: Swap amounts and balances remain encrypted on-chain using fhEVM
- **🛡️ No MEV/Front-running**: FHE makes transaction details invisible to validators
- **📱 Telegram Integration**: Seamless UX without leaving the chat app
- **⚡ Fast & Efficient**: Optimized AMM with constant product formula
- **🔒 Confidential Liquidity**: Add and remove liquidity with encrypted amounts
- **🎯 No Slippage Tracking**: Private order flow prevents MEV exploitation

## 🏗️ Architecture

### Smart Contracts (Solidity + fhEVM)

```
contracts/
├── ZamaSwapPair.sol          # Core AMM pair with encrypted reserves
├── ZamaSwapFactory.sol       # Factory for creating pairs
├── ZamaSwapRouter.sol        # Router for multi-hop swaps
├── tokens/
│   └── ConfidentialERC20.sol # ERC-7984 compliant encrypted token
├── libraries/
│   └── SwapMath.sol          # AMM math library
└── interfaces/               # Contract interfaces
```

### Frontend (React + Telegram WebApp)

```
frontend/
├── src/
│   ├── App.tsx               # Main application
│   ├── components/
│   │   └── SwapCard.tsx      # Swap interface
│   ├── hooks/
│   │   └── useTelegram.ts    # Telegram integration hook
│   ├── utils/
│   │   └── contracts.ts      # Contract utilities
│   └── types/
│       └── index.ts          # TypeScript definitions
└── package.json
```

## 🚀 Quick Start

### Prerequisites

- Node.js v20+ and npm
- MetaMask or compatible Web3 wallet
- Telegram account (for Mini App testing)

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/pvsairam/TGSWAP.git
cd TGSWAP
```

2. **Install root dependencies**

```bash
npm install
```

3. **Install frontend dependencies**

```bash
cd frontend
npm install
cd ..
```

4. **Set up environment variables**

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
PRIVATE_KEY=your_private_key_here
ZAMA_RPC_URL=https://devnet.zama.ai
SEPOLIA_RPC_URL=https://rpc.sepolia.org
FHEVM_MOCKED=true  # Set to false for real FHE deployment
```

## 📦 Development

### Compile Contracts

```bash
npm run compile
```

### Run Tests

```bash
# Fast testing with mocked FHE
npm run test:mocked

# Real FHE testing (slower but accurate)
npm test
```

### Deploy Contracts

#### Local Development

```bash
# Start local Hardhat node
npm run node

# In another terminal, deploy contracts
npm run deploy:local
```

#### Sepolia Testnet (Zama devnet)

```bash
npm run deploy:zama
```

This will:
- Deploy ConfidentialERC20 tokens (cUSDC, cWETH)
- Deploy Factory and Router contracts
- Create an initial trading pair
- Add initial liquidity
- Save addresses to `deployments/` and `frontend/src/contracts.json`

### Run Frontend

```bash
cd frontend
npm run dev
```

Frontend will be available at `http://localhost:5173`

## 🤖 Telegram Mini App Setup

### 1. Create Telegram Bot

1. Open [@BotFather](https://t.me/botfather) in Telegram
2. Send `/newbot` and follow instructions
3. Save your bot token

### 2. Configure Mini App

1. Send `/mybots` to @BotFather
2. Select your bot → **Bot Settings** → **Configure Mini App**
3. Enable Mini App
4. Set URL: `https://your-deployed-app.vercel.app` (after deployment)

### 3. Deploy Frontend

#### Option A: Vercel (Recommended)

```bash
cd frontend
npm install -g vercel
npm run build
vercel --prod
```

#### Option B: Firebase

```bash
npm install -g firebase-tools
firebase init hosting
firebase deploy --only hosting
```

#### Option C: GitHub Pages

```bash
npm run build
# Push dist/ to gh-pages branch
```

### 4. Set Menu Button

1. Go to @BotFather → **Bot Settings** → **Configure Menu Button**
2. Edit Menu Button
3. Set Button Name: "Swap"
4. Set URL: Your deployed frontend URL

### 5. Test Your Mini App

Open your bot in Telegram and click the menu button!

Share link: `https://t.me/YourBotName/swap`

## 🧪 Testing

### Contract Tests

```bash
# Run all tests
npm test

# Run specific test file
npx hardhat test test/ZamaSwap.test.ts

# With gas reporting
REPORT_GAS=true npm test
```

### Frontend Tests

```bash
cd frontend
npm run lint
```

## 📚 Smart Contract Details

### ZamaSwapPair.sol

Core AMM pair contract implementing:
- Encrypted reserve management
- Two-step swap mechanism (for FHE compatibility)
- Access control for viewing reserves
- LP token minting/burning
- Pool locking during pending operations

**Key Functions:**
- `mint(address to)`: Add liquidity
- `burn(address to)`: Remove liquidity
- `swap(uint256 amount0Out, uint256 amount1Out, address to, bytes data)`: Execute swap
- `getReserves()`: View reserves (authorized only)

### ZamaSwapRouter.sol

Router for convenient multi-hop swaps:
- `addLiquidity()`: Add liquidity with optimal amounts
- `removeLiquidity()`: Remove liquidity and receive tokens
- `swapExactTokensForTokens()`: Swap exact input for minimum output
- `swapTokensForExactTokens()`: Swap maximum input for exact output
- `getAmountOut()`: Calculate output amount
- `getAmountsOut()`: Calculate outputs for multi-hop path

### ConfidentialERC20.sol

ERC-7984 compliant token with encrypted balances:
- Encrypted balance storage
- `transferEncrypted()`: Transfer with encrypted amount
- `approveEncrypted()`: Approve with encrypted amount
- `balanceOfSealed()`: Get encrypted balance for decryption
- `grantPermission()`: Allow addresses to view balance

## 🔐 Security Considerations

### FHE Limitations

1. **Division Constraint**: Cannot divide two encrypted numbers directly
   - Solution: Use division invariance technique (multiply by random)
   - Implemented in swap calculations

2. **Access Control**: Encrypted data requires proper permission management
   - Used `authorizeViewer()` for pairs
   - Users can grant permissions via `grantPermission()`

3. **Gas Optimization**: FHE operations are expensive
   - Use mocked mode for development
   - Batch operations where possible

### Production Recommendations

- ✅ Audit contracts before mainnet deployment
- ✅ Implement emergency pause mechanism
- ✅ Add multisig for admin functions
- ✅ Monitor for unusual activity
- ✅ Set reasonable gas limits
- ✅ Implement rate limiting on frontend

## 📊 Deployed Contracts

### Sepolia Testnet (Zama devnet)

After running `npm run deploy:zama`, addresses will be saved in:
- `deployments/zama-8009.json`
- `frontend/src/contracts.json`

Example:
```json
{
  "chainId": 8009,
  "contracts": {
    "factory": "0x...",
    "router": "0x...",
    "tokens": {
      "cUSDC": { "address": "0x...", "symbol": "cUSDC", "decimals": 18 },
      "cWETH": { "address": "0x...", "symbol": "cWETH", "decimals": 18 }
    }
  }
}
```

## 🎯 Roadmap

### Phase 1: Core Functionality ✅
- [x] Encrypted token swaps
- [x] Liquidity provision
- [x] Telegram Mini App integration

### Phase 2: Enhanced Features 🚧
- [ ] Limit orders with encrypted prices
- [ ] Multi-hop routing optimization
- [ ] Price charts and analytics
- [ ] Transaction history

### Phase 3: Social Features 🔮
- [ ] Group trading pools
- [ ] Referral system
- [ ] Privacy scoring
- [ ] Portfolio sharing (without amounts)

### Phase 4: Mainnet 🚀
- [ ] Security audit
- [ ] Mainnet deployment
- [ ] Liquidity mining program
- [ ] Community governance

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Zama** for fhEVM technology and developer program
- **Telegram** for Mini Apps platform
- **OpenZeppelin** for secure contract libraries
- **Hardhat** for development framework

## 📞 Contact & Links

- **GitHub**: [github.com/pvsairam/TGSWAP](https://github.com/pvsairam/TGSWAP)
- **Telegram Bot**: [@ZamaSwapBot](https://t.me/ZamaSwapBot) (after deployment)
- **Documentation**: [docs.zama.ai](https://docs.zama.ai)
- **Zama Discord**: [discord.gg/zama](https://discord.gg/zama)

---

**Built with ❤️ for the Zama Developer Program November 2025**

*Bringing privacy to DeFi, one swap at a time* 🔒🔄
