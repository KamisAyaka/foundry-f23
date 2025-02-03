// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployBox} from "script/DeployBox.s.sol";
import {UpgradeBox} from "script/UpgradeBox.s.sol";
import {BoxV1} from "src/BoxV1.sol";
import {BoxV2} from "src/BoxV2.sol";

contract DeployAndUpgradeTest is Test {
    DeployBox public deployer;
    UpgradeBox public upgrader;
    address public OWNER = makeAddr("owner");

    address public proxy;

    function setUp() public {
        deployer = new DeployBox();
        upgrader = new UpgradeBox();
        proxy = deployer.run(); // right now, proxy is pointing to BoxV1
    }

    function testProxyStartsAsBoxV1() public view {
        assertEq(1, BoxV1(proxy).version());
    }

    function testUpgrade() public {
        BoxV2 boxV2 = new BoxV2();
        upgrader.upgradeBox(proxy, address(boxV2));

        uint256 expectedVersion = 2;
        assertEq(expectedVersion, BoxV2(proxy).version());

        BoxV2(proxy).setNumber(7);
        assertEq(7, BoxV2(proxy).getNumber());
    }
}
