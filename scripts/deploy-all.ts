import { ethers } from "hardhat";
import * as fs from "fs";
import * as path from "path";

interface DeployedAddresses {
    network: string;
    chainId: number;
    tokenA: string;
    tokenB: string;
    factory: string;
    router: string;
    pairAB: string;
    deployer: string;
    timestamp: string;
}

async function main() {
    console.log("🚀 Starting Zama Swap deployment...\n");

    const [deployer] = await ethers.getSigners();
    const network = await ethers.provider.getNetwork();

    console.log("📋 Deployment Details:");
    console.log("  Network:", network.name);
    console.log("  Chain ID:", network.chainId);
    console.log("  Deployer:", deployer.address);
    console.log("  Balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH\n");

    // Deploy Token A
    console.log("📦 Deploying Token A (Confidential USDC)...");
    const TokenA = await ethers.getContractFactory("ConfidentialERC20");
    const tokenA = await TokenA.deploy("Confidential USDC", "cUSDC");
    await tokenA.waitForDeployment();
    const tokenAAddress = await tokenA.getAddress();
    console.log("  ✅ Token A deployed to:", tokenAAddress);

    // Deploy Token B
    console.log("\n📦 Deploying Token B (Confidential WETH)...");
    const TokenB = await ethers.getContractFactory("ConfidentialERC20");
    const tokenB = await TokenB.deploy("Confidential WETH", "cWETH");
    await tokenB.waitForDeployment();
    const tokenBAddress = await tokenB.getAddress();
    console.log("  ✅ Token B deployed to:", tokenBAddress);

    // Mint initial tokens to deployer for testing
    console.log("\n💰 Minting initial tokens...");
    const mintAmount = ethers.parseEther("1000000"); // 1 million tokens

    const mintTxA = await tokenA.mint(deployer.address, mintAmount);
    await mintTxA.wait();
    console.log("  ✅ Minted", ethers.formatEther(mintAmount), "cUSDC to deployer");

    const mintTxB = await tokenB.mint(deployer.address, mintAmount);
    await mintTxB.wait();
    console.log("  ✅ Minted", ethers.formatEther(mintAmount), "cWETH to deployer");

    // Deploy Factory
    console.log("\n📦 Deploying ZamaSwapFactory...");
    const Factory = await ethers.getContractFactory("ZamaSwapFactory");
    const factory = await Factory.deploy(deployer.address);
    await factory.waitForDeployment();
    const factoryAddress = await factory.getAddress();
    console.log("  ✅ Factory deployed to:", factoryAddress);

    // Deploy Router
    console.log("\n📦 Deploying ZamaSwapRouter...");
    const Router = await ethers.getContractFactory("ZamaSwapRouter");
    const router = await Router.deploy(factoryAddress);
    await router.waitForDeployment();
    const routerAddress = await router.getAddress();
    console.log("  ✅ Router deployed to:", routerAddress);

    // Create pair A-B
    console.log("\n🔗 Creating trading pair (cUSDC/cWETH)...");
    const createPairTx = await factory.createPair(tokenAAddress, tokenBAddress);
    const receipt = await createPairTx.wait();

    const pairAddress = await factory.getPair(tokenAAddress, tokenBAddress);
    console.log("  ✅ Pair created at:", pairAddress);

    // Authorize router to view pair reserves
    console.log("\n🔐 Authorizing router...");
    const Pair = await ethers.getContractFactory("ZamaSwapPair");
    const pair = Pair.attach(pairAddress);

    const authTx = await pair.authorizeViewer(routerAddress);
    await authTx.wait();
    console.log("  ✅ Router authorized to view pair reserves");

    // Add initial liquidity (optional)
    console.log("\n💧 Adding initial liquidity...");
    const liquidityAmount0 = ethers.parseEther("100000"); // 100k cUSDC
    const liquidityAmount1 = ethers.parseEther("50"); // 50 cWETH (price: 1 ETH = 2000 USDC)

    // Approve router to spend tokens
    const approveTxA = await tokenA.approve(routerAddress, liquidityAmount0);
    await approveTxA.wait();

    const approveTxB = await tokenB.approve(routerAddress, liquidityAmount1);
    await approveTxB.wait();

    console.log("  ✅ Router approved to spend tokens");

    // Add liquidity through router
    const deadline = Math.floor(Date.now() / 1000) + 1200; // 20 minutes from now
    const addLiquidityTx = await router.addLiquidity(
        tokenAAddress,
        tokenBAddress,
        liquidityAmount0,
        liquidityAmount1,
        0, // amountAMin
        0, // amountBMin
        deployer.address,
        deadline
    );

    const liquidityReceipt = await addLiquidityTx.wait();
    console.log("  ✅ Initial liquidity added");
    console.log("    - cUSDC:", ethers.formatEther(liquidityAmount0));
    console.log("    - cWETH:", ethers.formatEther(liquidityAmount1));

    // Save deployment addresses
    const deployedAddresses: DeployedAddresses = {
        network: network.name,
        chainId: Number(network.chainId),
        tokenA: tokenAAddress,
        tokenB: tokenBAddress,
        factory: factoryAddress,
        router: routerAddress,
        pairAB: pairAddress,
        deployer: deployer.address,
        timestamp: new Date().toISOString(),
    };

    const outputDir = path.join(__dirname, "..", "deployments");
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    const outputFile = path.join(outputDir, `${network.name}-${network.chainId}.json`);
    fs.writeFileSync(outputFile, JSON.stringify(deployedAddresses, null, 2));

    console.log("\n📄 Deployment addresses saved to:", outputFile);

    // Create a frontend-friendly config
    const frontendConfig = {
        chainId: Number(network.chainId),
        contracts: {
            factory: factoryAddress,
            router: routerAddress,
            tokens: {
                cUSDC: {
                    address: tokenAAddress,
                    name: "Confidential USDC",
                    symbol: "cUSDC",
                    decimals: 18,
                },
                cWETH: {
                    address: tokenBAddress,
                    name: "Confidential WETH",
                    symbol: "cWETH",
                    decimals: 18,
                },
            },
            pairs: [
                {
                    address: pairAddress,
                    token0: tokenAAddress,
                    token1: tokenBAddress,
                    symbol: "cUSDC/cWETH",
                },
            ],
        },
    };

    const frontendConfigFile = path.join(__dirname, "..", "frontend", "src", "contracts.json");
    const frontendDir = path.dirname(frontendConfigFile);
    if (!fs.existsSync(frontendDir)) {
        fs.mkdirSync(frontendDir, { recursive: true });
    }
    fs.writeFileSync(frontendConfigFile, JSON.stringify(frontendConfig, null, 2));

    console.log("📄 Frontend config saved to:", frontendConfigFile);

    // Summary
    console.log("\n" + "=".repeat(60));
    console.log("🎉 DEPLOYMENT COMPLETE!");
    console.log("=".repeat(60));
    console.log("\n📋 Contract Addresses:");
    console.log("  🏭 Factory:    ", factoryAddress);
    console.log("  🔀 Router:     ", routerAddress);
    console.log("  💵 cUSDC:      ", tokenAAddress);
    console.log("  💎 cWETH:      ", tokenBAddress);
    console.log("  🔗 Pair (A/B): ", pairAddress);
    console.log("\n💡 Next Steps:");
    console.log("  1. Update .env with contract addresses");
    console.log("  2. Configure frontend with the generated contracts.json");
    console.log("  3. Test swaps using the router");
    console.log("  4. Deploy frontend to hosting");
    console.log("  5. Configure Telegram bot with Mini App URL");
    console.log("\n🔍 Verify contracts on block explorer:");
    if (network.name === "zama" || network.chainId === 8009n) {
        console.log("  https://explorer.zama.ai/address/" + factoryAddress);
    } else if (network.name === "sepolia") {
        console.log("  npx hardhat verify --network sepolia", factoryAddress, deployer.address);
    }
    console.log("");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });
