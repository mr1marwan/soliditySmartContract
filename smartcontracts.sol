//Example 1: Simple Crowdfunding Contract
//This contract allows users to create crowdfunding campaigns and contribute to them.
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract SimpleCrowdfunding {
    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 goal;
        uint256 pledged;
        bool completed;
        address[] contributors;
        mapping(address => uint256) contributions;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner, uint256 goal);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalPledged);

    // Function to create a new campaign
    function createCampaign(string memory _title, string memory _description, uint256 _goal) public {
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.owner = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.pledged = 0;
        newCampaign.completed = false;

        emit CampaignCreated(campaignCount, _title, msg.sender, _goal);
    }

    // Function to contribute to a campaign
    function contribute(uint256 _campaignId) public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");

        campaign.pledged += msg.value;
        campaign.contributors.push(msg.sender);
        campaign.contributions[msg.sender] += msg.value;

        if (campaign.pledged >= campaign.goal) {
            campaign.completed = true;
            campaign.owner.transfer(campaign.pledged);
            emit CampaignCompleted(_campaignId, campaign.pledged);
        } else {
            emit ContributionMade(_campaignId, msg.sender, msg.value);
        }
    }

    // Function to get contributors of a campaign
    function getContributors(uint256 _campaignId) public view returns (address[] memory) {
        return campaigns[_campaignId].contributors;
    }

    // Function to get contribution amount by a specific contributor
    function getContributionAmount(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}




//Example 2: Milestone-Based Crowdfunding Contract
//This contract allows users to create campaigns with milestones, and funds are released upon reaching each milestone.





// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract MilestoneCrowdfunding {
    struct Milestone {
        string description;
        uint256 targetAmount;
        bool achieved;
    }

    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 totalGoal;
        uint256 pledged;
        bool completed;
        Milestone[] milestones;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner, uint256 totalGoal);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event MilestoneAchieved(uint256 indexed campaignId, uint256 milestoneIndex, uint256 totalPledged);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalPledged);

    // Function to create a new campaign with milestones
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _totalGoal,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneTargets
    ) public {
        require(_milestoneDescriptions.length == _milestoneTargets.length, "Milestones data mismatch");

        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.owner = payable(msg.sender);
        newCampaign.totalGoal = _totalGoal;
        newCampaign.pledged = 0;
        newCampaign.completed = false;

        for (uint256 i = 0; i < _milestoneDescriptions.length; i++) {
            newCampaign.milestones.push(Milestone({
                description: _milestoneDescriptions[i],
                targetAmount: _milestoneTargets[i],
                achieved: false
            }));
        }

        emit CampaignCreated(campaignCount, _title, msg.sender, _totalGoal);
    }

    // Function to contribute to a campaign
    function contribute(uint256 _campaignId) public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");

        campaign.pledged += msg.value;

        for (uint256 i = 0; i < campaign.milestones.length; i++) {
            if (!campaign.milestones[i].achieved && campaign.pledged >= campaign.milestones[i].targetAmount) {
                campaign.milestones[i].achieved = true;
                campaign.owner.transfer(campaign.milestones[i].targetAmount);
                emit MilestoneAchieved(_campaignId, i, campaign.pledged);
            }
        }

        if (campaign.pledged >= campaign.totalGoal) {
            campaign.completed = true;
            emit CampaignCompleted(_campaignId, campaign.pledged);
        } else {
            emit ContributionMade(_campaignId, msg.sender, msg.value);
        }
    }

    // Function to get campaign milestones
    function getMilestones(uint256 _campaignId) public view returns (Milestone[] memory) {
        return campaigns[_campaignId].milestones;
    }
}


//Example 3: Refundable Crowdfunding Contract
//This contract allows users to create campaigns and provides a mechanism for contributors to get refunds if the funding goal is not met.


// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract RefundableCrowdfunding {
    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 goal;
        uint256 pledged;
        bool completed;
        mapping(address => uint256) contributions;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner, uint256 goal);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event RefundIssued(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalPledged);

    // Function to create a new campaign
    function createCampaign(string memory _title, string memory _description, uint256 _goal) public {
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.owner = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.pledged = 0;
        newCampaign.completed = false;

        emit CampaignCreated(campaignCount, _title, msg.sender, _goal);
    }

    // Function to contribute to a campaign
    function contribute(uint256 _campaignId) public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");

        campaign.pledged += msg.value;
        campaign.contributions[msg.sender] += msg.value;

        emit ContributionMade(_campaignId, msg.sender, msg.value);

        if (campaign.pledged >= campaign.goal) {
            campaign.completed = true;
            campaign.owner.transfer(campaign.pledged);
            emit CampaignCompleted(_campaignId, campaign.pledged);
        }
    }

    // Function to claim a refund if the campaign is not completed
    function claimRefund(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");
        uint256 contribution = campaign.contributions[msg.sender];
        require(contribution > 0, "No contributions found for this address");

        campaign.contributions[msg.sender] = 0;
        campaign.pledged -= contribution;
        payable(msg.sender).transfer(contribution);

        emit RefundIssued(_campaignId, msg.sender, contribution);
    }

    // Function to get the contribution amount of a specific contributor
    function getContributionAmount(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}


//Example 4: Time-Limited Crowdfunding Contract
//This contract allows users to create campaigns with a time limit. If the funding goal is not met within the time limit, contributors can withdraw their contributions.



// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract TimeLimitedCrowdfunding {
    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 goal;
        uint256 pledged;
        uint256 deadline;
        bool completed;
        mapping(address => uint256) contributions;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner, uint256 goal, uint256 deadline);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event RefundIssued(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalPledged);

    // Function to create a new campaign with a deadline
    function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _duration) public {
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.owner = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.pledged = 0;
        newCampaign.deadline = block.timestamp + _duration;
        newCampaign.completed = false;

        emit CampaignCreated(campaignCount, _title, msg.sender, _goal, newCampaign.deadline);
    }

    // Function to contribute to a campaign
    function contribute(uint256 _campaignId) public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");
        require(block.timestamp <= campaign.deadline, "Campaign has expired");

        campaign.pledged += msg.value;
        campaign.contributions[msg.sender] += msg.value;

        emit ContributionMade(_campaignId, msg.sender, msg.value);

        if (campaign.pledged >= campaign.goal) {
            campaign.completed = true;
            campaign.owner.transfer(campaign.pledged);
            emit CampaignCompleted(_campaignId, campaign.pledged);
        }
    }

    // Function to claim a refund if the campaign goal is not met within the deadline
    function claimRefund(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp > campaign.deadline, "Campaign is still ongoing");
        require(!campaign.completed, "Campaign is already completed");
        uint256 contribution = campaign.contributions[msg.sender];
        require(contribution > 0, "No contributions found for this address");

        campaign.contributions[msg.sender] = 0;
        campaign.pledged -= contribution;
        payable(msg.sender).transfer(contribution);

        emit RefundIssued(_campaignId, msg.sender, contribution);
    }

    // Function to get the contribution amount of a specific contributor
    function getContributionAmount(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}



//Example 5: Equity Crowdfunding Contract
//This contract allows users to create campaigns and offer equity in return for contributions. Contributors receive shares proportional to their contributions.


// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract EquityCrowdfunding {
    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 goal;
        uint256 pledged;
        bool completed;
        uint256 totalShares;
        mapping(address => uint256) contributions;
        mapping(address => uint256) shares;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner, uint256 goal, uint256 totalShares);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event SharesIssued(uint256 indexed campaignId, address indexed contributor, uint256 shares);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalPledged);

    // Function to create a new campaign with a specified number of shares
    function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _totalShares) public {
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.owner = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.pledged = 0;
        newCampaign.completed = false;
        newCampaign.totalShares = _totalShares;

        emit CampaignCreated(campaignCount, _title, msg.sender, _goal, _totalShares);
    }

    // Function to contribute to a campaign and receive shares
    function contribute(uint256 _campaignId) public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");

        uint256 shares = (msg.value * campaign.totalShares) / campaign.goal;
        campaign.pledged += msg.value;
        campaign.contributions[msg.sender] += msg.value;
        campaign.shares[msg.sender] += shares;

        emit ContributionMade(_campaignId, msg.sender, msg.value);
        emit SharesIssued(_campaignId, msg.sender, shares);

        if (campaign.pledged >= campaign.goal) {
            campaign.completed = true;
            campaign.owner.transfer(campaign.pledged);
            emit CampaignCompleted(_campaignId, campaign.pledged);
        }
    }

    // Function to get the shares of a specific contributor
    function getShares(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return campaigns[_campaignId].shares[_contributor];
    }

    // Function to get the contribution amount of a specific contributor
    function getContributionAmount(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}



//Example 6: Reward-Based Crowdfunding Contract
//This contract allows users to create campaigns and offer rewards for contributions.


// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract RewardCrowdfunding {
    struct Reward {
        string description;
        uint256 minContribution;
        bool available;
    }

    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 goal;
        uint256 pledged;
        bool completed;
        Reward[] rewards;
        mapping(address => uint256) contributions;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner, uint256 goal);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event RewardAdded(uint256 indexed campaignId, string description, uint256 minContribution);
    event RewardClaimed(uint256 indexed campaignId, address indexed contributor, string rewardDescription);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalPledged);

    // Function to create a new campaign
    function createCampaign(string memory _title, string memory _description, uint256 _goal) public {
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.owner = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.pledged = 0;
        newCampaign.completed = false;

        emit CampaignCreated(campaignCount, _title, msg.sender, _goal);
    }

    // Function to add a reward to a campaign
    function addReward(uint256 _campaignId, string memory _description, uint256 _minContribution) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.owner, "Only the campaign owner can add rewards");
        campaign.rewards.push(Reward({
            description: _description,
            minContribution: _minContribution,
            available: true
        }));

        emit RewardAdded(_campaignId, _description, _minContribution);
    }

    // Function to contribute to a campaign and claim a reward
    function contribute(uint256 _campaignId) public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");

        campaign.pledged += msg.value;
        campaign.contributions[msg.sender] += msg.value;

        emit ContributionMade(_campaignId, msg.sender, msg.value);

        for (uint256 i = 0; i < campaign.rewards.length; i++) {
            if (campaign.rewards[i].available && msg.value >= campaign.rewards[i].minContribution) {
                campaign.rewards[i].available = false;
                emit RewardClaimed(_campaignId, msg.sender, campaign.rewards[i].description);
            }
        }

        if (campaign.pledged >= campaign.goal) {
            campaign.completed = true;
            campaign.owner.transfer(campaign.pledged);
            emit CampaignCompleted(_campaignId, campaign.pledged);
        }
    }

    // Function to get the rewards of a campaign
    function getRewards(uint256 _campaignId) public view returns (Reward[] memory) {
        return campaigns[_campaignId].rewards;
    }

    // Function to get the contribution amount of a specific contributor
    function getContributionAmount(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}


//Example 7: Voting-Based Crowdfunding Contract
//This contract allows contributors to vote on whether the funds should be released to the campaign owner.


// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract VotingCrowdfunding {
    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 goal;
        uint256 pledged;
        bool completed;
        mapping(address => uint256) contributions;
        mapping(address => bool) votes;
        uint256 voteCount;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner, uint256 goal);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event VoteCast(uint256 indexed campaignId, address indexed voter);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalPledged);

    // Function to create a new campaign
    function createCampaign(string memory _title, string memory _description, uint256 _goal) public {
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.owner = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.pledged = 0;
        newCampaign.completed = false;
        newCampaign.voteCount = 0;

        emit CampaignCreated(campaignCount, _title, msg.sender, _goal);
    }

    // Function to contribute to a campaign
    function contribute(uint256 _campaignId) public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");

        campaign.pledged += msg.value;
        campaign.contributions[msg.sender] += msg.value;

        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }

    // Function to cast a vote on whether the funds should be released
    function vote(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.contributions[msg.sender] > 0, "Only contributors can vote");
        require(!campaign.votes[msg.sender], "You have already voted");

        campaign.votes[msg.sender] = true;
        campaign.voteCount++;

        emit VoteCast(_campaignId, msg.sender);

        if (campaign.voteCount > campaign.pledged / 2) {
            campaign.completed = true;
            campaign.owner.transfer(campaign.pledged);
            emit CampaignCompleted(_campaignId, campaign.pledged);
        }
    }

    // Function to get the contribution amount of a specific contributor
    function getContributionAmount(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}


//Example 8: Installment-Based Crowdfunding Contract
//This contract releases funds to the campaign owner in installments based on reaching specific funding thresholds.

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract InstallmentCrowdfunding {
    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 goal;
        uint256 pledged;
        bool completed;
        uint256 installmentAmount;
        uint256 withdrawnAmount;
        mapping(address => uint256) contributions;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner, uint256 goal, uint256 installmentAmount);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event InstallmentReleased(uint256 indexed campaignId, uint256 amount);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalPledged);

    // Function to create a new campaign with installment releases
    function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _installmentAmount) public {
        require(_installmentAmount > 0 && _installmentAmount <= _goal, "Installment amount must be positive and less than or equal to the goal");

        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.owner = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.pledged = 0;
        newCampaign.completed = false;
        newCampaign.installmentAmount = _installmentAmount;
        newCampaign.withdrawnAmount = 0;

        emit CampaignCreated(campaignCount, _title, msg.sender, _goal, _installmentAmount);
    }

    // Function to contribute to a campaign
    function contribute(uint256 _campaignId) public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");

        campaign.pledged += msg.value;
        campaign.contributions[msg.sender] += msg.value;

        emit ContributionMade(_campaignId, msg.sender, msg.value);

        if (campaign.pledged >= campaign.goal) {
            campaign.completed = true;
            emit CampaignCompleted(_campaignId, campaign.pledged);
        }
    }

    // Function to release installments to the campaign owner
    function releaseInstallment(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.owner, "Only the campaign owner can release installments");
        require(!campaign.completed, "Campaign is already completed");

        uint256 availableToWithdraw = (campaign.pledged / campaign.installmentAmount) * campaign.installmentAmount - campaign.withdrawnAmount;
        require(availableToWithdraw > 0, "No installments available for release");

        campaign.withdrawnAmount += availableToWithdraw;
        campaign.owner.transfer(availableToWithdraw);

        emit InstallmentReleased(_campaignId, availableToWithdraw);
    }

    // Function to get the contribution amount of a specific contributor
    function getContributionAmount(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}


//Example 9: Matching Funds Crowdfunding Contract
//This contract provides matching funds from a sponsor for each contribution made to the campaign.

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract MatchingFundsCrowdfunding {
    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 goal;
        uint256 pledged;
        bool completed;
        uint256 sponsorFunds;
        uint256 matchingRate;
        mapping(address => uint256) contributions;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner, uint256 goal, uint256 matchingRate);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount, uint256 matchedAmount);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalPledged);

    // Function to create a new campaign with matching funds
    function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _matchingRate, uint256 _sponsorFunds) public {
        require(_matchingRate > 0 && _matchingRate <= 100, "Matching rate must be between 1 and 100");

        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.owner = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.pledged = 0;
        newCampaign.completed = false;
        newCampaign.sponsorFunds = _sponsorFunds;
        newCampaign.matchingRate = _matchingRate;

        emit CampaignCreated(campaignCount, _title, msg.sender, _goal, _matchingRate);
    }

    // Function to contribute to a campaign and receive matching funds
    function contribute(uint256 _campaignId) public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");

        uint256 matchAmount = (msg.value * campaign.matchingRate) / 100;
        require(campaign.sponsorFunds >= matchAmount, "Not enough sponsor funds for matching");

        campaign.pledged += msg.value + matchAmount;
        campaign.contributions[msg.sender] += msg.value;
        campaign.sponsorFunds -= matchAmount;

        emit ContributionMade(_campaignId, msg.sender, msg.value, matchAmount);

        if (campaign.pledged >= campaign.goal) {
            campaign.completed = true;
            campaign.owner.transfer(campaign.pledged);
            emit CampaignCompleted(_campaignId, campaign.pledged);
        }
    }

    // Function to get the contribution amount of a specific contributor
    function getContributionAmount(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}


//Example 10: Lottery Crowdfunding Contract
//This contract allows contributors to enter a lottery, where the winner receives a prize.


// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract LotteryCrowdfunding {
    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 goal;
        uint256 pledged;
        bool completed;
        address[] contributors;
        mapping(address => uint256) contributions;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner, uint256 goal);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event LotteryWinner(uint256 indexed campaignId, address indexed winner, uint256 prize);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalPledged);

    // Function to create a new campaign
    function createCampaign(string memory _title, string memory _description, uint256 _goal) public {
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.owner = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.pledged = 0;
        newCampaign.completed = false;

        emit CampaignCreated(campaignCount, _title, msg.sender, _goal);
    }

    // Function to contribute to a campaign and enter the lottery
    function contribute(uint256 _campaignId) public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");

        campaign.pledged += msg.value;
        campaign.contributions[msg.sender] += msg.value;
        campaign.contributors.push(msg.sender);

        emit ContributionMade(_campaignId, msg.sender, msg.value);

        if (campaign.pledged >= campaign.goal) {
            campaign.completed = true;
            campaign.owner.transfer(campaign.pledged);

            address winner = campaign.contributors[random() % campaign.contributors.length];
            uint256 prize = campaign.pledged / 10; // 10% of the total pledged amount as prize
            payable(winner).transfer(prize);

            emit LotteryWinner(_campaignId, winner, prize);
            emit CampaignCompleted(_campaignId, campaign.pledged);
        }
    }

    // Function to get a random number (not secure, for demonstration purposes only)
    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, campaignCount)));
    }

    // Function to get the contribution amount of a specific contributor
    function getContributionAmount(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}


//Example 12: Flexible Goal Crowdfunding Contract
//This contract allows campaigns to have flexible funding goals, meaning the owner can withdraw funds even if the goal is not met.


// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract FlexibleGoalCrowdfunding {
    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 goal;
        uint256 pledged;
        bool completed;
        mapping(address => uint256) contributions;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner, uint256 goal);
    event ContributionMade(uint256 indexed campaignId, address indexed contributor, uint256 amount);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalPledged);

    // Function to create a new campaign
    function createCampaign(string memory _title, string memory _description, uint256 _goal) public {
        campaignCount++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.id = campaignCount;
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.owner = payable(msg.sender);
        newCampaign.goal = _goal;
        newCampaign.pledged = 0;
        newCampaign.completed = false;

        emit CampaignCreated(campaignCount, _title, msg.sender, _goal);
    }

    // Function to contribute to a campaign
    function contribute(uint256 _campaignId) public payable {
        require(msg.value > 0, "Contribution must be greater than 0");
        Campaign storage campaign = campaigns[_campaignId];
        require(!campaign.completed, "Campaign is already completed");

        campaign.pledged += msg.value;
        campaign.contributions[msg.sender] += msg.value;

        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }

    // Function for the campaign owner to withdraw funds
    function withdraw(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.owner, "Only the campaign owner can withdraw funds");
        require(!campaign.completed, "Campaign is already completed");

        uint256 amount = campaign.pledged;
        campaign.pledged = 0;
        campaign.completed = true;
        campaign.owner.transfer(amount);

        emit CampaignCompleted(_campaignId, amount);
    }

    // Function to get the contribution amount of a specific contributor
    function getContributionAmount(uint256 _campaignId, address _contributor) public view returns (uint256) {
        return campaigns[_campaignId].contributions[_contributor];
    }
}




//Example 14: Simple Donation Contract
//This contract allows anyone to create a campaign and receive donations without any specific goal.

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract SimpleDonation {
    struct Campaign {
        uint256 id;
        string title;
        string description;
        address payable owner;
        uint256 totalDonations;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 indexed campaignId, string title, address indexed owner);
    event DonationReceived(uint256 indexed campaignId, address indexed donor, uint256 amount);

    // Function to create a new campaign
    function createCampaign(string memory _title, string memory _description) public {
        campaignCount++;
        campaigns[campaignCount] = Campaign(campaignCount, _title, _description, payable(msg.sender), 0);

        emit CampaignCreated(campaignCount, _title, msg.sender);
    }

    // Function to donate to a campaign
    function donate(uint256 _campaignId) public payable {
        require(msg.value > 0, "Donation must be greater than 0");

        Campaign storage campaign = campaigns[_campaignId];
        campaign.totalDonations += msg.value;

        campaign.owner.transfer(msg.value);

        emit DonationReceived(_campaignId, msg.sender, msg.value);
    }

    // Function to get the total donations of a campaign
    function getTotalDonations(uint256 _campaignId) public view returns (uint256) {
        return campaigns[_campaignId].totalDonations;
    }
}




//Example 17: Charity Voting Contract
//This contract allows contributors to vote on how the funds should be distributed among different projects.


// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract CharityVoting {
    struct Project {
        uint256 id;
        string name;
        string description;
        uint256 votes;
        address payable owner;
    }

    uint256 public projectCount;
    mapping(uint256 => Project) public projects;
    mapping(address => bool) public hasVoted;

    event ProjectAdded(uint256 indexed projectId, string name, address indexed owner);
    event Voted(uint256 indexed projectId, address indexed voter);
    event FundsDistributed(uint256 indexed projectId, uint256 amount);

    // Function to add a new project
    function addProject(string memory _name, string memory _description) public {
        projectCount++;
        projects[projectCount] = Project(projectCount, _name, _description, 0, payable(msg.sender));

        emit ProjectAdded(projectCount, _name, msg.sender);
    }

    // Function to vote for a project
    function vote(uint256 _projectId) public {
        require(!hasVoted[msg.sender], "You have already voted");
        require(_projectId > 0 && _projectId <= projectCount, "Invalid project ID");

        projects[_projectId].votes++;
        hasVoted[msg.sender] = true;

        emit Voted(_projectId, msg.sender);
    }

    // Function to distribute funds to the project with the most votes
    function distributeFunds() public payable {
        require(msg.value > 0, "Funds to be distributed must be greater than 0");

        uint256 highestVotes = 0;
        uint256 winningProjectId = 0;

        for (uint256 i = 1; i <= projectCount; i++) {
            if (projects[i].votes > highestVotes) {
                highestVotes = projects[i].votes;
                winningProjectId = i;
            }
        }

        require(winningProjectId > 0, "No projects found");

        projects[winningProjectId].owner.transfer(msg.value);

        emit FundsDistributed(winningProjectId, msg.value);
    }

    // Function to get the number of votes for a project
    function getVotes(uint256 _projectId) public view returns (uint256) {
        return projects[_projectId].votes;
    }
}
