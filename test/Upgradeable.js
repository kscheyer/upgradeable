const { BN, constants, expectEvent, shouldFail } = require('openzeppelin-test-helpers');

const Example = artifacts.require('Example')
const Example2 = artifacts.require('Example2')
const Proxy = artifacts.require('Proxy')
const Resolver = artifacts.require("Resolver")



contract('Upgradeable', function (accounts) {
    const owner = accounts[0]
    const another = accounts[1]

    let exampleStorage
    let exampleStorage2
    let proxy
    let resolver
    let exampleProxy
    let exampleProxy2


    it('deploy contracts', async function () {
        exampleStorage = await Example.new()
        exampleStorage2 = await Example2.new()
        proxy = await Proxy.new(exampleStorage.address)
        exampleProxy = await Example.at(proxy.address)
        exampleProxy2 = await Example2.at(proxy.address)

        console.log("example 1 address ", exampleStorage.address)
        console.log("example 2 address", exampleStorage2.address)
    });

    it('initialize resolver and check variables set properly', async function() {
        resolver = await Resolver.at(await proxy._resolver())
        console.log("resolver is ", resolver.address)
        assert.equal(await resolver.owner(), owner)
    })


    it('Set highest hash in example 1', async function () {
        await exampleProxy.setHighestHash('test', {from: another})
        // Nonce not available in current implementation
        await shouldFail.reverting(exampleProxy2.nonce())
    })

    it('Upgrade to example2', async function () {
        // Upgrade to implementation 2, default version for user is set to 2
        await proxy.upgrade(exampleStorage2.address)
        assert.equal(exampleStorage2.address, await resolver.getUserVersion(another))
        assert.equal(exampleStorage2.address, await proxy._implementation())

        assert.equal(true, await exampleProxy2.isHighest('test23'))
        await exampleProxy2.setHighestHash('test23')
        //
        // // Nonce is now available
        assert.equal(await exampleProxy2.nonce(), 1);
        assert.equal(await exampleProxy2.highestHash(), await exampleProxy2.getSha3('test23'));

    })

    it('set user version preference to example1', async function () {
        let thisUser = another;
        // set version preference to the first contract
        await resolver.setUserVersion(exampleStorage.address, {from: thisUser});
        // Another user is using the original example storage
        assert.equal(exampleStorage.address, await resolver.getUserVersion(thisUser));
        // ExampleStorage2 is still the default implementation
        assert.equal(exampleStorage2.address, await proxy._implementation());

        // Set new highest hash
        assert.equal(true, await exampleProxy.isHighest('testy'));
        await exampleProxy.setHighestHash('testy', {from: thisUser});
        assert.equal(await exampleProxy.getSha3('testy'), await exampleProxy.highestHash());

        // Nonce should still be 1 since this user is still using original implementation
        assert.equal(await exampleProxy2.nonce(), 1);
    });

})
