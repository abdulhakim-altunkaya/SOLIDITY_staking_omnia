//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract Staking {

    //owner related code, 
    //I could use Ownable of OpenZeppelin but I want to make the contract easier to read.
    address public owner;
    error NotOwner(address caller, string message);
    modifier onlyOwner() {
        if(msg.sender != owner) {
            revert NotOwner(msg.sender, "you are not owner");
        }
        _;
    }
    function changeOwner(address _newOwner) external onlyOwner{
        require(_newOwner != address(0), "owner cant be address(0)");
        owner = _newOwner;
    }

    //keeping track of who staked and how much staked

    mapping (address => bool) public hasStaked;
    uint public totalStaked;

    event Staked(address staker, uint stakeAmount);
    event Unstaked(address staker, uint stakeAmount);

    constructor() {
        owner = msg.sender;
    }

    error NotStaker(address caller, string message);
    modifier onlyStakers() {
        if(hasStaked[msg.sender] == false) {
            revert NotStaker(msg.sender, "you are not staker");
        }
        _;
    }

    mapping(address => uint) public stakers;
    struct StakeDetails {
        uint amount;
        uint stakingDays;
        uint stakeDate;
    }
    mapping(address => StakeDetails[]) public StakeDetailsMapping;

    //Function lets everyone to stake anytime they want and as many times they want.
    //Each stake will be a new staking record. As "apy" will be calculated offchain, I dont need
    //to calculate it here. I can just grab it from the website.
    function stake(uint _amount, uint _period, uint _apy) external {
        require(msg.sender != address(0), "Cannot stake from address 0");
        require(_amount > 0, "stake must be > 0");
        
        stakers[msg.sender] += _amount;
        StakeDetails memory newStake = StakeDetails(_amount, _period, _apy);
        StakeDetailsMapping[msg.sender].push(newStake);

        hasStaked[msg.sender] = true;
    }

    function displayStakes() external view returns(StakeDetails[] memory) {
        return StakeDetailsMapping[msg.sender];
    }
    function displaySpecificStake(uint _index) external view returns(StakeDetails memory) {
        return StakeDetailsMapping[msg.sender][_index];
    }
    //user can claim reward for his/her stakes. To specify which stake, user needs to enter an index number
    //for the  StakeDetails[] array. User can specify his choice on the frontend website, and later web3
    //functions will convey the index number to the function below.
    function claim(uint _index) external onlyStakers {
        require(msg.sender != address(0), "Cannot claim from address 0");
        require(stakers[msg.sender] > 0, "Must have a stake to claim");


    }










    function stake1(uint256 stakeAmount) public {
        require(msg.sender != address(0), "Cannot stake from address 0");
        require(stakeAmount > 0, "Must stake a positive amount");

        stakers[msg.sender] += stakeAmount;
        totalStaked += stakeAmount;

        //emit Staked(msg.sender, stakeAmount);
    }

    function unstake(uint256 unstakeAmount) public {
        require(msg.sender != address(0), "Cannot unstake from address 0");
        require(unstakeAmount > 0, "Must unstake a positive amount");
        require(unstakeAmount <= stakers[msg.sender], "Cannot unstake more than current stake");

        stakers[msg.sender] -= unstakeAmount;
        totalStaked -= unstakeAmount;

        //emit Unstaked(msg.sender, unstakeAmount);
    }

    function claim1(uint _apy) public onlyStakers {
        require(msg.sender != address(0), "Cannot claim from address 0");
        require(stakers[msg.sender] > 0, "Must have a stake to claim");

        uint claimAmount = (stakers[msg.sender] * _apy) / 100;
        payable(msg.sender).transfer(claimAmount);

        //emit Claimed(msg.sender, claimAmount);
    }

    fallback() external payable{}
    receive() external payable{}
}