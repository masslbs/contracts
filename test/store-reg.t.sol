// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "forge-std/console.sol";
import "../src/store-reg.sol";
import "../src/relay-reg.sol";

contract StoreTest is Test {
    using stdStorage for StdStorage;

    StoreReg internal stores;
    RelayReg internal relays;
    bytes32 internal testHash = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
    uint256 internal storeId = 1;

    function setUp() public {
        relays = new RelayReg();
        stores = new StoreReg(relays);
    }

    function testFailMintZeroAddress() public {
        stores.registerStore(storeId, address(0), testHash);
    }

    function testNewMintOwnerRegistered() public {
        stores.registerStore(storeId, address(1), testHash);
        uint256 slotOfNewOwner = stdstore
            .target(address(stores))
            .sig(stores.ownerOf.selector)
            .with_key(storeId)
            .find();

        uint160 ownerOfTokenIdOne = uint160(
            uint256(
                (vm.load(address(stores), bytes32(abi.encode(slotOfNewOwner))))
            )
        );
        assertEq(address(ownerOfTokenIdOne), address(1));
    }

    function testBalanceIncremented() public {
        stores.registerStore(storeId, address(1), testHash);
        uint256 slotBalance = stdstore
            .target(address(stores))
            .sig(stores.balanceOf.selector)
            .with_key(address(1))
            .find();

        uint256 balanceFirstMint = uint256(
            vm.load(address(stores), bytes32(slotBalance))
        );
        assertEq(balanceFirstMint, 1);

        stores.registerStore(storeId+1, address(1), testHash);
        uint256 balanceSecondMint = uint256(
            vm.load(address(stores), bytes32(slotBalance))
        );
        assertEq(balanceSecondMint, 2);
    }

    function testFail_accesControl() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        stores.registerStore(storeId, owner, testHash);
        stores.updateRootHash(storeId, testHashUpdate);
        assertEq(testHashUpdate, stores.rootHashes(storeId));
    }

    function test_accesControl() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        stores.registerStore(storeId, owner, testHash);
        vm.prank(owner);
        stores.updateRootHash(storeId, testHashUpdate);
        assertEq(testHashUpdate, stores.rootHashes(storeId));
    }

    function test_accesControl_fromRelay() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        stores.registerStore(storeId, owner, testHash);
        address relayAddr = address(42);
        uint256 relayId = 23;
        relays.registerRelay(relayId, relayAddr, "https://smthing.somewhere");
        vm.prank(owner);
        uint256[] memory newRelays = new uint256[](1);
        newRelays[0] = relayId;
        stores.updateRelays(storeId, newRelays);
        uint256 wantCount = 1;
        uint256 count = stores.getRelayCount(storeId);
        assertEq(count, wantCount);
        uint256[] memory gotRelays = stores.getAllRelays(storeId);
        assertEq(gotRelays.length, wantCount);
        assertEq(gotRelays[0], relayId);
        vm.prank(relayAddr);
        stores.updateRootHash(storeId, testHashUpdate);
        assertEq(testHashUpdate, stores.rootHashes(storeId));
        // now remove relay and check it cant change rootHash
        vm.prank(owner);
        stores.updateRelays(storeId, new uint256[](0));
        vm.expectRevert("access denied");
        vm.prank(relayAddr);
        stores.updateRootHash(storeId, testHashUpdate);
    }

    function testSafeContractReceiver() public {
        Receiver receiver = new Receiver();
        stores.registerStore(storeId, address(receiver), testHash);
        uint256 slotBalance = stdstore
            .target(address(stores))
            .sig(stores.balanceOf.selector)
            .with_key(address(receiver))
            .find();

        uint256 balance = uint256(vm.load(address(stores), bytes32(slotBalance)));
        assertEq(balance, 1);
    }
}


contract Receiver is IERC721Receiver {
    function onERC721Received(address,address,uint256,bytes calldata)
        external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

