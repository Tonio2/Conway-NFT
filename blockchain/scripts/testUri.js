const decode = require("../utils/svg_decoder.js")

async function main() {
	const [owner] = await ethers.getSigners()

	const address = await owner.getAddress();

	const Token = await ethers.getContractFactory("AnimatedSVGToken");
	const token = await Token.deploy(address);


	const mintRet = await token.safeMint(address, 8, [16, 8, 56]);
	const tokenUri = await token.tokenURI(0);
	console.log(decode(tokenUri));
}


main().then(() => {}).catch((err) => {
	console.log(err);
});
