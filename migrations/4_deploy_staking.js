const AuraToken = artifacts.require("AuraToken");
const AuraStaking = artifacts.require("AuraStaking");

module.exports = function (deployer, network) {
    deployer.deploy(AuraStaking, AuraToken.address, 1);
};