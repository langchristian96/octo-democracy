pragma solidity ^0.4.24;
contract OctoDemocracy {
    struct Proposal {
        string description;
        uint voteCount;
    }

    struct Voter {
        bool isAllowedToVote;
        bool hasVoted;
        uint votedProposalIndex;
    }

    enum OctoStatus {
        OwnerRegisteringVoters,
        ProposalRegistrationStart,
        ProposalRegistrationEnd,
        VotingStart,
        VotingEnd,
        VotesTallied
    }

    event VoterRegisteredEvent(address registeredVoter);
    event ProposalRegistrationStartedEvent();
    event ProposalRegisteredEvent(uint proposalIndex);
    event ProposalRegistrationEndedEvent();
    event VotingStartedEvent();
    event VotedEvent(address voter, uint proposalIndex);
    event VotingEndedEvent();
    event VotesTalliedEvent();

    event OctoStatusChangedEvent(OctoStatus previousStatus, OctoStatus newStatus);

    address public owner;
    OctoStatus public currentVotingStatus;
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    uint private winningProposalIndex;     //should only be exposed after votes are tallied

    constructor() public {
        owner = msg.sender;
        currentVotingStatus = OctoStatus.OwnerRegisteringVoters;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller of this function must be contract owner");
        _;      //merge wildcard; merge function code with modifier code
    }

    modifier onlyAllowedVoter() {
        require(voters[msg.sender].isAllowedToVote, "caller of this function must be allowed to vote");
        _;
    }

    modifier onlyDuringVotersRegistering() {
        require(currentVotingStatus == OctoStatus.OwnerRegisteringVoters, "function can be called only during voters registering");
        _;
    }

    modifier onlyDuringProposalRegistering() {
        require(currentVotingStatus == OctoStatus.ProposalRegistrationStart, "function can be called only during proposal registering");
        _;
    }
    
    modifier onlyDuringVotingTime() {
        require(currentVotingStatus == OctoStatus.VotingStart, "function can be called only after voting has started");
        _;
    }

     modifier onlyAfterVotesAreTallied() {
         require(currentVotingStatus == OctoStatus.VotesTallied, "function can be called only after votes are tallied");
         _;
     }

    function registerVoter(address _voterAddress) public onlyOwner onlyDuringVotersRegistering {
        require(!voters[_voterAddress].isAllowedToVote, "this voter was already registered for voting");
        voters[_voterAddress].isAllowedToVote = true;
        voters[_voterAddress].hasVoted = false;
        voters[_voterAddress].votedProposalIndex = 0;

        emit VoterRegisteredEvent(_voterAddress);
    }

    function startProposalRegistration() public onlyOwner onlyDuringVotersRegistering {
        currentVotingStatus = OctoStatus.ProposalRegistrationStart;
        emit ProposalRegistrationStartedEvent();
        emit OctoStatusChangedEvent(OctoStatus.OwnerRegisteringVoters, currentVotingStatus);
    }

    function registerProposal(string proposalDescription) public onlyAllowedVoter onlyDuringProposalRegistering {
        proposals.push(Proposal({
            description: proposalDescription,
            voteCount: 0 
        }));

        emit ProposalRegisteredEvent(proposals.length - 1);
    }

    function endProposalRegistration() public onlyOwner onlyDuringProposalRegistering {
        currentVotingStatus = OctoStatus.ProposalRegistrationEnd;
        emit ProposalRegistrationEndedEvent();
        emit OctoStatusChangedEvent(OctoStatus.ProposalRegistrationStart, currentVotingStatus);
    }

    function startVoting() public onlyOwner {
        require(currentVotingStatus == OctoStatus.ProposalRegistrationEnd, "function can only be called after proposal stage has ended");
        currentVotingStatus = OctoStatus.VotingStart;
        emit VotingStartedEvent();
        emit OctoStatusChangedEvent(OctoStatus.ProposalRegistrationEnd, currentVotingStatus);
    }

    function vote(uint proposalIndex) public onlyAllowedVoter onlyDuringVotingTime {
        require(!voters[msg.sender].hasVoted, "the caller has already voted");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalIndex = proposalIndex;
        proposals[proposalIndex].voteCount += 1;

        emit VotedEvent(msg.sender, proposalIndex);
    }

    function endVoting() public onlyOwner onlyDuringVotingTime {
        currentVotingStatus = OctoStatus.VotingEnd;
        emit VotingEndedEvent();
        emit OctoStatusChangedEvent(OctoStatus.VotingStart, currentVotingStatus);
    }

    function tallyVotes() public onlyOwner {
        require(currentVotingStatus == OctoStatus.VotingEnd, "function can only be called after voting has ended");
        uint maxVoteCount = 0;
        uint maxProposalIndex = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVoteCount) {
                maxVoteCount = proposals[i].voteCount;
                maxProposalIndex = i;
            }
        }

        winningProposalIndex = maxProposalIndex;
        currentVotingStatus = OctoStatus.VotesTallied;

        emit VotesTalliedEvent();
        emit OctoStatusChangedEvent(OctoStatus.VotingEnd, OctoStatus.VotesTallied);
    }

    function getProposalsNumber() public view returns (uint) {
        return proposals.length;
    }

    function getProposalDescription(uint index) public view returns (string) {
        require(index < proposals.length, "the requested proposal index does not exist");
        return proposals[index].description;
    }

    function getWinningProposalIndex() public view onlyAfterVotesAreTallied returns (uint) {
        return winningProposalIndex;
    }

    function getWinningProposalDescription() public view onlyAfterVotesAreTallied returns (string) {
        return proposals[winningProposalIndex].description;
    }

    function getWinningProposalVotes() public view onlyAfterVotesAreTallied returns (uint) {
        return proposals[winningProposalIndex].voteCount;
    }

    function isVoterAllowed(address _voterAddress) public view returns (bool) {
        return voters[_voterAddress].isAllowedToVote;
    }

    function isContractOwner(address _address) public view returns (bool) {
        return owner == _address;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getCurrentVotingStatus() public view returns (OctoStatus) {
        return currentVotingStatus;
    }
}