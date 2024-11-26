const { task, vars } = require("hardhat/config");
const decodeBase64 = require("./utils/svg_decoder");
require("@nomicfoundation/hardhat-toolbox");

const INFURA_API_KEY = vars.get("INFURA_API_KEY");
const SEPOLIA_PRIVATE_KEY = vars.get("SEPOLIA_PRIVATE_KEY");


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.8.27",
    networks: {
        sepolia: {
            url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
            accounts: [SEPOLIA_PRIVATE_KEY],
        },
    },
};

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const [owner] = await ethers.getSigners();

    console.log(owner.address);
});

task("balanceOf", "Get balance of user", async (taskArgs, hre) => {
    const [owner] = await ethers.getSigners();

    const token = await ethers.getContractAt("AnimatedSVGToken", "0x5fbdb2315678afecb367f032d93f642f64180aa3");
    const balance = await token.balanceOf(owner.address);

    console.log(balance);
});

task("mint", "Mints tokens to an address", async (taskArgs, hre) => {

    if (network.name === "hardhat") {
        console.warn(
            "You are running the faucet task with Hardhat network, which" +
            " gets automatically created and destroyed every time. Use the Hardhat" +
            " option '--network localhost'"
        );
    }
    const [owner] = await ethers.getSigners();

    const token = await ethers.getContractAt("AnimatedSVGToken", "0x5fbdb2315678afecb367f032d93f642f64180aa3");

    const tx = await token.safeMint(owner.address, 8, [255, 255, 255]);
    await tx.wait();

    console.log("Minted tokens to", owner.address);
    console.log("Transaction hash:", tx.hash);
});

task("tokenUri", "Prints the token URI of a token", async (taskArgs, hre) => {
    const token = await ethers.getContractAt("AnimatedSVGToken", "0x5FbDB2315678afecb367f032d93F642f64180aa3");

    const tokenUri = await token.tokenURI(0);

    console.log("Token URI of token 0 is", tokenUri);

    console.log("Decoding token URI...");
    console.log("Decoded token URI:", decodeBase64(tokenUri));
});

task("balance", "Prints the balance of an address", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    const Token = await hre.ethers.getContractFactory("AnimatedSVGToken");
    const token = Token.attach("0x5FbDB2315678afecb367f032d93F642f64180aa3");

    const balance = await token.balanceOf(accounts[0].address);

    console.log("Balance of", accounts[0].address, "is", balance.toString());
});
