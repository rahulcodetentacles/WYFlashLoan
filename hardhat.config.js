/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require('@nomiclabs/hardhat-ethers');
// require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();
require("@nomicfoundation/hardhat-toolbox");
// require("@nomicfoundation/hardhat-verify");


module.exports = {
  solidity: {
    compilers: [
      { version: "0.8.10" },
      { version: "0.8.20" },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    polygon: {
      url: process.env.API_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
    polygonMumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/6AHnfnUbxy7QfRdCh2e6CuxRy_egXPMP",
      accounts: ["cdf6a858b71520aedaf50442a761af94a516a3d0e36f2b5b6c9bcf0bfbe45820"]
    },
    ftmTestnet: {
      url: "https://rpc.testnet.fantom.network/",
      accounts: [
        "cdf6a858b71520aedaf50442a761af94a516a3d0e36f2b5b6c9bcf0bfbe45820",//0x703632A0b52244fAbca04aaE138fA8EcaF72dCBC
      ],
      gas: "auto"
    },
    bscTestnet: {
      url: "https://bsc-testnet.publicnode.com",
      accounts: [
        "cdf6a858b71520aedaf50442a761af94a516a3d0e36f2b5b6c9bcf0bfbe45820",//0x703632A0b52244fAbca04aaE138fA8EcaF72dCBC
      ],
      gas: "auto"
    },
    xdc_testnet: {
      url: "https://erpc.apothem.network",
      accounts: ["779047eedd52784ab20c5a4de80708e5d405bc30c16a28cd488940a595bcb62b"]
    },
    goerli: {
      url: `https://ethereum-goerli.publicnode.com`,
      accounts: [
        "cdf6a858b71520aedaf50442a761af94a516a3d0e36f2b5b6c9bcf0bfbe45820",//0x703632A0b52244fAbca04aaE138fA8EcaF72dCBC
      ],
      gas: "auto"
    },
    sepolia: {
      url: "https://ethereum-sepolia.blockpi.network/v1/rpc/public",
      accounts: ["8d3a4b28bf81f02bd772bd049db86422d675eb087edf8594c5808ea188fb982d"],//0x703632A0b52244fAbca04aaE138fA8EcaF72dCBC
      gas: "auto"
    },
    wyzthTest: {
      url: "https://rpc-testnet.wyzthchain.org/",
      accounts: ["cdf6a858b71520aedaf50442a761af94a516a3d0e36f2b5b6c9bcf0bfbe45820"]//0x703632A0b52244fAbca04aaE138fA8EcaF72dCBC
    },
    wyzthMainNet: {
      url: "https://rpc-mainnet.wyzthchain.org/",
      accounts: ["8d3a4b28bf81f02bd772bd049db86422d675eb087edf8594c5808ea188fb982d"]//0x703632A0b52244fAbca04aaE138fA8EcaF72dCBC
    },
    arbitrumGoerli: {
      url: "https://arbitrum-goerli.public.blastapi.io",
      accounts: ["cdf6a858b71520aedaf50442a761af94a516a3d0e36f2b5b6c9bcf0bfbe45820"]
    }
  },
  etherscan: {
    apiKey: {
      mainnet: "P8YXEUFFSMIIYAIPPW8YC8PI598XX4R7P7",
      ropsten: "P8YXEUFFSMIIYAIPPW8YC8PI598XX4R7P7",
      rinkeby: "P8YXEUFFSMIIYAIPPW8YC8PI598XX4R7P7",
      goerli: "P8YXEUFFSMIIYAIPPW8YC8PI598XX4R7P7",
      kovan: "P8YXEUFFSMIIYAIPPW8YC8PI598XX4R7P7",
      sepolia: "P8YXEUFFSMIIYAIPPW8YC8PI598XX4R7P7",
      // binance smart chain
      bsc: "6WT3TEA4JFJ4DG9PTCGGKHVRRY8DIJ1MYC",
      bscTestnet: "6WT3TEA4JFJ4DG9PTCGGKHVRRY8DIJ1MYC",
      polygonMumbai: "CTZ7FPH21A754TIR576BZJRRGM8YCCU19W",
      polygon: "P8YXEUFFSMIIYAIPPW8YC8PI598XX4R7P7",
      wyzthTest: "P8YXEUFFSMIIYAIPPW8YC8PI598XX4R7P7",
      wyzthMainNet: "P8YXEUFFSMIIYAIPPW8YC8PI598XX4R7P7",
      arbitrumGoerli: "YW21KJ2UA8WMA8VR4QHMUVE1F8W826UH2H",
      xdc_testnet: "YJG89ZWVH95XWGN46G66SWGSPK77XAVXTU",
      ftmTestnet: "3C1JYSYQJDQ3H3CD6RF9CRC8RUYT5J291E"
    },
    customChains: [
      {
        network: "wyzthTest",
        chainId: 309,
        urls: {
          apiURL: "http://24.199.108.65:4000/api",
          browserURL: "http://24.199.108.65:4000"
        }
      },
      {
        network: "wyzthMainNet",
        chainId: 303,
        urls: {
          apiURL: "https://wyzthscan.org/api",
          browserURL: "https://wyzthscan.org"
        }
      },
      {
        network: "xdc_testnet",
        chainId: 51,
        urls: {
          // apiURL: "https://apothem.blocksscan.io/api",
          browserURL: "https://explorer.apothem.network/"
        }
      }
    ]
  }
};
