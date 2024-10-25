// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract Raffle {
    uint256 private balance;
    address[] private players;
    address private immutable manager;
    mapping(address => uint256) private balances;
    bool private isRaffleOpen;
    uint256 private raffleFee;
    mapping(address => uint256) private rewards;

    // @notice The constructor
    constructor () {
        manager = msg.sender;
    }

    // @notice Enter the raffle by sending ETH
    function enter() external payable {
        uint8 playersLength = uint8(players.length);
        
        // @dev Check if the raffle is full
        require(playersLength < 5, "Raffle is full. Please wait for the current raffle to end");
        // @dev Check if the minimum ETH to enter is met
        require(msg.value >= 0.001 ether, "Minimum ETH not met to enter the raffle");

        balances[msg.sender] += msg.value;
        balance += msg.value;
        players.push(msg.sender);

        // @dev If there are 5 players, the raffle closes
        if(playersLength + 1 == 5)
        {
            isRaffleOpen = false;
        }
    }

    
    // @notice Picking a winner
    // @dev Only the manager can pick a winner
    function pickWinner() external onlyManager {
        require(!isRaffleOpen, "There are not enough active players in the raffle");

        // @dev Get a random index
        uint256 index = random() % players.length;
        address winner = players[index];

        // @dev setting all player balances to 0
        for(uint256 i; i < 5; i++)
        {
            balances[players[i]] = 0;
        }

        // @dev Allocate the raffle fee to the raffle
        balance -= 0.001 ether;
        rewards[winner] += 0.001 ether;

        // @dev Allocate the eth to the winner
        rewards[winner] += balance;

        delete players;
        balance = 0;

        isRaffleOpen = true;
    }

    // @notice This function is responsible for withdrawing ETH
    function withdrawETH() external payable {
        require(isRaffleOpen, "Raffle is in the process of picking a winner");
        require(balances[msg.sender] > 0, "There is no ETH deposited in the current raffle");
        uint256 ethToSend = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(ethToSend);
    }

    // @notice This function is responsible for claiming rewards
    // @param amount The amount of ETH to claim
    // @notice if the amount is set to max, the user will claim all of their ETH
    function claimRewards(uint256 amount) external payable {
        require(isRaffleOpen, "Raffle is in the process of picking a winner");

        if(amount == type(uint256).max)
        {
            require(rewards[msg.sender] > 0, "There is no ETH to claim");
            uint256 rewardsToClaim = rewards[msg.sender];
            rewards[msg.sender] = 0;
            payable(msg.sender).transfer(rewardsToClaim);
        }
        else 
        {
            require(rewards[msg.sender] >= amount, "There is not enough ETH to claim");
            rewards[msg.sender] -= amount;
            payable(msg.sender).transfer(amount);
        }


    }

    // @notice This function returns a random number
    function random() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(players, balance)));
    }

    // @notice This function returns all active players in the raffle
    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    // @notice This modifier ensures that only the manager can call certain functions
    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }
}