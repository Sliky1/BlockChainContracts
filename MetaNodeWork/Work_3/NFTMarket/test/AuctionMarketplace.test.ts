import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("🎨 NFT拍卖市场 - 简化测试", function () {
    let nft: any;
    let factory: any;
    let usdc: any;
    let owner: HardhatEthersSigner;
    let seller: HardhatEthersSigner;
    let bidder1: HardhatEthersSigner;
    let bidder2: HardhatEthersSigner;

    // 测试常量
    const STARTING_PRICE = ethers.parseEther("100"); // $100
    const RESERVE_PRICE = ethers.parseEther("500"); // $500
    const AUCTION_DURATION = 7 * 24 * 60 * 60; // 7天
    const PLATFORM_FEE = 250; // 2.5%
    const BID_AMOUNT = ethers.parseEther("2"); // 2 ETH

    beforeEach(async function () {
        [owner, seller, bidder1, bidder2] = await ethers.getSigners();

        // 部署NFT合约
        const AuctionNFT = await ethers.getContractFactory("AuctionNFT");
        nft = await upgrades.deployProxy(
            AuctionNFT,
            ["Test NFT", "TNFT"],
            { initializer: "initialize", kind: "uups" }
        );

        // 部署拍卖实现
        const Auction = await ethers.getContractFactory("Auction");
        const auctionImpl = await Auction.deploy();
        const auctionImplAddress = await auctionImpl.getAddress();

        // 部署工厂合约
        const AuctionFactory = await ethers.getContractFactory("AuctionFactory");
        factory = await upgrades.deployProxy(
            AuctionFactory,
            [auctionImplAddress, PLATFORM_FEE, owner.address],
            { initializer: "initialize", kind: "uups" }
        );

        // 部署测试代币
        const MockToken = await ethers.getContractFactory("MockToken");
        usdc = await MockToken.deploy("USDC", "USDC", 6, 1000000);

        // 配置支付代币
        await factory.addPaymentToken(
            await usdc.getAddress(),
            "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E", // Mock price feed
            6,
            "USDC"
        );

        // 分发代币
        await usdc.mint(bidder1.address, ethers.parseUnits("10000", 6));
        await usdc.mint(bidder2.address, ethers.parseUnits("10000", 6));
    });

    describe("📋 基础功能测试", function () {
        it("应该正确部署所有合约", async function () {
            expect(await nft.name()).to.equal("Test NFT");
            expect(await nft.symbol()).to.equal("TNFT");
            expect(await factory.platformFee()).to.equal(PLATFORM_FEE);
            expect(await usdc.name()).to.equal("USDC");
        });
    });

    describe("🎨 NFT功能测试", function () {
        it("应该能够铸造NFT", async function () {
            await nft.connect(seller).mintNFT(seller.address, "test-uri", 500);
            
            expect(await nft.ownerOf(1)).to.equal(seller.address);
            expect(await nft.tokenURI(1)).to.equal("test-uri");
            expect(await nft.creators(1)).to.equal(seller.address);
            expect(await nft.royalties(1)).to.equal(500);
        });

        it("应该能够设置版税", async function () {
            await nft.connect(seller).mintNFT(seller.address, "test-uri", 500);
            
            await nft.connect(seller).setRoyalty(1, 1000);
            expect(await nft.royalties(1)).to.equal(1000);
        });
    });

    describe("🏭 工厂功能测试", function () {
        beforeEach(async function () {
            await nft.connect(seller).mintNFT(seller.address, "test-uri", 500);
        });

        it("应该能够创建拍卖", async function () {
            await nft.connect(seller).approve(await factory.getAddress(), 1);
            
            await expect(
                factory.connect(seller).createAuction(
                    await nft.getAddress(), 1, STARTING_PRICE, RESERVE_PRICE, AUCTION_DURATION
                )
            ).to.emit(factory, "AuctionCreated");
            
            const auctionAddress = await factory.getAuction(await nft.getAddress(), 1);
            expect(auctionAddress).to.not.equal(ethers.ZeroAddress);
        });
    });

    describe("💰 基础拍卖功能测试", function () {
        let auction: any;
        
        beforeEach(async function () {
            await nft.connect(seller).mintNFT(seller.address, "test-uri", 500);
            await nft.connect(seller).approve(await factory.getAddress(), 1);
            await factory.connect(seller).createAuction(
                await nft.getAddress(), 1, STARTING_PRICE, RESERVE_PRICE, AUCTION_DURATION
            );
            
            const auctionAddress = await factory.getAuction(await nft.getAddress(), 1);
            auction = await ethers.getContractAt("Auction", auctionAddress);
        });

        it("应该能够用ETH出价", async function () {
            await expect(
                auction.connect(bidder1).bidWithETH({ value: BID_AMOUNT })
            ).to.emit(auction, "BidPlaced");
            
            const highestBid = await auction.highestBid();
            expect(highestBid.bidder).to.equal(bidder1.address);
            expect(highestBid.amount).to.equal(BID_AMOUNT);
        });

        it("应该能够结束拍卖", async function () {
            // 出价超过保留价
            const highBid = ethers.parseEther("4"); // > reserve price in USD
            await auction.connect(bidder1).bidWithETH({ value: highBid });
            
            // 快进到拍卖结束
            await ethers.provider.send("evm_increaseTime", [AUCTION_DURATION + 1]);
            await ethers.provider.send("evm_mine", []);
            
            await expect(auction.endAuction())
                .to.emit(auction, "AuctionEnded");
            
            // NFT应该转移给获胜者
            expect(await nft.ownerOf(1)).to.equal(bidder1.address);
        });
    });
});