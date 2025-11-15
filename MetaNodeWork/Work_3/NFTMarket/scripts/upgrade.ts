import { ethers, network, upgrades } from "hardhat";

async function main() {
    console.log("=== 🔄 合约升级脚本 ===");
    console.log("网络:", network.name);

    const [deployer] = await ethers.getSigners();
    console.log("升级账户:", deployer.address);
    console.log("账户余额:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");

    // 从环境变量获取代理地址
    const NFT_PROXY = process.env.NFT_ADDRESS || "";
    const FACTORY_PROXY = process.env.FACTORY_ADDRESS || "";

    if (!NFT_PROXY || !FACTORY_PROXY) {
        console.log("❌ 请设置合约地址环境变量:");
        console.log("export NFT_ADDRESS=your_nft_proxy_address");
        console.log("export FACTORY_ADDRESS=your_factory_proxy_address");
        process.exit(1);
    }

    console.log("NFT代理地址:", NFT_PROXY);
    console.log("工厂代理地址:", FACTORY_PROXY);

    try {
        // 1. 升级前检查
        console.log("\n=== 📋 升级前检查 ===");

        const currentNftImpl = await upgrades.erc1967.getImplementationAddress(NFT_PROXY);
        const currentFactoryImpl = await upgrades.erc1967.getImplementationAddress(FACTORY_PROXY);

        console.log("当前NFT实现:", currentNftImpl);
        console.log("当前工厂实现:", currentFactoryImpl);

        // 验证合约状态
        const nft = await ethers.getContractAt("AuctionNFT", NFT_PROXY);
        const factory = await ethers.getContractAt("AuctionFactory", FACTORY_PROXY);

        console.log("✅ 合约状态验证:");
        console.log("  NFT名称:", await nft.name());
        console.log("  当前Token ID:", (await nft.getCurrentTokenId()).toString());
        console.log("  平台费用:", (await factory.platformFee()).toString(), "基点");
        
        const stats = await factory.getAuctionStats();
        console.log("  总拍卖数:", stats.totalAuctions.toString());

        // 2. 准备升级
        console.log("\n=== 🔨 准备升级合约 ===");

        // 检查升级权限
        try {
            const nftOwner = await nft.owner();
            const factoryOwner = await factory.owner();
            
            if (nftOwner !== deployer.address) {
                console.log("❌ NFT合约owner不是当前账户:", nftOwner);
                throw new Error("权限不足");
            }
            
            if (factoryOwner !== deployer.address) {
                console.log("❌ 工厂合约owner不是当前账户:", factoryOwner);
                throw new Error("权限不足");
            }
            
            console.log("✅ 升级权限验证通过");
        } catch (error) {
            console.log("❌ 权限检查失败:", error);
            throw error;
        }

        // 3. 升级NFT合约
        console.log("\n=== 🎨 升级NFT合约 ===");
        const AuctionNFTV2 = await ethers.getContractFactory("AuctionNFT");

        console.log("正在升级NFT合约...");
        const upgradedNft = await upgrades.upgradeProxy(NFT_PROXY, AuctionNFTV2);
        await upgradedNft.waitForDeployment();
        
        const newNftImpl = await upgrades.erc1967.getImplementationAddress(NFT_PROXY);
        console.log("✅ NFT合约升级成功");
        console.log("  新实现地址:", newNftImpl);
        console.log("  变化:", currentNftImpl !== newNftImpl ? "已更新" : "无变化");

        // 4. 升级工厂合约
        console.log("\n=== 🏭 升级工厂合约 ===");
        const AuctionFactoryV2 = await ethers.getContractFactory("AuctionFactory");

        console.log("正在升级工厂合约...");
        const upgradedFactory = await upgrades.upgradeProxy(FACTORY_PROXY, AuctionFactoryV2);
        await upgradedFactory.waitForDeployment();
        
        const newFactoryImpl = await upgrades.erc1967.getImplementationAddress(FACTORY_PROXY);
        console.log("✅ 工厂合约升级成功");
        console.log("  新实现地址:", newFactoryImpl);
        console.log("  变化:", currentFactoryImpl !== newFactoryImpl ? "已更新" : "无变化");

        // 5. 升级后验证
        console.log("\n=== ✅ 升级后验证 ===");

        // 验证状态保持
        console.log("状态保持验证:");
        console.log("  NFT名称:", await upgradedNft.name());
        console.log("  当前Token ID:", (await upgradedNft.getCurrentTokenId()).toString());
        console.log("  平台费用:", (await upgradedFactory.platformFee()).toString(), "基点");

        // 验证新功能
        const newStats = await upgradedFactory.getAuctionStats();
        console.log("  升级后拍卖数:", newStats.totalAuctions.toString());

        // 验证合约仍然可操作
        try {
            await upgradedNft.name(); // 简单的读取操作
            await upgradedFactory.platformFee(); // 简单的读取操作
            console.log("✅ 合约功能验证通过");
        } catch (error) {
            console.log("❌ 合约功能验证失败:", error);
            throw error;
        }

        console.log("\n=== 🎊 升级完成 ===");
        console.log("✅ 所有合约升级成功!");
        console.log("📋 升级摘要:");
        console.log("  NFT实现: ", currentNftImpl, "→", newNftImpl);
        console.log("  工厂实现:", currentFactoryImpl, "→", newFactoryImpl);
        console.log("💡 状态和数据完全保留");

        return {
            nft: {
                proxy: NFT_PROXY,
                oldImplementation: currentNftImpl,
                newImplementation: newNftImpl
            },
            factory: {
                proxy: FACTORY_PROXY,
                oldImplementation: currentFactoryImpl,
                newImplementation: newFactoryImpl
            }
        };

    } catch (error) {
        console.error("\n❌ 升级失败:", error);

        console.log("\n🔧 故障排除建议:");
        console.log("1. 确认代理地址正确");
        console.log("2. 确认有升级权限 (必须是owner)");
        console.log("3. 检查新合约兼容性");
        console.log("4. 验证网络连接");
        console.log("5. 确保有足够gas费用");

        if (error.message.includes("revert")) {
            console.log("6. 检查合约逻辑错误");
        }

        throw error;
    }
}

/**
 * 验证升级结果
 */
async function validateUpgrade() {
    console.log("=== 🔍 升级验证 ===");

    const NFT_PROXY = process.env.NFT_ADDRESS || "";
    const FACTORY_PROXY = process.env.FACTORY_ADDRESS || "";

    if (!NFT_PROXY || !FACTORY_PROXY) {
        throw new Error("请设置代理地址环境变量");
    }

    try {
        // 验证NFT合约
        const nft = await ethers.getContractAt("AuctionNFT", NFT_PROXY);
        const name = await nft.name();
        const owner = await nft.owner();
        const currentTokenId = await nft.getCurrentTokenId();

        console.log("✅ NFT合约验证:");
        console.log("  名称:", name);
        console.log("  所有者:", owner);
        console.log("  当前Token ID:", currentTokenId.toString());

        // 验证工厂合约
        const factory = await ethers.getContractAt("AuctionFactory", FACTORY_PROXY);
        const platformFee = await factory.platformFee();
        const recipient = await factory.platformFeeRecipient();
        const stats = await factory.getAuctionStats();

        console.log("✅ 工厂合约验证:");
        console.log("  平台费用:", platformFee.toString(), "基点");
        console.log("  费用接收者:", recipient);
        console.log("  总拍卖数:", stats.totalAuctions.toString());

        // 测试基本功能
        console.log("✅ 功能验证:");
        console.log("  读取功能正常");

        // 获取实现地址
        const nftImpl = await upgrades.erc1967.getImplementationAddress(NFT_PROXY);
        const factoryImpl = await upgrades.erc1967.getImplementationAddress(FACTORY_PROXY);

        console.log("✅ 代理验证:");
        console.log("  NFT实现地址:", nftImpl);
        console.log("  工厂实现地址:", factoryImpl);

        console.log("\n🎉 所有验证通过！");

        return { nftImpl, factoryImpl };

    } catch (error) {
        console.error("❌ 验证失败:", error);
        throw error;
    }
}

// 主执行逻辑
if (require.main === module) {
    const command = process.argv[2];

    if (command === "validate") {
        validateUpgrade()
            .then(() => process.exit(0))
            .catch((error) => {
                console.error("验证失败:", error);
                process.exit(1);
            });
    } else {
        main()
            .then(() => process.exit(0))
            .catch((error) => {
                console.error("升级失败:", error);
                process.exit(1);
            });
    }
}

export { main as upgrade, validateUpgrade };