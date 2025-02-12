// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {IHorseStore} from "../../src/horseStoreV1/IHorseStore.sol";
import {HorseStore} from "../../src/horseStoreV1/HorseStore.sol";

abstract contract Base_TestV1 is Test {
    IHorseStore public horseStore;

    function setUp() public virtual {
        horseStore = IHorseStore(address(new HorseStore()));
    }

    function testReadValue() public view {
        uint256 initialValue = horseStore.readNumberOfHorses();
        assertEq(initialValue, 0);
    }

    function testWriteValue(uint256 newValue) public {
        horseStore.updateHorseNumber(newValue);
        uint256 updatedValue = horseStore.readNumberOfHorses();
        assertEq(updatedValue, newValue);
    }
}
