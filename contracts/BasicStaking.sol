//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract Staking {
    event Staked(address stakerAddress, uint amount);
    event Unstaked(address unstaker, uint index);
    event ClaimedReward(address claimer, uint index, uint amount);
    event StakedReward(address rewardStaker, uint index, uint amount);
    event DecreasedStake(address stakeDecreeaser, uint index, uint decreaseAmount);
    event OwnerChanged(address oldOwner, address newOwner);

    //owner related code, 
    //I could use Ownable of OpenZeppelin but I want to show you that I can comfortably create "owner" code.
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
        uint apy;
        uint stakeDate;
    }
    mapping(address => StakeDetails[]) public StakeDetailsMapping;

    //Function lets everyone to stake anytime they want and as many times they want.
    //Each stake will be a new staking record. As "apy" will be calculated offchain, I dont need
    //to calculate it here. I can just grab it from the website.

    //If token is staked, we will use ERC20 transfer functions. If currency is staked,
    //then we will make this function payable and later use call methods.
    function stake(uint _amount, uint _period, uint _apy) public {
        require(msg.sender != address(0), "Cannot stake from address 0");
        require(_amount > 0, "stake must be > 0");
        
        stakers[msg.sender] += _amount;
        StakeDetails memory newStake = StakeDetails(_amount, _period, _apy, block.timestamp);
        StakeDetailsMapping[msg.sender].push(newStake);
        hasStaked[msg.sender] = true;
    }

    //user can claim reward for his/her stakes. To specify which stake, user needs to enter an index number
    //for the  StakeDetails[] array. User can specify his choice on the frontend website, and later web3
    //functions will convey the index number to the function below.

    //ASSUMPTION 1: I assume the apy is stable. I mean apy does not change daily.

    //ASSUMPTION 2: I assume deposits and rewards will be in  base currencies (like ETH in Ethereum). 
    //If deposits and rewards will be in ERC20, methods can be easily updated.

    //Users will need to wait for 28 days to withdraw the reward (condition in QA).
    //For testing purposes, I made 28 seconds. Normally I need make it "28 days".
    function calculateReward(uint _index) internal view onlyStakers returns(uint) {
        //security checks
        require(msg.sender != address(0), "Cannot claim from address 0");
        require(stakers[msg.sender] > 0, "your total stake amount is 0");
        uint stakedAmount = StakeDetailsMapping[msg.sender][_index].amount;
        require(stakedAmount > 0, "wrong stake index");
        uint interestRate = StakeDetailsMapping[msg.sender][_index].apy;
        uint interestDays = StakeDetailsMapping[msg.sender][_index].stakingDays;
        // Compound interest formula: principal += principal * rate/100;
        uint principal = stakedAmount;
        for ( uint i=0; i< interestDays; i++ ) {
            principal += principal * interestRate/100 ;
        }
        uint reward = principal - stakedAmount; 
        return reward;
    }

    uint public myReward;//COMMENT IN DEPLOYMENT

    function claimReward(address payable _to, uint _index) external onlyStakers {
        uint stakeTime = StakeDetailsMapping[msg.sender][_index].stakeDate;
        require(block.timestamp >= stakeTime + 28 seconds,"wait 28 days to get your reward"); //COMMENT IN DEPLOYMENT
        //require(block.timestamp >= stakeTime + 28 days,"wait 28 days to get your reward"); //UNCOMMENT IN DEPLOYMENT
        uint reward = calculateReward(_index);
        //resetting the block.timestamp to prevent exploitation
        StakeDetailsMapping[msg.sender][_index].stakeDate = block.timestamp;
        //transferring the reward (see ASSUMPTION 2)
        /* (bool success, ) = _to.call{value: reward}(""); 
        if(success == false) {
            StakeDetailsMapping[msg.sender][_index].stakeDate = stakeTime;
            revert("transaction failed");
        }*/ // UNCOMMENT IN DEPLOYMENT
        myReward = reward; //COMMENT IN DEPLOYMENT
    }

    function stakeReward(uint _index, uint _period, uint _apy) external onlyStakers {
        uint stakeTime = StakeDetailsMapping[msg.sender][_index].stakeDate;
        require(block.timestamp >= stakeTime + 28 seconds,"wait 28 days to get your reward"); //COMMENT IN DEPLOYMENT
        //require(block.timestamp >= stakeTime + 28 days,"wait 28 days to get your reward"); //UNCOMMENT IN DEPLOYMENT
        uint reward = calculateReward(_index);
        //resetting the block.timestamp to prevent exploitation
        StakeDetailsMapping[msg.sender][_index].stakeDate = block.timestamp;

        //creating a new stake from claimedReward
        stake(reward, _period, _apy);
    }

    uint public myUnstakingAmount;//COMMENT IN DEPLOYMENT
    //User can then unstake the specific stake
    function unstake(address payable _to, uint _index) external onlyStakers {
        //1) To unstake, user must first claim the reward that is available (28 days condition).
        uint stakeTime = StakeDetailsMapping[msg.sender][_index].stakeDate;
        if(block.timestamp >= stakeTime + 28 seconds) { //DEPLOYMENT: 28 days
            revert("claim your reward first, then unstake");
        }

        // 2) transferring the reward (see ASSUMPTION 2)
        uint stakeAmount = StakeDetailsMapping[msg.sender][_index].amount;
        myUnstakingAmount = stakeAmount; //COMMENT IN DEPLOYMENT
        // (bool success, ) = _to.call{value: stake}(""); // UNCOMMENT IN DEPLOYMENT
        // require(success, "unstaking failed"); // UNCOMMENT IN DEPLOYMENT

        // 3) delete the specific stake from stakes array of the user
        uint stakesArray = StakeDetailsMapping[msg.sender].length;
        for(uint i=0; i<stakesArray-1; i++) {
            StakeDetailsMapping[msg.sender][_index] = StakeDetailsMapping[msg.sender][_index+1];
        }
        StakeDetailsMapping[msg.sender].pop();

        //NOTE: I can reconfigure step 3 and 2 to prevent reentrancy attacks. For easy reading & testing, I left it like this.
    }

    function decreaseStake(address payable _to, uint _index, uint _amount) external {
        //1) To decrease stake, user must first claim the reward that is available (28 days condition).
        uint stakeTime = StakeDetailsMapping[msg.sender][_index].stakeDate;
        if(block.timestamp >= stakeTime + 28 seconds) { //DEPLOYMENT: 28 days
            revert("claim your reward first, then unstake");
        }

        // 2) transferring the desired stake amount (see ASSUMPTION 2)
        require(_amount < StakeDetailsMapping[msg.sender][_index].amount, "amount must be smaller than stake");
        StakeDetailsMapping[msg.sender][_index].amount -= _amount;
        // (bool success, ) = _to.call{value: _amount}(""); // UNCOMMENT IN DEPLOYMENT
        // require(success, "unstaking failed"); // UNCOMMENT IN DEPLOYMENT
    }

    function displayStakes() external view returns(StakeDetails[] memory) {
        return StakeDetailsMapping[msg.sender];
    }
    function displaySpecificStake(uint _index) external view returns(StakeDetails memory) {
        return StakeDetailsMapping[msg.sender][_index];
    }
    function displaySpecificStakeAmount(uint _index) external view returns(uint) {
        return StakeDetailsMapping[msg.sender][_index].amount;
    }

    fallback() external payable{}
    receive() external payable{}

    /*
    function stake(uint _index) public onlyStakers { }
    function calculateReward(uint _index) internal onlyStakers { }
    function claimReward(uint _index) external onlyStakers { } reset blocktimestamp
    function stakeReward(uint _index) external onlyStakers { }
    function decreaseStake(uint _index) external onlyStakers {}
    function unstake(uint _index) external onlyStakers { }
    */

}