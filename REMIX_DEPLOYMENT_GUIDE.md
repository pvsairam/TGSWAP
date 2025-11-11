# 🚀 Deploy ZamaSwap Contracts Using Remix IDE on Sepolia

## ✅ Why Remix IDE?

Remix IDE is **perfect** for deploying your contracts because:
- ✅ No local environment setup needed
- ✅ Browser-based compiler (bypasses network restrictions)
- ✅ Direct deployment to Sepolia testnet
- ✅ Easy to verify and interact with contracts
- ✅ Works with MetaMask for deployment

---

## 📋 Prerequisites

### 1. Get Sepolia ETH
You'll need **~0.5 ETH** on Sepolia testnet for deployment:
- **Faucet 1**: https://sepoliafaucet.com/
- **Faucet 2**: https://faucet.quicknode.com/ethereum/sepolia
- **Faucet 3**: https://www.infura.io/faucet/sepolia

### 2. Setup MetaMask
- Install MetaMask browser extension
- Add Sepolia testnet to MetaMask:
  - Network Name: `Sepolia Testnet`
  - RPC URL: `https://rpc.sepolia.org`
  - Chain ID: `11155111`
  - Currency Symbol: `ETH`
  - Block Explorer: `https://sepolia.etherscan.io`

---

## 🎯 Deployment Steps

### **Step 1: Open Remix IDE**

Go to: **https://remix.ethereum.org**

### **Step 2: Create New Workspace**

1. Click "File Explorers" in left sidebar
2. Create a new workspace: `ZamaSwap`
3. Delete default files (optional)

### **Step 3: Upload Contract Files**

Create the following folder structure and copy your contracts:

```
contracts/
├── tokens/
│   └── ConfidentialERC20.sol
├── libraries/
│   └── SwapMath.sol
├── interfaces/
│   ├── IZamaSwapPair.sol
│   ├── IZamaSwapFactory.sol
│   └── IZamaSwapRouter.sol
├── ZamaSwapPair.sol
├── ZamaSwapFactory.sol
└── ZamaSwapRouter.sol
```

**How to upload:**
1. Right-click on `contracts` folder
2. Click "New File" or "New Folder"
3. Copy-paste your contract code from your GitHub repo
4. Or directly import from GitHub (see below)

### **Step 4: Import from GitHub (Easier Method)**

Remix can directly import from GitHub!

1. In Remix, click on "GitHub" icon in left sidebar
2. Enter your GitHub URL: `https://github.com/pvsairam/TGSWAP`
3. Select your branch: `claude/zama-fhe-swap-telegram-app-011CUz954ouohbJQMSighVW4`
4. Remix will import all files automatically!

---

## 🔨 Compilation

### **Step 1: Select Compiler**

1. Click "Solidity Compiler" icon in left sidebar
2. Select compiler version: `0.8.24`
3. Enable "Auto compile" (optional)
4. Click "Advanced Configurations"
   - EVM Version: `paris` or `shanghai`
   - Enable optimization: `200` runs

### **Step 2: Install OpenZeppelin**

Your contracts use `@openzeppelin/contracts`. Remix will auto-detect and install them!

If needed, you can manually import:
```solidity
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/token/ERC20/ERC20.sol";
```

### **Step 3: Compile Each Contract**

Compile in this order (check for errors):
1. ✅ `contracts/tokens/ConfidentialERC20.sol`
2. ✅ `contracts/libraries/SwapMath.sol`
3. ✅ `contracts/interfaces/*.sol` (all interfaces)
4. ✅ `contracts/ZamaSwapPair.sol`
5. ✅ `contracts/ZamaSwapFactory.sol`
6. ✅ `contracts/ZamaSwapRouter.sol`

---

## 🚀 Deployment to Sepolia

### **Connect MetaMask**

1. Click "Deploy & Run Transactions" icon in left sidebar
2. Environment: Select **"Injected Provider - MetaMask"**
3. MetaMask will popup → Click "Connect"
4. Ensure you're on **Sepolia Testnet** (Chain ID: 11155111)

### **Deployment Order (IMPORTANT!)**

You **must** deploy in this order:

---

### **1️⃣ Deploy Confidential Tokens**

#### **Deploy cUSDC:**
1. Select contract: `ConfidentialERC20`
2. Constructor parameters:
   ```
   _name: "Confidential USDC"
   _symbol: "cUSDC"
   ```
3. Click **"Deploy"**
4. Confirm transaction in MetaMask
5. **Copy deployed address** → Save it!

#### **Deploy cWETH:**
1. Select contract: `ConfidentialERC20`
2. Constructor parameters:
   ```
   _name: "Confidential WETH"
   _symbol: "cWETH"
   ```
3. Click **"Deploy"**
4. Confirm transaction in MetaMask
5. **Copy deployed address** → Save it!

#### **Mint Initial Supply:**
After deploying each token:
1. Expand the deployed contract in "Deployed Contracts" section
2. Find `mint` function
3. Parameters:
   ```
   to: YOUR_WALLET_ADDRESS
   amount: 1000000000000000000000000  (1 million tokens with 18 decimals)
   ```
4. Click **"transact"**
5. Confirm in MetaMask

---

### **2️⃣ Deploy ZamaSwapFactory**

1. Select contract: `ZamaSwapFactory`
2. Constructor parameter:
   ```
   _feeToSetter: YOUR_WALLET_ADDRESS
   ```
3. Click **"Deploy"**
4. Confirm transaction in MetaMask
5. **Copy deployed address** → Save it!

---

### **3️⃣ Deploy ZamaSwapRouter**

1. Select contract: `ZamaSwapRouter`
2. Constructor parameter:
   ```
   _factory: FACTORY_ADDRESS_FROM_STEP_2
   ```
3. Click **"Deploy"**
4. Confirm transaction in MetaMask
5. **Copy deployed address** → Save it!

---

### **4️⃣ Create Initial Pair**

1. Expand the **Factory** contract in "Deployed Contracts"
2. Find `createPair` function
3. Parameters:
   ```
   tokenA: cUSDC_ADDRESS
   tokenB: cWETH_ADDRESS
   ```
4. Click **"transact"**
5. Confirm in MetaMask
6. Wait for confirmation
7. Call `getPair` function to get the pair address:
   ```
   tokenA: cUSDC_ADDRESS
   tokenB: cWETH_ADDRESS
   ```
8. **Copy pair address** → Save it!

---

### **5️⃣ Approve Router (Prepare for Liquidity)**

For **each token** (cUSDC and cWETH):

1. Expand the token contract
2. Find `approve` function
3. Parameters:
   ```
   spender: ROUTER_ADDRESS
   amount: 115792089237316195423570985008687907853269984665640564039457584007913129639935
   (This is max uint256 for unlimited approval)
   ```
4. Click **"transact"**
5. Confirm in MetaMask

---

### **6️⃣ Add Initial Liquidity**

1. Expand the **Router** contract
2. Find `addLiquidity` function
3. Parameters:
   ```
   tokenA: cUSDC_ADDRESS
   tokenB: cWETH_ADDRESS
   amountADesired: 100000000000000000000000  (100,000 cUSDC)
   amountBDesired: 50000000000000000000      (50 cWETH)
   amountAMin: 99000000000000000000000       (99,000 cUSDC - 1% slippage)
   amountBMin: 49500000000000000000          (49.5 cWETH - 1% slippage)
   to: YOUR_WALLET_ADDRESS
   deadline: 1735689600  (Some future timestamp - use https://www.unixtimestamp.com/)
   ```
4. Click **"transact"**
5. Confirm in MetaMask
6. Wait for confirmation ✅

---

## 📝 Save Your Deployed Addresses

Create a file with all your deployed addresses:

```json
{
  "chainId": 11155111,
  "network": "Sepolia",
  "deployed": "2025-11-11",
  "contracts": {
    "tokens": {
      "cUSDC": {
        "address": "0x...",
        "name": "Confidential USDC",
        "symbol": "cUSDC",
        "decimals": 18
      },
      "cWETH": {
        "address": "0x...",
        "name": "Confidential WETH",
        "symbol": "cWETH",
        "decimals": 18
      }
    },
    "factory": "0x...",
    "router": "0x...",
    "pairs": {
      "cUSDC-cWETH": "0x..."
    }
  }
}
```

---

## ✅ Verify Deployment

### **1. On Remix:**
- All contracts should be visible in "Deployed Contracts" section
- You can interact with functions directly

### **2. On Sepolia Etherscan:**
Visit: `https://sepolia.etherscan.io/address/YOUR_CONTRACT_ADDRESS`

For each contract:
1. Check transaction succeeded
2. View contract code (will show as bytecode)
3. (Optional) Verify contract source code

### **3. Test Basic Functions:**

#### **Check Token Balance:**
1. Expand cUSDC contract
2. Call `balanceOf`:
   ```
   account: YOUR_WALLET_ADDRESS
   ```
3. Should return: `1000000000000000000000000` (1 million)

#### **Check Pair Reserves:**
1. Expand Pair contract
2. Call `getReserves`
3. Should return the liquidity amounts you added

---

## 🔧 Update Frontend Configuration

After deployment, update `frontend/src/contracts.json`:

```json
{
  "chainId": 11155111,
  "contracts": {
    "factory": "YOUR_DEPLOYED_FACTORY_ADDRESS",
    "router": "YOUR_DEPLOYED_ROUTER_ADDRESS",
    "tokens": {
      "cUSDC": {
        "address": "YOUR_DEPLOYED_cUSDC_ADDRESS",
        "name": "Confidential USDC",
        "symbol": "cUSDC",
        "decimals": 18
      },
      "cWETH": {
        "address": "YOUR_DEPLOYED_cWETH_ADDRESS",
        "name": "Confidential WETH",
        "symbol": "cWETH",
        "decimals": 18
      }
    },
    "pairs": [
      {
        "address": "YOUR_DEPLOYED_PAIR_ADDRESS",
        "token0": "YOUR_DEPLOYED_cUSDC_ADDRESS",
        "token1": "YOUR_DEPLOYED_cWETH_ADDRESS",
        "symbol": "cUSDC/cWETH"
      }
    ]
  }
}
```

Then rebuild frontend:
```bash
cd frontend
npm run build
```

---

## 🎯 Deployment Checklist

- [ ] Got Sepolia ETH from faucets (~0.5 ETH)
- [ ] MetaMask connected to Sepolia testnet
- [ ] Uploaded all contract files to Remix
- [ ] Compiled all contracts successfully
- [ ] Deployed cUSDC token ✅
- [ ] Deployed cWETH token ✅
- [ ] Minted initial supply for both tokens
- [ ] Deployed ZamaSwapFactory ✅
- [ ] Deployed ZamaSwapRouter ✅
- [ ] Created cUSDC/cWETH pair ✅
- [ ] Approved router for both tokens
- [ ] Added initial liquidity ✅
- [ ] Saved all deployed addresses
- [ ] Updated frontend/src/contracts.json
- [ ] Verified on Sepolia Etherscan
- [ ] Tested basic functions

---

## 💡 Pro Tips

### **Gas Optimization:**
- Deploy during off-peak hours (cheaper gas)
- Set gas limit manually if needed (MetaMask → Advanced)

### **Common Issues:**

**❌ "Gas estimation failed"**
- Increase gas limit manually
- Check you have enough Sepolia ETH
- Verify constructor parameters are correct

**❌ "Transaction reverted"**
- Check token addresses are correct
- Verify you have token balance
- Ensure approvals are set

**❌ "Nonce too high"**
- MetaMask → Settings → Advanced → Reset Account

### **Verify Contract Source (Optional):**
1. Go to Sepolia Etherscan
2. Click "Contract" tab → "Verify and Publish"
3. Compiler: `v0.8.24`
4. Copy-paste flattened source code
5. Match constructor arguments

---

## 📞 Need Help?

- **Remix Documentation**: https://remix-ide.readthedocs.io/
- **Sepolia Faucets**: Multiple options listed above
- **Etherscan**: https://sepolia.etherscan.io/
- **Zama Discord**: For Zama-specific questions

---

## 🎉 Success!

Once deployed:
1. ✅ All contracts are on Sepolia testnet
2. ✅ Addresses saved
3. ✅ Frontend configuration updated
4. ✅ Ready to deploy frontend to Vercel
5. ✅ Ready to submit to Zama Developer Program!

**Congratulations! Your ZamaSwap is now live on Sepolia!** 🚀

---

**Estimated Total Deployment Time**: 20-30 minutes
**Estimated Total Gas Cost**: ~0.3-0.5 Sepolia ETH

---

**Note**: These are confidential tokens using FHE concepts. In production with real fhEVM library, the encrypted operations would be fully homomorphic. This testnet version maintains the architecture and patterns while being deployable on standard Sepolia.
