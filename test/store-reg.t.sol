// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "forge-std/console.sol";
import "../src/store-reg.sol";
import "../src/relay-reg.sol";

contract StoreTest is Test {
    using stdStorage for StdStorage;

    Store internal store;
    RelayReg internal relayReg;
    bytes32 internal testHash = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;

    function setUp() public {
        relayReg = new RelayReg();
        // Deploy NFT contract
        store = new Store(relayReg);
    }

    function testFailMintZeroAddress() public {
        store.mint(address(0), testHash);
    }

    function testNewMintOwnerRegistered() public {
        uint256 store_id = store.mint(address(1), testHash);
        uint256 slotOfNewOwner = stdstore
            .target(address(store))
            .sig(store.ownerOf.selector)
            .with_key(store_id)
            .find();

        uint160 ownerOfTokenIdOne = uint160(
            uint256(
                (vm.load(address(store), bytes32(abi.encode(slotOfNewOwner))))
            )
        );
        assertEq(address(ownerOfTokenIdOne), address(1));
    }

    function testBalanceIncremented() public {
        store.mint(address(1), testHash);
        uint256 slotBalance = stdstore
            .target(address(store))
            .sig(store.balanceOf.selector)
            .with_key(address(1))
            .find();

        uint256 balanceFirstMint = uint256(
            vm.load(address(store), bytes32(slotBalance))
        );
        assertEq(balanceFirstMint, 1);

        store.mint(address(1), testHash);
        uint256 balanceSecondMint = uint256(
            vm.load(address(store), bytes32(slotBalance))
        );
        assertEq(balanceSecondMint, 2);
    }

    function testFail_accesControl() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        uint256 storeId = store.mint(owner, testHash);
        store.updateRootHash(storeId, testHashUpdate);
        assertEq(testHashUpdate, store.rootHashes(storeId));
    }

    function test_accesControl() public {
        bytes32 testHashUpdate = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;
        address owner = address(3);
        uint256 storeId = store.mint(owner, testHash);
        vm.prank(owner);
        store.updateRootHash(storeId, testHashUpdate);
        assertEq(testHashUpdate, store.rootHashes(storeId));
    }

    function testSafeContractReceiver() public {
        Receiver receiver = new Receiver();
        store.mint(address(receiver), testHash);
        uint256 slotBalance = stdstore
            .target(address(store))
            .sig(store.balanceOf.selector)
            .with_key(address(receiver))
            .find();

        uint256 balance = uint256(vm.load(address(store), bytes32(slotBalance)));
        assertEq(balance, 1);
    }
}


contract Receiver is IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

