// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract ProjectFunding {
    // Struct to represent a project
    struct Project {
        uint256 id;  // Unique identifier for the project
        string title;  // Title of the project
        string description;  // Description of the project
        address owner;  // Address of the project owner
        address[] donors;  // Array of addresses that donated to the project
        mapping(address => uint256) donations;  // Mapping from donor address to donation amount
    }

    uint256 public projectCount;  // Counter for the total number of projects
    mapping(uint256 => Project) public projects;  // Mapping from project ID to Project struct
    mapping(address => uint256[]) public userProjects;  // Mapping from user address to list of project IDs created by the user

    // Event emitted when a new project is created
    event ProjectCreated(uint256 indexed projectId, string title, address indexed owner);
    // Event emitted when a donation is made to a project
    event DonationMade(uint256 indexed projectId, address indexed donor, uint256 amount);

    // Function to create a new project
    function createProject(string memory _title, string memory _description) public {
        projectCount++;  // Increment the project count
        Project storage newProject = projects[projectCount];  // Create a new project
        newProject.id = projectCount;  // Set the project ID
        newProject.title = _title;  // Set the project title
        newProject.description = _description;  // Set the project description
        newProject.owner = msg.sender;  // Set the project owner to the address that called the function

        userProjects[msg.sender].push(projectCount);  // Add the project ID to the user's list of projects

        emit ProjectCreated(projectCount, _title, msg.sender);  // Emit the ProjectCreated event
    }

    // Function to donate to a project
    function donateToProject(uint256 _projectId) public payable {
        require(msg.value > 0, "Donation must be greater than 0");  // Ensure the donation is greater than 0
        Project storage project = projects[_projectId];  // Get the project by ID
        require(project.donations[msg.sender] == 0, "You can only donate once to a project");  // Ensure the user hasn't already donated

        project.donors.push(msg.sender);  // Add the donor to the project's list of donors
        project.donations[msg.sender] = msg.value;  // Record the donation amount

        payable(project.owner).transfer(msg.value);  // Transfer the donation to the project owner

        emit DonationMade(_projectId, msg.sender, msg.value);  // Emit the DonationMade event
    }

    // Function to get the list of donors for a project
    function getProjectDonors(uint256 _projectId) public view returns (address[] memory) {
        return projects[_projectId].donors;  // Return the list of donors
    }

    // Function to get the donation amount for a specific donor in a specific project
    function getProjectDonationAmount(uint256 _projectId, address _donor) public view returns (uint256) {
        return projects[_projectId].donations[_donor];  // Return the donation amount
    }

    
}
