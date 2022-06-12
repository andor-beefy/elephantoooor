import hre from "hardhat"

export async function verifyContract() {
    try {
        await hre.run("verify:verify", {
            address: "0x8D8E30853935aC0A07ed480067E10AEA53769486",
            constructorArguments: [
                "0xBA6378f1c1D046e9EB0F538560BA7558546edF3C",
                "100",
                "500",
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
