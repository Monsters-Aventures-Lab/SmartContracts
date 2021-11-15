// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Dependencies/math/SafeMath.sol";

// This is a Crowfunding contract for Monster Adventure Game

contract CrowfundingMonster {
    using SafeMath for uint256;

    // Data structures
    enum State {
        Ready,
        Fundraising,
        Expired,
        Successful
    }
    struct ContributionItem {
        address contributor;
        uint256 contribution;
        string NFTUrl;
        uint256 tokenAmount;
    }
    
    // State variables
    uint256 public currentBalance;
    address payable public creator;
    uint256 startingTime = 1637006280; // 1637006280 Unix time for GMT Mon Nov 15 2021 19:58:00 GMT+0000
    uint256 deadline;
    uint256 goal;
    uint256 minContribution = 200 wei;
    uint256 maxContribution = 10 ether;
    uint256 convertionRate = 1;
    State public state = State.Ready;
    int256 public contributorsCount = 0;
    address[] contributors;
    mapping (address => uint256) public contributions;
    mapping (address => string) public NFTUrl;
    mapping (address => uint256) public contributionTimestamp;
    mapping (address => bool) public whitelist;

    // Event that will be emitted whenever funding will be received
    event FundingReceived(address contributor, uint256 amount, uint256 currentTotal, uint256 timestamp);

    // Modifier to check current state
    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    // Modifier to check current state
    modifier inWhitelist(address _wallet) {
        require(whitelist[_wallet]);
        _;
    }

    // Modifier to check if the function caller is the project creator
    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    constructor(uint256 numberOfDays, uint256 _goal) {
        creator = payable(msg.sender);
        deadline = startingTime + (numberOfDays * 1 days);
        goal = _goal;
        return;
    }
    
    function setCreator(address payable _creator) external isCreator {
        creator = _creator;
    }

    function getConvertionRate() external view returns (uint256) {
        return convertionRate;
    }

    function setConvertionRate(uint256 _convertionRate) external isCreator {
        convertionRate = _convertionRate;
    }

    function getNFTUrl(address _wallet) external view returns (string memory) {
        return NFTUrl[_wallet];
    }
    
    function setNFTUrl(address _wallet, string memory url) external isCreator { // OJO Internal
        NFTUrl[_wallet] = url;
    }

    function getStartingTime() external view returns (uint256) {
        return startingTime;
    }

    function getDeadline() external view returns (uint256) {
        return deadline;
    }
    
    function setStartingTime(uint256 _startingTime) external isCreator {
        startingTime = _startingTime;
    }

    function setDeadline(uint256 _deadline) external isCreator {
        deadline = _deadline;
    }
    
    function setMaxContribution(uint256 _maxContribution) external isCreator {
        maxContribution = _maxContribution;
    }

    function setMinContribution(uint256 _minContribution) external isCreator {
        minContribution = _minContribution;
    }

    function batchWhitelist(address[] memory _users) public isCreator {
        uint256 size = _users.length;

        for (uint256 i = 0; i < size; i++) {
            address user = _users[i];
            whitelist[user] = true;
        }
    }

    function contribute(uint256 amount) external inState(State.Fundraising) inWhitelist(msg.sender) payable {
        require(msg.sender != creator, "You can't contribute to your own project");
        require(msg.value == amount, "You can't contribute with a different amount");
        require(msg.value > minContribution, "You can't contribute with less than 0.2 BNB");
        require(msg.value < maxContribution, "You can't contribute with more than 10 BNB");
        if ((block.timestamp > startingTime) && (block.timestamp < deadline)) { 
            state = State.Fundraising;
        }
        require(isCrowfundingStarted(), "You can't contribute until crowfunding is started");
        require(block.timestamp < deadline, "Project has expired");
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        contributionTimestamp[msg.sender] = block.timestamp;
        currentBalance = currentBalance.add(msg.value);
        payable(msg.sender).transfer(creator.balance);
        emit FundingReceived(msg.sender, msg.value, currentBalance, contributionTimestamp[msg.sender]);
        addContributor(msg.sender);
        return;
    }

    function addContributor(address _wallet) public isCreator { // OJO Internal
        require(isNewContributor(_wallet), "This contributor is already in the list");
        contributors.push(_wallet);
        contributorsCount = contributorsCount + 1;
        return;
    }

    function isCrowfundingStarted() public view returns (bool) {
        if (state == State.Fundraising) {
            return true;
        }
        return false;
    }

    function startCrowdfunding() external isCreator inState(State.Ready) {
        state = State.Fundraising;
        return;
    }

    function setState(State _state) external isCreator {
        state = _state;
        return;
    }

    function isNewContributor(address _wallet) public view returns (bool) {
        uint256 size = contributors.length;

        for (uint256 i = 0; i < size; i++) {
            if (_wallet == contributors[i]) {
                return false;
            }
        }
        return true;
    }

    function fetchContributions() public view returns (ContributionItem[] memory) {
        uint256 size = contributors.length;
        ContributionItem[] memory items = new ContributionItem[](size);
        for (uint256 i = 0; i < size; i++) {
            address contributorAddress = contributors[i];
            items[i].contributor = contributorAddress;
            items[i].contribution = contributions[contributorAddress];
            items[i].NFTUrl = NFTUrl[contributorAddress];
            items[i].tokenAmount = contributions[contributorAddress] * convertionRate;
        }
        return items;
    }
}
