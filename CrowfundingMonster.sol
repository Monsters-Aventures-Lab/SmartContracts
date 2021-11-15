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
    uint256 convertionRate;
    State public state = State.Ready;
    int256 public contributorsCount = 0;
    address[] contributors;
    mapping (address => uint256) public contributions;
    mapping (address => string) public NFTUrl;
    mapping (address => bool) public whitelist;

    // Event that will be emitted whenever funding will be received
    event FundingReceived(address contributor, uint amount, uint currentTotal ); // date

    // Modifier to check current state
    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    // Modifier to check current state
    modifier inWhitelist(address _wallet) { // Ready is the default state
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
        deadline = block.timestamp + (numberOfDays * 10 days);
        goal = _goal;
        return;
    }
    
    function setCreator(address payable _creator) external isCreator {
        creator = _creator;
    }

    function setConvertionRate(uint256 _convertionRate) external isCreator {
        convertionRate = _convertionRate;
    }

    function setStartingTime(uint256 _startingTime) external isCreator {
        startingTime = _startingTime;
    }

    function setDeadline(uint256 _deadline) external isCreator {
        deadline = _deadline;
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
        currentBalance = currentBalance.add(msg.value);
        payable(msg.sender).transfer(creator.balance);
        emit FundingReceived(msg.sender, msg.value, currentBalance);
        addContributor(msg.sender);
        return;
    }

    function isCrowfundingStarted() public view returns (bool) {
        if (state == State.Fundraising) {
            return true;
        }
        return false;
    }

    function startCrowdfunding() external isCreator inState(State.Fundraising) {
        state = State.Fundraising;
        return;
    }

    function setState(State _state) external isCreator {
        state = _state;
        return;
    }
    function addContributor(address _wallet) public isCreator {
        require(isNewContributor(_wallet), "This contributor is already in the list");
        contributors.push(_wallet);
        contributorsCount = contributorsCount + 1;
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
