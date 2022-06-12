import { ethers } from "hardhat"
import { Optimizer } from "../typechain-types"

async function main() {
    const signer = await ethers.getSigners()
    const optimizerContractFactory = await ethers.getContractFactory(
        "Optimizer",
        signer[0]
    )
    const aavePoolAddressesProvider =
        "0xBA6378f1c1D046e9EB0F538560BA7558546edF3C"
    const uniswapRouterAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564"

    const optimizerContract = (await optimizerContractFactory.deploy(
        aavePoolAddressesProvider,
        "100",
        "500",
        uniswapRouterAddress
    )) as Optimizer

    // optimizerContract.redeem("0x4aAded56bd7c69861E8654719195fCA9C670EB45", [
    //     {
    //         tokenAddress: "0x4aAded56bd7c69861E8654719195fCA9C670EB45",
    //         amount: ethers.utils.parseUnits("1000"),
    //     },
    // ])

    console.log("Deployed Address:", optimizerContract.address)
}

main()
    .then(() => {
        process.exit(0)
    })
    .catch((err) => {
        console.error(err)
        process.exit(1)
    })
