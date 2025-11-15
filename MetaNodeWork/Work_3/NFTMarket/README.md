# NFT拍卖市场 - 最新版

一个基于最新Hardhat和OpenZeppelin框架的NFT拍卖市场，支持多币种支付、价格预言机和合约升级。

## ✨ 核心功能

- 🖼️ **NFT铸造** - ERC721标准，支持版税
- 🔨 **英式拍卖** - 价格递增，自动延时
- 💰 **多币种支付** - ETH + ERC20代币 
- 📊 **价格预言机** - Chainlink实时价格转换
- 🏭 **工厂模式** - 统一管理拍卖实例
- 🔄 **合约升级** - UUPS代理模式

## 🔧 技术栈

- **Solidity**: ^0.8.24
- **Hardhat**: ^2.26.1  
- **OpenZeppelin**: ^5.4.0
- **Chainlink**: ^1.3.0
- **TypeScript**: ^5.9.0

## 🚀 快速开始

### 1. 环境安装

```bash
# 克隆项目
git clone <repository-url>
cd nftmarket

# 安装依赖
npm install
```

### 2. 环境配置

创建 `.env` 文件:
```env
SEPOLIA_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### 3. 编译和测试

```bash
# 编译合约
npm run compile

# 运行测试
npm run test

# 查看测试覆盖率
npm run test:coverage
```

### 4. 部署

```bash
# 本地测试
npm run node          # 新终端
npm run deploy:local  # 部署到本地

# 测试网部署
npm run deploy:sepolia
```

### 5. 演示

```bash
# 修改demo.ts中的合约地址后运行
npm run demo
```

## 📁 项目结构

```
nftmarket/
├── contracts/              # 智能合约
│   ├── AuctionNFT.sol      # NFT合约 (最新版)
│   ├── Auction.sol         # 拍卖合约  
│   ├── AuctionFactory.sol  # 工厂合约
│   └── MockToken.sol       # 测试代币
├── scripts/                # 脚本
│   ├── deploy.ts           # 部署脚本 (更新版)
│   ├── upgrade.ts          # 升级脚本 (更新版)
│   └── demo.ts             # 演示脚本 (更新版)
├── test/                   # 测试
│   ├── AuctionMarketplace.test.ts  # 主测试 (更新版)
│   └── helpers.ts          # 测试工具 (更新版)
├── hardhat.config.ts       # 配置文件 (更新版)
└── package.json           # 项目配置 (最新版)
```