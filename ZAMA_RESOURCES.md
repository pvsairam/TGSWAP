# 🔗 Zama fhEVM Official Resources & Links

## 📚 **Official Documentation**

### Core Documentation
- **Developer Docs**: https://docs.zama.ai/protocol
- **Litepaper**: https://docs.zama.ai/protocol/zama-protocol-litepaper
- **Whitepaper**: https://github.com/zama-ai/fhevm/blob/main/fhevm-whitepaper.pdf

### Implementation Guides
- **ERC-7984 Confidential Tokens**: https://docs.zama.org/protocol/examples/openzeppelin-confidential-contracts/erc7984
- **Relayer SDK & Gateway**: https://docs.zama.org/protocol/relayer-sdk-guides/v0.1/fhevm-relayer/initialization
- **Contract Addresses**: https://docs.zama.org/protocol/solidity-guides/smart-contract/configure/contract_addresses

---

## 🌐 **Network & Infrastructure**

### Testnet
- **Network**: Sepolia Testnet (Chain ID: 11155111)
- **RPC URL**: https://rpc.sepolia.org
- **Relayer URL**: https://relayer.testnet.zama.cloud

### Monitoring & Status
- **Testnet Explorer**: https://explorer.testnet.zama.cloud/
- **Testnet Status**: https://status.zama.ai/
- **Protocol Dashboard**: https://dune.com/zama_fhe/protocol-overview

---

## 💰 **Tokens on Zama fhEVM**

### ✅ **What You Need (From Zama Admin)**

**Q: "I need zama test tokens and preferably stablecoins on zama"**

**A: "You just need to create normal ERC-20 tokens on Sepolia testnet. That's it. There is no specific token for ZAMA."**

### For Confidential Tokens:
- **Use ERC-7984 Standard** ✅ (We've already implemented this!)
- **Guide**: https://docs.zama.org/protocol/examples/openzeppelin-confidential-contracts/erc7984
- **Deploy on**: Sepolia testnet

### Our Implementation:
✅ We've already created `ConfidentialERC20.sol` following ERC-7984 standard
✅ Located at: `contracts/tokens/ConfidentialERC20.sol`
✅ Includes encrypted balances, allowances, and permission system

---

## 🔧 **Contract Addresses (Sepolia - Chain ID: 11155111)**

### FHEVM Host Chain Contracts
```
FHEVM Executor:    0x848B0066793BcC60346Da1F49049357399B8D595
ACL Contract:      0x687820221192C5B662b25367F70076A37bc79b6c
HCU Limit:         0x594BB474275918AF9609814E68C61B1587c5F838
KMS Verifier:      0x1364cBBf2cDF5032C47d8226a6f6FBD2AFCDacAC
Input Verifier:    0xbc91f3daD1A5F19F8390c400196e58073B6a0BC4
Decryption Oracle: 0xa02Cda4Ca3a71D7C46997716F4283aa851C28812
```

### Gateway Chain Contracts (Chain ID: 55815)
```
Decryption Address:        0xb6E160B1ff80D67Bfe90A85eE06Ce0A2613607D1
Input Verification Address: 0x7048C39f048125eDa9d678AEbaDfB22F7900a29F
```

---

## 🎯 **How Our Project Uses These**

### Network Configuration ✅
```typescript
// hardhat.config.ts
zama: {
  url: "https://rpc.sepolia.org",        // Sepolia RPC
  chainId: 11155111,                     // Sepolia Chain ID
}
```

### Contract Integration ✅
```solidity
// contracts/tokens/ConfidentialERC20.sol
// Implements ERC-7984 standard for confidential tokens
// Uses encrypted balances and allowances
// Permission-based access control
```

### Environment Configuration ✅
```bash
# .env.example
SEPOLIA_RPC_URL=https://rpc.sepolia.org
RELAYER_URL=https://relayer.testnet.zama.cloud
ACL_CONTRACT=0x687820221192C5B662b25367F70076A37bc79b6c
# ... (all contract addresses included)
```

---

## 📖 **Key Learning Points**

### ✅ **Correct Setup (What We've Implemented)**

1. **Network**: Deploy on Sepolia testnet (Chain ID: 11155111)
2. **Tokens**: Create ERC-7984 confidential tokens (not special Zama tokens)
3. **RPC**: Use Sepolia RPC URL (not devnet.zama.ai)
4. **Relayer**: Use https://relayer.testnet.zama.cloud for FHE operations
5. **Contracts**: Reference official Zama contract addresses

### ❌ **Common Mistakes to Avoid**

1. ❌ Using `https://devnet.zama.ai` as RPC URL
2. ❌ Thinking there's a separate "Zama chain" (it's on Sepolia!)
3. ❌ Looking for special "Zama tokens" (use normal ERC-20 or ERC-7984)
4. ❌ Wrong chain ID (8009 instead of 11155111)
5. ❌ Not using the relayer URL for FHE-specific operations

---

## 🚀 **Getting Started**

### Step 1: Get Sepolia ETH
- **Faucet 1**: https://sepoliafaucet.com/
- **Faucet 2**: https://faucet.quicknode.com/ethereum/sepolia
- **Faucet 3**: https://www.infura.io/faucet/sepolia

### Step 2: Deploy Your Confidential Tokens
```bash
# We've already created ConfidentialERC20.sol
# Just deploy it to Sepolia:

npm run deploy:zama

# This deploys:
# - ConfidentialERC20 (cUSDC)
# - ConfidentialERC20 (cWETH)
# - ZamaSwapFactory
# - ZamaSwapRouter
# - Creates initial pair
```

### Step 3: Verify on Explorer
- **Sepolia Etherscan**: https://sepolia.etherscan.io/
- **Zama Explorer**: https://explorer.testnet.zama.cloud/

### Step 4: Monitor & Debug
- **Status Page**: https://status.zama.ai/
- **Dashboard**: https://dune.com/zama_fhe/protocol-overview

---

## 📞 **Community Support**

### Official Channels
- **Discord**: https://discord.gg/zama (for technical support)
- **Forum**: Check Zama documentation for community forums
- **GitHub Issues**: https://github.com/zama-ai/fhevm/issues

### Response Time
- Zama admins are active and helpful
- Community members share solutions
- Check existing issues before asking

---

## ✅ **Our Implementation Status**

| Component | Status | Details |
|-----------|--------|---------|
| Network Config | ✅ Fixed | Using Sepolia (11155111) |
| RPC URL | ✅ Fixed | Using rpc.sepolia.org |
| Relayer URL | ✅ Added | https://relayer.testnet.zama.cloud |
| Contract Addresses | ✅ Added | All official addresses in .env |
| ERC-7984 Token | ✅ Done | ConfidentialERC20.sol |
| AMM Contracts | ✅ Done | Factory, Router, Pair |
| Frontend | ✅ Done | React + Telegram WebApp |
| Chain ID | ✅ Fixed | 11155111 everywhere |

---

## 🎓 **Additional Resources**

### Learning Materials
- **Zama Blog**: Latest updates and tutorials
- **GitHub Examples**: https://github.com/zama-ai/fhevm
- **Workshop**: https://github.com/zama-ai/fhevm-workshop

### Technical References
- **fhEVM Contracts**: https://github.com/zama-ai/fhevm-contracts
- **OpenZeppelin Confidential**: ERC-7984 implementation
- **Hardhat Template**: https://github.com/zama-ai/fhevm-hardhat-template

---

## 🔍 **Verification Checklist**

Before deploying, verify:

- [ ] Network is Sepolia (Chain ID: 11155111)
- [ ] RPC URL is https://rpc.sepolia.org
- [ ] Relayer URL is configured
- [ ] Contract addresses are from official docs
- [ ] Tokens follow ERC-7984 standard
- [ ] Have Sepolia ETH for gas
- [ ] Contracts compile without errors
- [ ] Tests pass in mocked mode

---

## 🎉 **Summary**

**Everything in our project is now correctly configured!**

✅ Using Sepolia testnet (not a separate Zama chain)
✅ Using official contract addresses
✅ Implementing ERC-7984 for confidential tokens
✅ Using relayer URL for FHE operations
✅ Following official documentation

**No changes needed - we're ready to deploy!** 🚀

---

**Last Updated**: Based on Zama admin responses and official documentation (November 2025)

**Official Docs**: https://docs.zama.ai/protocol
