import { ethers, upgrades, network } from "hardhat";

async function main() {
    console.log("=== 🚀 简化部署脚本 ===");
    console.log("网络:", network.name);
    
    try {
        const [deployer] = await ethers.getSigners();
        console.log("部署账户:", deployer.address);
        
        // 检查账户余额
        const balance = await ethers.provider.getBalance(deployer.address);
        console.log("账户余额:", ethers.formatEther(balance), "ETH");
        
        if (balance === 0n) {
            console.log("❌ 账户余额为0，请确保本地节点正在运行");
            return;
        }

        console.log("\n1. 部署NFT合约...");
        const AuctionNFT = await ethers.getContractFactory("AuctionNFT");
        const nft = await upgrades.deployProxy(
            AuctionNFT,
            ["Auction NFT", "ANFT"],
            { 
                initializer: "initialize", 
                kind: "uups",
                timeout: 60000
            }
        );
        await nft.waitForDeployment();
        const nftAddress = await nft.getAddress();
        console.log("✅ NFT合约:", nftAddress);

        console.log("\n2. 部署拍卖实现...");
        const Auction = await ethers.getContractFactory("Auction");
        const auctionImpl = await Auction.deploy();
        await auctionImpl.waitForDeployment();
        const auctionImplAddress = await auctionImpl.getAddress();
        console.log("✅ 拍卖实现:", auctionImplAddress);

        console.log("\n3. 部署工厂合约...");
        const AuctionFactory = await ethers.getContractFactory("AuctionFactory");
        const factory = await upgrades.deployProxy(
            AuctionFactory,
            [auctionImplAddress, 250, deployer.address],
            { 
                initializer: "initialize", 
                kind: "uups",
                timeout: 60000
            }
        );
        await factory.waitForDeployment();
        const factoryAddress = await factory.getAddress();
        console.log("✅ 工厂合约:", factoryAddress);

        console.log("\n4. 部署测试代币...");
        const MockToken = await ethers.getContractFactory("MockToken");
        
        const usdc = await MockToken.deploy("USD Coin", "USDC", 6, 1000000);
        await usdc.waitForDeployment();
        const usdcAddress = await usdc.getAddress();
        console.log("✅ USDC:", usdcAddress);

        const dai = await MockToken.deploy("Dai Stablecoin", "DAI", 18, 1000000);
        await dai.waitForDeployment();
        const daiAddress = await dai.getAddress();
        console.log("✅ DAI:", daiAddress);

        console.log("\n5. 配置支付代币...");
        // 添加USDC
        await factory.addPaymentToken(
            usdcAddress,
            "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E", // Mock price feed
            6,
            "USDC"
        );
        console.log("✅ USDC已配置");

        // 添加DAI
        await factory.addPaymentToken(
            daiAddress,
            "0x14866185B1962B63C3Ea9E03Bc1da838bab34C19", // Mock price feed
            18,
            "DAI"
        );
        console.log("✅ DAI已配置");

        console.log("\n=== 🎉 部署完成 ===");
        console.log("📋 合约地址汇总:");
        console.log("NFT合约     :", nftAddress);
        console.log("工厂合约    :", factoryAddress);
        console.log("拍卖实现    :", auctionImplAddress);
        console.log("USDC代币    :", usdcAddress);
        console.log("DAI代币     :", daiAddress);

        console.log("\n📝 环境变量设置:");
        console.log(`export NFT_ADDRESS=${nftAddress}`);
        console.log(`export FACTORY_ADDRESS=${factoryAddress}`);
        console.log(`export USDC_ADDRESS=${usdcAddress}`);
        console.log(`export DAI_ADDRESS=${daiAddress}`);

        console.log("\n🎮 下一步操作:");
        console.log("npm run demo");

        return {
            nft: nftAddress,
            factory: factoryAddress,
            auctionImplementation: auctionImplAddress,
            usdc: usdcAddress,
            dai: daiAddress
        };

    } catch (error) {
        console.error("\n❌ 部署失败:", error);
        
        console.log("\n🔧 故障排除:");
        console.log("1. 确保本地节点正在运行: npm run node");
        console.log("2. 检查网络连接");
        console.log("3. 重新编译: npm run compile");
        console.log("4. 清理缓存: npx hardhat clean");
        
        throw error;
    }
}

if (require.main === module) {
    main()
        .then(() => process.exit(0))
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}

export { main as deploySimple };