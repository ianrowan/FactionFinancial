const AuraStaking = artifacts.require("AuraStaking");
const AuraToken = artifacts.require("AuraToken");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("AuraStaking", function (accounts) {
  
  it("should assert true", async function () {
    await AuraStaking.deployed();
    return assert.isTrue(true);
  });

  it("Should be funded with rewards", async function(){
    let stake = await AuraStaking.deployed();
    let tok = await AuraToken.deployed();

    await tok.transfer(stake.address, 1000);

    assert.equal(await tok.balanceOf(stake.address), 1000);
  });

  it("Should be able to stake", async function(){
    let stake = await AuraStaking.deployed();
    let tok = await AuraToken.deployed();

    let stakeTot = 10;
    let userBal1 = await tok.balanceOf(accounts[0]);
    let contractBal1 = await tok.balanceOf(stake.address);

    await tok.approve(stake.address, stakeTot)

    await stake.stake(stakeTot);

    let userBal2 = await tok.balanceOf(accounts[0]);
    let contractBal2 = await tok.balanceOf(stake.address);


    assert.equal(userBal1 - stakeTot, userBal2)
    //assert.equal(contractBal1 + stakeTot, contractBal2)
  });

  it("Should get reward", async function(){
    let stake = await AuraStaking.deployed();
    let tok = await AuraToken.deployed();

    let userBal1 = await tok.balanceOf(accounts[0]);
    let contractBal1 = await tok.balanceOf(stake.address);
    await stake.adjustUserTimestamp(accounts[0], 1);
    await stake.getReward();

    let userBal2 = await tok.balanceOf(accounts[0]);
    let contractBal2 = await tok.balanceOf(stake.address);

    assert(userBal1 < userBal2)
    assert(contractBal1 > contractBal2)
  });
  
  
  it("Should be able to stake User 2", async function(){
    let stake = await AuraStaking.deployed();
    let tok = await AuraToken.deployed();

    await tok.transfer(accounts[1], 20);

    let stakeTot = 10;
    let userBal1 = await tok.balanceOf(accounts[1]);
    let contractBal1 = await tok.balanceOf(stake.address);

    await tok.approve(stake.address, stakeTot, {from: accounts[1]})

    await stake.stake(stakeTot, {from: accounts[1]});

    let userBal2 = await tok.balanceOf(accounts[1]);
    let contractBal2 = await tok.balanceOf(stake.address);


    assert.equal(userBal1 - stakeTot, userBal2)
    //assert.equal(contractBal1 + stakeTot, contractBal2)
  });

  it("Should get reward User 2", async function(){
    let stake = await AuraStaking.deployed();
    let tok = await AuraToken.deployed();

    let userBal1 = await tok.balanceOf(accounts[1]);
    let contractBal1 = await tok.balanceOf(stake.address);
    await stake.adjustUserTimestamp(accounts[0], 1);
    await stake.getReward({from: accounts[1]});

    let userBal2 = await tok.balanceOf(accounts[1]);
    let contractBal2 = await tok.balanceOf(stake.address);

    assert(userBal1 < userBal2)
    assert(contractBal1 > contractBal2)
  });

  it("Should withdraw", async function(){
    let stake = await AuraStaking.deployed();
    let tok = await AuraToken.deployed();

    let userBal1 = await stake.getStake(accounts[0]);
    let contractBal1 = await tok.balanceOf(stake.address);
    
    await stake.adjustUserTimestamp(accounts[0], 1);
    await stake.withdraw(userBal1);

    let userBal2 = await stake.getStake(accounts[0]);
    let contractBal2 = await tok.balanceOf(stake.address);

    assert(userBal1 > userBal2)
    assert(contractBal1 < contractBal2)
  });

});
