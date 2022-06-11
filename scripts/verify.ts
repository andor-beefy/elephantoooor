import hre from "hardhat"

export async function verifyContract() {
    try {
        await hre.run("verify:verify", {
            address: "0x5390196F105F2f405169b19bd3C3135220A076C1",
            constructorArguments: [
                "0xBA6378f1c1D046e9EB0F538560BA7558546edF3C",
                "100000000000000000000",
                "500000000000000000000",
                "0xE592427A0AEce92De3Edee1F18E0157C05861564",
            ],
        })
    } catch (err) {
        console.error(err)
    }
}

verifyContract()
    .then(() => {
        console.log("gm")
        process.exit(0)
    })
    .catch((x) => {
        console.error(x)
        process.exit(1)
    })
