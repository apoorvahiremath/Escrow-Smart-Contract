const EscrowFactory = artifacts.require("EscrowFactory");
const Escrow = artifacts.require('Escrow');
module.exports = function (deployer) {
  deployer.deploy(EscrowFactory);
//   deployer.deploy(Escrow);
};
