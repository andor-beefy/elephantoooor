import * as dotenv from "dotenv"
import { HardhatUserConfig } from "hardhat/types"

import "@nomiclabs/hardhat-waffle"
import "hardhat-gas-reporter"
import "@nomiclabs/hardhat-etherscan"
import "solidity-coverage"
import "hardhat-deploy"
import "hardhat-prettier"

dotenv.config()

const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL
const PRIVATE_KEY =
    process.env.PRIVATE_KEY ||
    "0x11ee3108a03081fe260ecdc106554d09d9d1209bcafd46942b10e02943effc4a"
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ""

const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
            // gasPrice: 130000000000,
        },
        rinkeby: {
            url: RINKEBY_RPC_URL,
            accounts: [PRIVATE_KEY],
            chainId: 4,
        },
    },
    solidity: {
        version: "0.8.10",
    },
    etherscan: {
    apiKey: { rinkeby: ETHERSCAN_API_KEY },
        customChains: [
          {
            network: "rinkeby",
            chainId: 4,
            urls: {
              apiURL: "https://api-rinkeby.etherscan.io/api",
              browserURL: "https://rinkeby.etherscan.io"
            }
          }
        ]
    },
    gasReporter: {
        enabled: true,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
    },
}

export default config
