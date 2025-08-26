// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {ShopReg} from "../src/ShopReg.sol";
import {RelayReg} from "../src/RelayReg.sol";

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

    function testRevert_MintZeroAddress() public {
        vm.expectRevert();
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
        uint256 slotBalance = stdstore.target(address(shops)).sig(shops.balanceOf.selector).with_key(address(1)).find();

        uint256 balanceFirstMint = uint256(vm.load(address(shops), bytes32(slotBalance)));
        assertEq(balanceFirstMint, 1);

        shops.mint(shopId + 1, address(1));
        uint256 balanceSecondMint = uint256(vm.load(address(shops), bytes32(slotBalance)));
        assertEq(balanceSecondMint, 2);
    }

    function testRevert_accessControl() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        shops.mint(shopId, owner);
        vm.expectRevert("NOT_AUTHORIZED");
        shops.updateRootHash(shopId, testHashUpdate, 1);
    }

    function test_accessControl() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        shops.mint(shopId, owner);
        vm.prank(owner);
        shops.updateRootHash(shopId, testHashUpdate, 1);
        assertEq(testHashUpdate, shops.rootHashes(shopId));
    }

    function test_setTokenURI() public {
        address owner = address(3);
        string memory uri = "test";
        shops.mint(shopId, owner);
        vm.prank(owner);
        shops.setTokenURI(shopId, uri);
        assertEq(uri, shops.tokenURI(shopId));
    }

    function test_accessControl_fromRelay() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        shops.mint(shopId, owner);
        address relayAddr = address(42);
        uint256 relayId = 23;
        relays.mint(relayId, relayAddr, "https://smthing.somewhere");
        vm.prank(owner);
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
        vm.expectRevert("NOT_AUTHORIZED");
        vm.prank(relayAddr);
        shops.updateRootHash(shopId, testHashUpdate, 2);
    }

    function test_nonceValidation() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        shops.mint(shopId, owner);

        vm.prank(owner);
        shops.updateRootHash(shopId, testHashUpdate, 1);
        assertEq(shops.nonce(shopId), 1);

        // Should fail with same nonce
        vm.expectRevert(abi.encodeWithSelector(ShopReg.InvalidNonce.selector, 1, 1));
        vm.prank(owner);
        shops.updateRootHash(shopId, testHashUpdate, 1);

        // Should fail with lower nonce
        vm.expectRevert(abi.encodeWithSelector(ShopReg.InvalidNonce.selector, 1, 0));
        vm.prank(owner);
        shops.updateRootHash(shopId, testHashUpdate, 0);

        // Should succeed with higher nonce
        vm.prank(owner);
        shops.updateRootHash(shopId, testHashUpdate, 2);
        assertEq(shops.nonce(shopId), 2);
    }

    function test_relayManagement() public {
        address owner = address(3);
        shops.mint(shopId, owner);

        uint256 relayId1 = 1;
        uint256 relayId2 = 2;
        uint256 relayId3 = 3;

        // Add relays
        vm.startPrank(owner);
        shops.addRelay(shopId, relayId1);
        shops.addRelay(shopId, relayId2);
        shops.addRelay(shopId, relayId3);
        vm.stopPrank();

        assertEq(shops.getRelayCount(shopId), 3);

        uint256[] memory allRelays = shops.getAllRelays(shopId);
        assertEq(allRelays.length, 3);
        assertEq(allRelays[0], relayId1);
        assertEq(allRelays[1], relayId2);
        assertEq(allRelays[2], relayId3);

        // Replace relay
        uint256 newRelayId = 4;
        vm.prank(owner);
        shops.replaceRelay(shopId, 1, newRelayId);

        allRelays = shops.getAllRelays(shopId);
        assertEq(allRelays[1], newRelayId);

        // Remove relay (should move last to removed position)
        vm.prank(owner);
        shops.removeRelay(shopId, 1);

        assertEq(shops.getRelayCount(shopId), 2);
        allRelays = shops.getAllRelays(shopId);
        assertEq(allRelays[0], relayId1);
        assertEq(allRelays[1], relayId3); // relayId3 moved to position 1
    }

    function test_unauthorizedRelayManagement() public {
        address owner = address(3);
        address notOwner = address(4);
        shops.mint(shopId, owner);

        uint256 relayId = 1;

        // Should fail for non-owner
        vm.expectRevert("NOT_AUTHORIZED");
        vm.prank(notOwner);
        shops.addRelay(shopId, relayId);

        // Add relay as owner first
        vm.prank(owner);
        shops.addRelay(shopId, relayId);

        // Should fail for non-owner to replace
        vm.expectRevert("NOT_AUTHORIZED");
        vm.prank(notOwner);
        shops.replaceRelay(shopId, 0, 2);

        // Should fail for non-owner to remove
        vm.expectRevert("NOT_AUTHORIZED");
        vm.prank(notOwner);
        shops.removeRelay(shopId, 0);
    }
}