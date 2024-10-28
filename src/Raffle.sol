// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/chainlink/contracts/src/v0.8/vrf/VRFConsumerBase.sol";

contract Raffle is VRFConsumerBase{
    uint256 private balance;
    address[] private players;
    address private immutable manager;
    mapping(address => uint256) private balances;
    bool private isRaffleOpen = true;
    uint256 private constant RAFFLE_FEE = 0.001 ether;
    mapping(address => uint256) private rewards;
    uint256 private maxPlayers = 5;

   // VRF variables
    event RequestFulfilled(bytes32 requestId, uint256 randomness);
    bytes32 internal immutable keyHash;
    uint256 internal immutable fee;

    event RaffleEntered(address indexed player, uint256 amount);
    event Withdrawn(address indexed player, uint256 amount);
    event WinnerSelected(address indexed winner, uint256 reward);

    // @notice The constructor
    constructor()
        VRFConsumerBase(
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, // VRF Coordinator
            0x779877A7B0D9E8603169DdbD7836e478b4624789 // LINK Token
        )
    {
        keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        manager = msg.sender;
    }

    // @notice Enter the raffle by sending ETH
    function enter() external payable {
        uint256 playersLength = uint256(players.length);
        
        // @dev Check if the raffle is full
        require(playersLength < maxPlayers, "Raffle is full. Please wait for the current raffle to end");
        // @dev Check if the minimum ETH to enter is met
        require(msg.value >= 0.001 ether, "Minimum ETH not met to enter the raffle");

        balances[msg.sender] += msg.value;
        balance += msg.value;
        players.push(msg.sender);

        // @dev If there are 5 players, the raffle closes
        if(playersLength + 1 == maxPlayers)
        {
            isRaffleOpen = false;
        }

        emit RaffleEntered(msg.sender, msg.value);
    }

    // @notice Picking a winner
    // @dev Only the manager can pick a winner
    function pickWinner() external onlyManager {
        require(!isRaffleOpen, "There are not enough active players in the raffle");
        getRandomNumber();
    }

    // @notice This function is responsible for claiming rewards
    // @param amount The amount of ETH to claim
    // @notice if the amount is set to max, the user will claim all of their ETH
    function claimRewards(uint256 amount) external payable {
        require(!isRaffleOpen, "Raffle is in the process of picking a winner");

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

    // @notice This function sets the maximum number of players that can enter a raffle
    function setMaxPlayers(uint256 _maxPlayers) external onlyManager {
        require(_maxPlayers > 1, "Maximum players must be greater than 1");
        require(isRaffleOpen, "Raffle is in the process of picking a winner");
        maxPlayers = _maxPlayers;
    }

    // @notice This function returns all active players in the raffle
    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    // @notice Requests randomness from the VRF
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }
 
    // @notice Callback function used by VRF Coordinator
    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness
    ) internal override {
        uint256 _maxPlayers = maxPlayers;
        uint256 winnerIndex = randomness % _maxPlayers;
        address[] memory _players  = players;

        address winner = _players[winnerIndex];

        // @dev deleting balances array
        for(uint256 i; i < _maxPlayers; i++)
        {
            balances[_players[i]] = 0;
        }

        uint256 _balance = balance;
        
        // @dev Allocate the raffle fee to the raffle manager
        _balance -= RAFFLE_FEE;
        rewards[manager] += RAFFLE_FEE;

        // @dev Adding any spare funds in the contract to the raffle manager
        rewards[manager] += address(this).balance - balance;

        // @dev Allocate the eth to the winner
        rewards[winner] += _balance;

        delete players;
        balance = 0;

        isRaffleOpen = true;
        emit RequestFulfilled(requestId, randomness);
        emit WinnerSelected(winner, rewards[winner]);
    }

    // @notice This modifier ensures that only the manager can call certain functions
    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }
}