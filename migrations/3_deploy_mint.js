const AuraToken = artifacts.require("AuraToken");
const MintAura = artifacts.require("MintAura");

module.exports = function (deployer, network) {
    deployer.deploy(MintAura, AuraToken.address, 5);
};