const OctoDemocracy = artifacts.require("./OctoDemocracy.sol");

contract('OctoDemocracy', function(accounts) {
    contract('OctoDemocracy.endProposalRegistration - onlyOwner modifier', function(accounts) {
        it(" Only The voting contract owner should be able to end proposal registration session", async function() {
            let octoDemocracyInstance = await OctoDemocracy.deployed();
            let votingContractOwner = await octoDemocracyInstance.getOwner();
            let nonVotingOwner = web3.eth.accounts[1];

            try {
                await octoDemocracyInstance.endProposalRegistration({from: nonVotingOwner});
                assert.isTrue(false);
            } catch(e) {
                assert.isTrue(votingContractOwner != nonVotingOwner);
                assert.equal(e, "Error: VM Exception while processing transaction: revert caller of this function must be contract owner");
            }
        });
    });
    
    contract('OctoDemocracy.endProposalRegistration - onlyDuringProposalRegistering modifier', function(accounts) {
        it("The voting contract owner should be able to end proposal registration session only after it has started", async function() {
            let octoDemocracyInstance = await OctoDemocracy.deployed();
            let votingContractOwner = await octoDemocracyInstance.getOwner();

            try {
                await octoDemocracyInstance.endProposalRegistration({from: votingContractOwner});
                assert.isTrue(false);
            } catch(e) {
                assert.equal(e, "Error: VM Exception while processing transaction: revert function can be called only during proposal registering");
            }
        });
    });
    
    contract('OctoDemocracy.endProposalRegistration - success', function(accounts) {
        it("The voting contract owner should be able to end proposal registration session if the status is correct", async function() {
            let octoDemocracyInstance = await OctoDemocracy.deployed();
            let votingContractOwner = await octoDemocracyInstance.getOwner();

            await octoDemocracyInstance.startProposalRegistration({from: votingContractOwner});
            let currentStatus = await octoDemocracyInstance.getCurrentVotingStatus();
            assert.equal(currentStatus.valueOf(), 1, "Current status does not correspond to proposal registration started");

            await octoDemocracyInstance.endProposalRegistration({from: votingContractOwner});
            let newStatus = await octoDemocracyInstance.getCurrentVotingStatus();
            assert.equal(newStatus.valueOf(), 2, "Current status does not correspond to proposal registration ended");
            try {
                await octoDemocracyInstance.endProposalRegistration({from: votingContractOwner});
                assert.isTrue(false);
            } catch(e) {
                assert.equal(e, "Error: VM Exception while processing transaction: revert function can be called only during proposal registering");
            }
        });
    });
});