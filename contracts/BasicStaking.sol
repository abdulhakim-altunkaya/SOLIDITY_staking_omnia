pragma solidity ^0.8.0;

contract Staking {
    mapping (address => uint256) public stakes;
    mapping (address => bool) public hasStaked;
    address public owner;
    uint256 public totalStaked;

    event Staked(address staker, uint256 stakeAmount);
    event Unstaked(address staker, uint256 stakeAmount);

    constructor() public {
        owner = msg.sender;
    }

    error NotStaker(address caller, string message);
    modifier onlyStakers(address caller) {
        if(hasStaked[caller] == false) {
            revert NotStaker(caller, "you are not staker");
        }
    }

    function stake(uint256 stakeAmount) public {
        require(msg.sender != address(0), "Cannot stake from address 0");
        require(stakeAmount > 0, "Must stake a positive amount");

        stakes[msg.sender] += stakeAmount;
        totalStaked += stakeAmount;

        emit Staked(msg.sender, stakeAmount);
    }

    function unstake(uint256 unstakeAmount) public {
        require(msg.sender != address(0), "Cannot unstake from address 0");
        require(unstakeAmount > 0, "Must unstake a positive amount");
        require(unstakeAmount <= stakes[msg.sender], "Cannot unstake more than current stake");

        stakes[msg.sender] -= unstakeAmount;
        totalStaked -= unstakeAmount;

        emit Unstaked(msg.sender, unstakeAmount);
    }

    function claim() public onlyStaker() {
        require(msg.sender != address(0), "Cannot claim from address 0");
        require(stakes[msg.sender] > 0, "Must have a stake to claim");

        uint256 claimAmount = (stakes[msg.sender] * 3) / 100;
        msg.sender.transfer(claimAmount);

        emit Claimed(msg.sender, claimAmount);
    }

    function() external payable {}
}