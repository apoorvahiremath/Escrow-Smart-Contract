const {assert} = require('chai');
require('chai').use(require('chai-as-promised')).should();

const EscrowFactory = artifacts.require('EscrowFactory');

contract('EscrowFactory', ([owner, buyer, seller])=>{
    let factory;
    before(async()=>{
        factory = await EscrowFactory.deployed()
    })

    describe('Factory deployment', async()=>{
        it('address', async()=>{
            assert.notEqual(factory.address, 0x0);
            assert.notEqual(factory.address, null);
            assert.notEqual(factory.address, undefined);
            assert.notEqual(factory.address, '');

        })
    })
});