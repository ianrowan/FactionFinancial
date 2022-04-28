const AuraToken = artifacts.require("AuraToken");
const MintAura = artifacts.require("MintAura");

module.exports = function (accounts) {

    accounts.then(async function(accounts){
        const tokenIntance = await AuraToken.deployed();

        await tokenIntance.transfer(MintAura.address, 10000, {from:accounts[0]});
    })
    
};