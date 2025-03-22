/**
* @type import('hardhat/config').HardhatUserConfig
*/

require('dotenv').config();
require("@nomiclabs/hardhat-ethers");

const { API_URL, PRIVATE_KEY } = process.env;

module.exports = {
  solidity: "0.8.28",
  defaultNetwork: "volta",
  networks: {
    hardhat: {},
    volta: {
      url: "https://volta-rpc.energyweb.org",
      accounts: [`0x${PRIVATE_KEY}`],
      gas: 210000000,
      gasPrice: 800000000000,
    }
  },
}