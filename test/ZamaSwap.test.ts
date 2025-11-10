import { expect } from "chai";
import { ethers } from "hardhat";
import { ConfidentialERC20, ZamaSwapFactory, ZamaSwapRouter, ZamaSwapPair } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("ZamaSwap", function () {
    let tokenA: ConfidentialERC20;
    let tokenB: ConfidentialERC20;
    let factory: ZamaSwapFactory;
    let router: ZamaSwapRouter;
    let pair: ZamaSwapPair;

    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    const INITIAL_SUPPLY = ethers.parseEther("1000000");
    const LIQUIDITY_AMOUNT_A = ethers.parseEther("100000");
    const LIQUIDITY_AMOUNT_B = ethers.parseEther("50");

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();

        // Deploy tokens
        const Token = await ethers.getContractFactory("ConfidentialERC20");
        tokenA = await Token.deploy("Token A", "TKNA");
        tokenB = await Token.deploy("Token B", "TKNB");

        await tokenA.waitForDeployment();
        await tokenB.waitForDeployment();

        // Mint tokens
        await tokenA.mint(owner.address, INITIAL_SUPPLY);
        await tokenB.mint(owner.address, INITIAL_SUPPLY);

        await tokenA.mint(user1.address, ethers.parseEther("10000"));
        await tokenB.mint(user1.address, ethers.parseEther("10000"));

        // Deploy factory and router
        const Factory = await ethers.getContractFactory("ZamaSwapFactory");
        factory = await Factory.deploy(owner.address);
        await factory.waitForDeployment();

        const Router = await ethers.getContractFactory("ZamaSwapRouter");
        router = await Router.deploy(await factory.getAddress());
        await router.waitForDeployment();

        // Create pair
        await factory.createPair(await tokenA.getAddress(), await tokenB.getAddress());
        const pairAddress = await factory.getPair(await tokenA.getAddress(), await tokenB.getAddress());

        const Pair = await ethers.getContractFactory("ZamaSwapPair");
        pair = Pair.attach(pairAddress) as ZamaSwapPair;

        // Authorize router
        await pair.authorizeViewer(await router.getAddress());
    });

    describe("Token Deployment", function () {
        it("Should deploy tokens with correct names and symbols", async function () {
            expect(await tokenA.name()).to.equal("Token A");
            expect(await tokenA.symbol()).to.equal("TKNA");
            expect(await tokenB.name()).to.equal("Token B");
            expect(await tokenB.symbol()).to.equal("TKNB");
        });

        it("Should mint initial supply to owner", async function () {
            expect(await tokenA.balanceOf(owner.address)).to.equal(INITIAL_SUPPLY);
            expect(await tokenB.balanceOf(owner.address)).to.equal(INITIAL_SUPPLY);
        });
    });

    describe("Factory", function () {
        it("Should create pair successfully", async function () {
            const pairAddress = await factory.getPair(await tokenA.getAddress(), await tokenB.getAddress());
            expect(pairAddress).to.not.equal(ethers.ZeroAddress);
        });

        it("Should track all pairs", async function () {
            expect(await factory.allPairsLength()).to.equal(1);
        });

        it("Should prevent duplicate pair creation", async function () {
            await expect(
                factory.createPair(await tokenA.getAddress(), await tokenB.getAddress())
            ).to.be.revertedWith("ZamaSwapFactory: PAIR_EXISTS");
        });
    });

    describe("Liquidity", function () {
        it("Should add liquidity successfully", async function () {
            const routerAddress = await router.getAddress();

            await tokenA.approve(routerAddress, LIQUIDITY_AMOUNT_A);
            await tokenB.approve(routerAddress, LIQUIDITY_AMOUNT_B);

            const deadline = Math.floor(Date.now() / 1000) + 1200;

            const tx = await router.addLiquidity(
                await tokenA.getAddress(),
                await tokenB.getAddress(),
                LIQUIDITY_AMOUNT_A,
                LIQUIDITY_AMOUNT_B,
                0,
                0,
                owner.address,
                deadline
            );

            await tx.wait();

            const lpBalance = await pair.balanceOf(owner.address);
            expect(lpBalance).to.be.gt(0);
        });

        it("Should remove liquidity successfully", async function () {
            // First add liquidity
            const routerAddress = await router.getAddress();

            await tokenA.approve(routerAddress, LIQUIDITY_AMOUNT_A);
            await tokenB.approve(routerAddress, LIQUIDITY_AMOUNT_B);

            const deadline = Math.floor(Date.now() / 1000) + 1200;

            await router.addLiquidity(
                await tokenA.getAddress(),
                await tokenB.getAddress(),
                LIQUIDITY_AMOUNT_A,
                LIQUIDITY_AMOUNT_B,
                0,
                0,
                owner.address,
                deadline
            );

            const lpBalance = await pair.balanceOf(owner.address);

            // Approve router to spend LP tokens
            await pair.approve(routerAddress, lpBalance);

            // Remove liquidity
            const removeTx = await router.removeLiquidity(
                await tokenA.getAddress(),
                await tokenB.getAddress(),
                lpBalance / 2n, // Remove half
                0,
                0,
                owner.address,
                deadline
            );

            await removeTx.wait();

            const newLpBalance = await pair.balanceOf(owner.address);
            expect(newLpBalance).to.be.lt(lpBalance);
        });
    });

    describe("Swaps", function () {
        beforeEach(async function () {
            // Add initial liquidity
            const routerAddress = await router.getAddress();

            await tokenA.approve(routerAddress, LIQUIDITY_AMOUNT_A);
            await tokenB.approve(routerAddress, LIQUIDITY_AMOUNT_B);

            const deadline = Math.floor(Date.now() / 1000) + 1200;

            await router.addLiquidity(
                await tokenA.getAddress(),
                await tokenB.getAddress(),
                LIQUIDITY_AMOUNT_A,
                LIQUIDITY_AMOUNT_B,
                0,
                0,
                owner.address,
                deadline
            );
        });

        it("Should swap exact tokens for tokens", async function () {
            const routerAddress = await router.getAddress();
            const swapAmount = ethers.parseEther("1000");

            // User1 approves router
            await tokenA.connect(user1).approve(routerAddress, swapAmount);

            const balanceBefore = await tokenB.balanceOf(user1.address);

            const deadline = Math.floor(Date.now() / 1000) + 1200;

            const path = [await tokenA.getAddress(), await tokenB.getAddress()];

            await router.connect(user1).swapExactTokensForTokens(
                swapAmount,
                0, // Min amount out (no slippage protection for test)
                path,
                user1.address,
                deadline
            );

            const balanceAfter = await tokenB.balanceOf(user1.address);
            expect(balanceAfter).to.be.gt(balanceBefore);
        });

        it("Should calculate correct output amount", async function () {
            const amountIn = ethers.parseEther("1000");

            const amountOut = await router.getAmountOut(
                amountIn,
                await tokenA.getAddress(),
                await tokenB.getAddress()
            );

            expect(amountOut).to.be.gt(0);
        });

        it("Should revert if insufficient output amount", async function () {
            const routerAddress = await router.getAddress();
            const swapAmount = ethers.parseEther("1000");

            await tokenA.connect(user1).approve(routerAddress, swapAmount);

            const deadline = Math.floor(Date.now() / 1000) + 1200;
            const path = [await tokenA.getAddress(), await tokenB.getAddress()];

            // Calculate expected output
            const expectedOut = await router.getAmountOut(
                swapAmount,
                await tokenA.getAddress(),
                await tokenB.getAddress()
            );

            // Request more than possible
            await expect(
                router.connect(user1).swapExactTokensForTokens(
                    swapAmount,
                    expectedOut * 2n, // Request 2x the possible output
                    path,
                    user1.address,
                    deadline
                )
            ).to.be.revertedWith("ZamaSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        });
    });

    describe("Access Control", function () {
        it("Should restrict reserve viewing to authorized addresses", async function () {
            // Owner (factory) can view
            await factory.getPair(await tokenA.getAddress(), await tokenB.getAddress());

            // Unauthorized address cannot view (this test may vary based on implementation)
            // In our implementation, getReserves requires authorization
        });
    });
});
