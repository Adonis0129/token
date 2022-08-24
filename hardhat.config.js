require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-defender');
require("@openzeppelin/hardhat-upgrades");
require("hardhat-interface-generator");
require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const accounts = process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [];

module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.4.25",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 10,
                    },
                },
            },
            {
                version: "0.8.4",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 10,
                    },
                },
            },
            {
                version: "0.8.2",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 10,
                    },
                },
            },
            {
                version: "0.6.6",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 10,
                    },
                },
            },
        ],
    },
    defaultNetwork: "testnet",
    networks: {
        testnet: {
            url: process.env.TESTNET_RPC_URL || '',
            accounts: accounts,
            gasMultiplier: 3,
            timeout: 600000,
        },
        mainnet: {
            url: process.env.MAINNET_RPC_URL || '',
            accounts: accounts,
            gasMultiplier: 3,
            timeout: 60000,
        },
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY || '',
    },
    gasReporter: {
        enabled: true,
        currency: 'USD',
        gasPrice: 21,
        coinmarketcap: process.env.COINMARKETCAP_API_KEY || '',
    },
    defender: {
        apiKey: process.env.DEFENDER_API_KEY || '',
        apiSecret: process.env.DEFENDER_API_SECRET || '',
    },
};
