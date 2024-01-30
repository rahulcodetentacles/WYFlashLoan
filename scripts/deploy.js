const { ethers } = require('ethers');
const fs = require("fs");

const fundControllerJson = JSON.parse(fs.readFileSync("./artifacts/contracts/BoomerangFundController.sol/FarziFundControllerV2.json", "utf8"));
const fundControllerABI = fundControllerJson.abi;
const fundControllerBytecode = fundControllerJson.bytecode;

const flashLoanJson = JSON.parse(fs.readFileSync("./artifacts/contracts/BoomerangFlashLoanAuthority.sol/FarziFlashLoanAuthorityV2.json", "utf8"));
const flashLoanABI = flashLoanJson.abi;
const flashLoanBytecode = flashLoanJson.bytecode;

async function main() {
    const provider = new ethers.providers.JsonRpcProvider(
        process.env.API_URL
    );
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    const signer = wallet.connect(provider);
    console.log(`Deploying contracts with the account: ${signer.address}`);

    // Deploy the fund controller contract using the provided abi and bytecode
    const fundControllerFactory = new ethers.ContractFactory(fundControllerABI, fundControllerBytecode, signer);
    const fundControllerContract = await fundControllerFactory.deploy(
        "0xcce491Ca41049631d8276276E31474911652CF70",
        [30000, 60000, 150000, 300000, 1500000, 3000000]
    );

    await fundControllerContract.deployed();
    console.log('FundController Contract deployed to:', fundControllerContract.address);

    // Deploy the flash loan contract using the provided abi and bytecode
    const flashLoanFactory = new ethers.ContractFactory(flashLoanABI, flashLoanBytecode, signer);
    const flashLoanContract = await flashLoanFactory.deploy(
        "0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb",
        "0xE592427A0AEce92De3Edee1F18E0157C05861564",
        "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff",
        "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506",
        fundControllerContract.address,
        "0xcce491Ca41049631d8276276E31474911652CF70"
    );

    await flashLoanContract.deployed();
    console.log('FlashLoan Contract deployed to:', flashLoanContract.address);
}

// Run the deployment
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });