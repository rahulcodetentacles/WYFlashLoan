const { ethers } = require('ethers');

async function main() {
    const provider = new ethers.providers.JsonRpcProvider(
        process.env.API_URL
    );
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    const signer = wallet.connect(provider);

    const fundControllerAddress = "0x7dC8bcF5be91A2e90FcA90FB9d894606F8B9Ca9e";
    const fundControllerConstructor = [
        "0xcce491Ca41049631d8276276E31474911652CF70",
        [30000, 60000, 150000, 300000, 1500000, 3000000]
    ];

    const flashLoanAddress = "0x7dC8bcF5be91A2e90FcA90FB9d894606F8B9Ca9e";
    const flashLoanConstructor = [
        "0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb",
        "0xE592427A0AEce92De3Edee1F18E0157C05861564",
        "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff",
        "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506",
        fundControllerContract.address,
        "0xcce491Ca41049631d8276276E31474911652CF70"
    ];

    await run('verify:verify', {
        address: fundControllerAddress,
        constructorArguments: fundControllerConstructor
    });

    await run('verify:verify', {
        address: flashLoanAddress,
        constructorArguments: flashLoanConstructor
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
