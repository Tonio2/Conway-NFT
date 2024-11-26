// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("TokenModule", (m) => {

  const token = m.contract("AnimatedSVGToken", ["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"], {});

  return { token };
});
