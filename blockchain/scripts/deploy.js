// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.

const path = require("path");

async function main() {
    // This is just a convenience check
    if (network.name === "hardhat") {
        console.warn(
            "You are trying to deploy a contract to the Hardhat Network, which" +
            "gets automatically created and destroyed every time. Use the Hardhat" +
            " option '--network localhost'"
        );
    }

    // ethers is available in the global scope
    const [deployer] = await ethers.getSigners();
    const address = await deployer.getAddress();
    console.log(
        "Deploying the contracts with the account:",
        address
    );

    const balance = await ethers.provider.getBalance(address);
    console.log("Account balance:", balance.toString());

    const Token = await ethers.getContractFactory("AnimatedSVGToken");

    const gasPrice = (await ethers.provider.getFeeData()).gasPrice;

    const deployTx = await Token.getDeployTransaction(address);
    const estimatedGas = await ethers.provider.estimateGas(deployTx);

    const deploymentCost = estimatedGas * gasPrice;

    if (balance < deploymentCost) {
        console.error("Not enough funds to deploy the contract");
        return;
    }

    const token = await Token.deploy(address);

    console.log("Token address:", token.target);

    // We also save the contract's artifacts and address in the frontend directory
    saveFrontendFiles(token);
}

function saveFrontendFiles(token) {
    const fs = require("fs");
    const contractsDir = path.join(__dirname, "../..", "dapp_conway", "src", "contracts");

    if (!fs.existsSync(contractsDir)) {
        fs.mkdirSync(contractsDir);
    }

    fs.writeFileSync(
        path.join(contractsDir, "address.json"),
        JSON.stringify({ Token: token.target }, undefined, 2)
    );

    const TokenArtifact = artifacts.readArtifactSync("AnimatedSVGToken");

    fs.writeFileSync(
        path.join(contractsDir, "Token.json"),
        JSON.stringify(TokenArtifact, null, 2)
    );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
