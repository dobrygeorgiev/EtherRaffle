// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Raffle} from "../src/Raffle.sol";
import {Test} from "forge-std/Test.sol";

contract RaffleTest is Test {
    Raffle raffle;
    address manager = address(1);
    address player1 = address(2);
    address player2 = address(3);
    address player3 = address(4);
    address player4 = address(5);
    address player5 = address(6);


    function setUp() public {
        vm.prank(manager);
        raffle = new Raffle();
    }

    // @dev Test the enter function
    function testEnter() public {
        // @dev Simulate a player entering the raffle
        vm.deal(player1, 0.01 ether);
        vm.prank(player1);
        raffle.enter{value: 0.01 ether}();

        // @dev Verify that the player is added to the raffle
        address[] memory players = raffle.getPlayers();
        assertEq(players.length, 1);
        assertEq(players[0], player1);
    }

    function cannotEnterWhenRaffleIsFull() public {
        vm.deal(player1, 0.01 ether);
        vm.deal(player2, 0.01 ether);
        vm.deal(player3, 0.01 ether);
        vm.deal(player4, 0.01 ether);
        vm.deal(player5, 0.01 ether);

        vm.prank(player1);
        raffle.enter{value: 0.01 ether}();

        vm.prank(player2);
        raffle.enter{value: 0.01 ether}();

        vm.prank(player3);
        raffle.enter{value: 0.01 ether}();

        vm.prank(player4);
        raffle.enter{value: 0.01 ether}();

        vm.prank(player5);
        raffle.enter{value: 0.01 ether}();

        // @dev Check that there are 5 active players in the array
        address[] memory players = raffle.getPlayers();
        assertEq(players.length, 5);

        // @dev Try to add a 6th player and expect a revert
        address player6 = address(7);
        vm.deal(player6, 0.01 ether);
        vm.prank(player6);
        vm.expectRevert("Raffle is full. Please wait for the current raffle to end");
        raffle.enter{value: 0.01 ether}();
    }

    
}