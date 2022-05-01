// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0;

contract CrowdFunding {

    enum ProjectState { Opened, Achieved, Closed }

    struct Project {
        string id;
        string name;
        string description;
        address payable author;
        uint totalFunding;
        uint fundingGoal;
        ProjectState state;
    }

    struct Contribution {
        address contributor;
        uint amount;
    }
    
    mapping(string => uint) public projectIndexes;
    mapping(string => Contribution[]) public contributions;
    Project[] public projects;

    event CreatedProject(string projectId, string projectName, string projectDescription, address projectAuthor, uint projectFundingGoal);
    event FundedProject(string projectId, address contributor, uint amount);
    event ClosedProject(string projectId, uint totalFundingAmount);
    
    constructor() {
    }    

    modifier onlyAuthor(string calldata _projectId) {
        uint projectIndex = getProjectIndex(_projectId);
        Project memory currentProject = projects[projectIndex];
        require(msg.sender == currentProject.author, "This function can be executed only by the author.");
        _;
    }

    modifier notAuthor(string calldata _projectId) {
        uint projectIndex = getProjectIndex(_projectId);
        Project memory currentProject = projects[projectIndex];
        require(msg.sender != currentProject.author, "This function cannot be executed by the author.");
        _;
    }

    modifier alreadyClosed(string calldata _projectId) {
        uint projectIndex = getProjectIndex(_projectId);
        Project memory currentProject = projects[projectIndex];
        require(currentProject.state != ProjectState.Closed, "You cannot contribute to a closed project.");
        _;
    }

    function getProjectIndex(string calldata _projectId) public view returns (uint) {
        return (projectIndexes[_projectId]);
    }

    function getCount() public view returns(uint count) {
        return projects.length;
    }

    function createProject(string calldata _id, string calldata _name, string calldata _description, uint _fundingGoal) public {
        require(_fundingGoal > 0, "Funding goal is mandatory, cannot be 0.");
        Project memory createdProject = Project(_id, _name, _description, payable(msg.sender), 0, _fundingGoal, ProjectState.Opened);
        projects.push(createdProject);
        projectIndexes[_id] = getCount() - 1;
        emit CreatedProject(_id, _name, _description, msg.sender, _fundingGoal);
    }

    function changeProjectName(string calldata _projectId, string calldata _newName) public onlyAuthor(_projectId) {
        uint projectIndex = getProjectIndex(_projectId);
        Project memory currentProject = projects[projectIndex];
        currentProject.name = _newName;
        projects[projectIndex] = currentProject;
    }

    function closeProject(string calldata _projectId) public onlyAuthor(_projectId) {
        uint projectIndex = getProjectIndex(_projectId);
        Project memory currentProject = projects[projectIndex];
        currentProject.state = ProjectState.Closed;
        projects[projectIndex] = currentProject;
        emit ClosedProject(currentProject.id, currentProject.totalFunding);
    }

    function fundProject(string calldata _projectId) public payable notAuthor(_projectId) alreadyClosed(_projectId) {
        require(msg.value > 0, "Is mandatory to contribute some ETH.");
        uint projectIndex = getProjectIndex(_projectId);
        Project memory currentProject = projects[projectIndex];
        currentProject.author.transfer(msg.value);
        currentProject.totalFunding += msg.value;
        verifyProjectState(currentProject);
        projects[projectIndex] = currentProject;
        contributions[_projectId].push(Contribution(msg.sender, msg.value));
        emit FundedProject(currentProject.id, msg.sender, msg.value);
    }

    function verifyProjectState(Project memory _currentProject) private pure {
        if(_currentProject.state == ProjectState.Opened && _currentProject.totalFunding >= _currentProject.fundingGoal)
            _currentProject.state = ProjectState.Achieved;
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
