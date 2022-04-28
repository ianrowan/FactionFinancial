const AuraToken = artifacts.require("AuraToken");

module.exports = function (deployer, network) {
  deployer.deploy(AuraToken, "Faction Financial Aura", "AURA");
};