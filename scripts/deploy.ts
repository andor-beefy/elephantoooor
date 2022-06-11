import { ethers } from "hardhat"

async function main() {
    const signer = await ethers.getSigners()
    const optimizerContractFactory = await ethers.getContractFactory(
        "Optimizer",
        signer[0]
    )
    const aavePoolAddressesProvider =
        "0xBA6378f1c1D046e9EB0F538560BA7558546edF3C"
    const uniswapRouterAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564"

    const optimizerContract = await optimizerContractFactory.deploy(
        aavePoolAddressesProvider,
        ethers.utils.parseUnits("100"),
        ethers.utils.parseUnits("500"),
        uniswapRouterAddress
    )

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
