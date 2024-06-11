// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {Receiver} from "solady/src/accounts/Receiver.sol";
import {ShopReg} from "../src/ShopReg.sol";
import {RelayReg} from "../src/RelayReg.sol";
import {AccessControl} from "../src/AccessControl.sol";

contract ShopTest is Test {
    using stdStorage for StdStorage;

    ShopReg internal shops;
    RelayReg internal relays;
    bytes32 internal testHash = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
    uint256 internal shopId = 1;

    function setUp() public {
        relays = new RelayReg();
        shops = new ShopReg(relays);
    }

    function testFailMintZeroAddress() public {
        shops.mint(shopId, address(0));
    }

    function testNewMintOwnerRegistered() public {
        shops.mint(shopId, address(1));
        uint256 slotOfNewOwner = stdstore.target(address(shops)).sig(shops.ownerOf.selector).with_key(shopId).find();

        uint160 ownerOfTokenIdOne = uint160(uint256((vm.load(address(shops), bytes32(abi.encode(slotOfNewOwner))))));
        assertEq(address(ownerOfTokenIdOne), address(1));
    }

    function testBalanceIncremented() public {
        shops.mint(shopId, address(1));
        uint256 slotBalance =
            stdstore.target(address(shops)).sig(shops.balanceOf.selector).with_key(address(1)).find();

        uint256 balanceFirstMint = uint256(vm.load(address(shops), bytes32(slotBalance)));
        assertEq(balanceFirstMint, 1);

        shops.mint(shopId + 1, address(1));
        uint256 balanceSecondMint = uint256(vm.load(address(shops), bytes32(slotBalance)));
        assertEq(balanceSecondMint, 2);
    }

    function testFail_accesControl() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        shops.mint(shopId, owner);
        shops.updateRootHash(shopId, testHashUpdate, 1);
        assertEq(testHashUpdate, shops.rootHashes(shopId));
    }

    function test_accesControl() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        shops.mint(shopId, owner);
        vm.prank(owner);
        shops.updateRootHash(shopId, testHashUpdate, 1);
        assertEq(testHashUpdate, shops.rootHashes(shopId));
    }

    function test_accesControl_fromRelay() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        shops.mint(shopId, owner);
        address relayAddr = address(42);
        uint256 relayId = 23;
        relays.mint(relayId, relayAddr, "https://smthing.somewhere");
        vm.prank(owner);
        uint256[] memory newRelays = new uint256[](1);
        newRelays[0] = relayId;
        shops.addRelay(shopId, relayId);
        uint256 wantCount = 1;
        uint256 count = shops.getRelayCount(shopId);
        assertEq(count, wantCount);
        vm.prank(relayAddr);
        shops.updateRootHash(shopId, testHashUpdate, 1);
        assertEq(testHashUpdate, shops.rootHashes(shopId));
        // now remove relay and check it cant change rootHash
        vm.prank(owner);
        shops.removeRelay(shopId, 0);
        vm.expectRevert(abi.encodeWithSelector(AccessControl.NotAuthorized.selector, 2));
        vm.prank(relayAddr);
        shops.updateRootHash(shopId, testHashUpdate, 1);
    }

    function testSafeContractReceiver() public {
        Receiver receiver = new MockReceiver();
        shops.mint(shopId, address(receiver));
        uint256 slotBalance =
            stdstore.target(address(shops)).sig(shops.balanceOf.selector).with_key(address(receiver)).find();

        uint256 balance = uint256(vm.load(address(shops), bytes32(slotBalance)));
        assertEq(balance, 1);
    }
}

contract MockReceiver is Receiver {}
