## Priming step
- 1.empty [.env] CONTRACT_ADDRESS
- 2.Voting terminal ：npx hardhat run --network volta scripts/deploy.js
- 3.copy Generate Address to [.env] CONTRACT_ADDRESS
- 4.copy Generate Address to [constant.js] contractAddress
- 5.react-app terminal: npm start

---
Before starting this app, run

## npm install
Update the smart contract address and abi in Healthcare.js file.

To run the project, go to terminal and type

## npm start
Open http://localhost:3000 to view it in your browser.

---
## Next Optimization Direction
1.投票Tickets
    前端Form  提交[标题、时间、候选人] ==> constract 
    优化[deploy.js] 存储提交的信息，形成Tickets

2.美化界面
    Tickets界面
    Admin界面