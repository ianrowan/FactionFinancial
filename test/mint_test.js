const AuraToken = artifacts.require("AuraToken");
const MintAura = artifacts.require("MintAura");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("mintTest", function (accounts) {
  
  it("Contracts are deployed", async function () {
    await MintAura.deployed();
    await AuraToken.deployed();
    return assert.isTrue(true);
  });

  it("Mint Contract is funded", async function () {
    let mintInst = await MintAura.deployed();
    let tokInst = await AuraToken.deployed();

    await tokInst.transfer(mintInst.address, 10000, {from: accounts[0]})
    assert.equal(await tokInst.balanceOf(mintInst.address), 10000)
  });

  it("Can Mint", async function (){
    let mintInst = await MintAura.deployed();
    let tokInst = await AuraToken.deployed();

    qty = 10;
    let contTokBal = await tokInst.balanceOf(mintInst.address)

    await mintInst.mint(qty, {from: accounts[1], value: qty * 5 * 1e17})

    let tokBalance = await tokInst.balanceOf(accounts[1])
    let contractBalance = await tokInst.balanceOf(mintInst.address)
    let contractEthBalance = await web3.eth.getBalance(mintInst.address)

    assert.equal(tokBalance, qty)
    assert.equal(contractBalance, contTokBal - qty)
    assert.equal(contractEthBalance, qty * 5 * 1e17)

  });

  it("Can't mint with insufficient funds", async function(){
    let mintInst = await MintAura.deployed();
    try {
      await mintInst.mint(5, {from: accounts[1], value: 5});
      assert(false)
    } catch (error) {
      assert(true)
    }
  });

  it("Does Change Exchange Rate", async function(){
    let mintInst = await MintAura.deployed();

    await mintInst.adjustExchangeRate(1, {from: accounts[0]})

    assert.ok(await mintInst.mint(5, {from: accounts[1], value:qty * 1 * 1e17 }))
  });  

  it("Can Withdraw funds", async function(){
    let mintInst = await MintAura.deployed();
    let contractEthBalance = await web3.eth.getBalance(mintInst.address)
    let accountBal = await web3.eth.getBalance(accounts[0])

    await mintInst.withdraw({from: accounts[0]})
    let contractEthBalance2 = await web3.eth.getBalance(mintInst.address)
    let accountBal2 = await web3.eth.getBalance(accounts[0])

    assert(contractEthBalance > contractEthBalance2)
    assert(accountBal2 > accountBal)

  });

  it("Can Withdraw tokens", async function(){
    let mintInst = await MintAura.deployed();
    let tokInst = await AuraToken.deployed();

    let conBal1 = await tokInst.balanceOf(mintInst.address)
    let acctBal1 = await tokInst.balanceOf(accounts[0])

    await mintInst.withdrawTokens(conBal1)

    let conBal2 = await tokInst.balanceOf(mintInst.address)
    let acctBal2 = await tokInst.balanceOf(accounts[0])

    assert.equal(conBal2, 0)
    assert(acctBal2 >= conBal1 + acctBal1)
  })

  it("Can't mint on empty", async function(){
    let mintInst = await MintAura.deployed();

    try {
      await mintInst.mint(2, {from: accounts[1], valeu: 2*1*1e17})
      assert(false)
    } catch (error) {
      assert(true)
    }
  });

})
