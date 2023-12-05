// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package main

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// RegStoreMetaData contains all meta data concerning the RegStore contract.
var RegStoreMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[{\"internalType\":\"contractRelayReg\",\"name\":\"r\",\"type\":\"address\"}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"}],\"name\":\"ERC721IncorrectOwner\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"ERC721InsufficientApproval\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"approver\",\"type\":\"address\"}],\"name\":\"ERC721InvalidApprover\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"}],\"name\":\"ERC721InvalidOperator\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"}],\"name\":\"ERC721InvalidOwner\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"receiver\",\"type\":\"address\"}],\"name\":\"ERC721InvalidReceiver\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"}],\"name\":\"ERC721InvalidSender\",\"type\":\"error\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"ERC721NonexistentToken\",\"type\":\"error\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"approved\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"Approval\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"bool\",\"name\":\"approved\",\"type\":\"bool\"}],\"name\":\"ApprovalForAll\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"Transfer\",\"type\":\"event\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"approve\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"}],\"name\":\"balanceOf\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"getApproved\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"storeId\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"addr\",\"type\":\"address\"},{\"internalType\":\"enumAccessLevel\",\"name\":\"want\",\"type\":\"uint8\"}],\"name\":\"hasAtLeastAccess\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"}],\"name\":\"isApprovedForAll\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"name\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"ownerOf\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"storeId\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"internalType\":\"bytes32\",\"name\":\"rootHash\",\"type\":\"bytes32\"}],\"name\":\"registerStore\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"storeId\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"addr\",\"type\":\"address\"},{\"internalType\":\"enumAccessLevel\",\"name\":\"acl\",\"type\":\"uint8\"}],\"name\":\"registerUser\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"relayReg\",\"outputs\":[{\"internalType\":\"contractRelayReg\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"relays\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"storeId\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"who\",\"type\":\"address\"}],\"name\":\"removeUser\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"storeId\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"who\",\"type\":\"address\"}],\"name\":\"requireOnlyAdminOrHigher\",\"outputs\":[],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"name\":\"rootHashes\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"safeTransferFrom\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"},{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\"}],\"name\":\"safeTransferFrom\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"operator\",\"type\":\"address\"},{\"internalType\":\"bool\",\"name\":\"approved\",\"type\":\"bool\"}],\"name\":\"setApprovalForAll\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"name\":\"storesToUsers\",\"outputs\":[{\"internalType\":\"enumAccessLevel\",\"name\":\"\",\"type\":\"uint8\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes4\",\"name\":\"interfaceId\",\"type\":\"bytes4\"}],\"name\":\"supportsInterface\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"symbol\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"tokenURI\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"}],\"name\":\"transferFrom\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"storeId\",\"type\":\"uint256\"},{\"internalType\":\"uint256[]\",\"name\":\"_relays\",\"type\":\"uint256[]\"}],\"name\":\"updateRelays\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"storeId\",\"type\":\"uint256\"},{\"internalType\":\"bytes32\",\"name\":\"hash\",\"type\":\"bytes32\"}],\"name\":\"updateRootHash\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]",
}

// RegStoreABI is the input ABI used to generate the binding from.
// Deprecated: Use RegStoreMetaData.ABI instead.
var RegStoreABI = RegStoreMetaData.ABI

// RegStore is an auto generated Go binding around an Ethereum contract.
type RegStore struct {
	RegStoreCaller     // Read-only binding to the contract
	RegStoreTransactor // Write-only binding to the contract
	RegStoreFilterer   // Log filterer for contract events
}

// RegStoreCaller is an auto generated read-only Go binding around an Ethereum contract.
type RegStoreCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RegStoreTransactor is an auto generated write-only Go binding around an Ethereum contract.
type RegStoreTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RegStoreFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type RegStoreFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// RegStoreSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type RegStoreSession struct {
	Contract     *RegStore         // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// RegStoreCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type RegStoreCallerSession struct {
	Contract *RegStoreCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts   // Call options to use throughout this session
}

// RegStoreTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type RegStoreTransactorSession struct {
	Contract     *RegStoreTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// RegStoreRaw is an auto generated low-level Go binding around an Ethereum contract.
type RegStoreRaw struct {
	Contract *RegStore // Generic contract binding to access the raw methods on
}

// RegStoreCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type RegStoreCallerRaw struct {
	Contract *RegStoreCaller // Generic read-only contract binding to access the raw methods on
}

// RegStoreTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type RegStoreTransactorRaw struct {
	Contract *RegStoreTransactor // Generic write-only contract binding to access the raw methods on
}

// NewRegStore creates a new instance of RegStore, bound to a specific deployed contract.
func NewRegStore(address common.Address, backend bind.ContractBackend) (*RegStore, error) {
	contract, err := bindRegStore(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &RegStore{RegStoreCaller: RegStoreCaller{contract: contract}, RegStoreTransactor: RegStoreTransactor{contract: contract}, RegStoreFilterer: RegStoreFilterer{contract: contract}}, nil
}

// NewRegStoreCaller creates a new read-only instance of RegStore, bound to a specific deployed contract.
func NewRegStoreCaller(address common.Address, caller bind.ContractCaller) (*RegStoreCaller, error) {
	contract, err := bindRegStore(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &RegStoreCaller{contract: contract}, nil
}

// NewRegStoreTransactor creates a new write-only instance of RegStore, bound to a specific deployed contract.
func NewRegStoreTransactor(address common.Address, transactor bind.ContractTransactor) (*RegStoreTransactor, error) {
	contract, err := bindRegStore(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &RegStoreTransactor{contract: contract}, nil
}

// NewRegStoreFilterer creates a new log filterer instance of RegStore, bound to a specific deployed contract.
func NewRegStoreFilterer(address common.Address, filterer bind.ContractFilterer) (*RegStoreFilterer, error) {
	contract, err := bindRegStore(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &RegStoreFilterer{contract: contract}, nil
}

// bindRegStore binds a generic wrapper to an already deployed contract.
func bindRegStore(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := RegStoreMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RegStore *RegStoreRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RegStore.Contract.RegStoreCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RegStore *RegStoreRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RegStore.Contract.RegStoreTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RegStore *RegStoreRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RegStore.Contract.RegStoreTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_RegStore *RegStoreCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _RegStore.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_RegStore *RegStoreTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _RegStore.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_RegStore *RegStoreTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _RegStore.Contract.contract.Transact(opts, method, params...)
}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address owner) view returns(uint256)
func (_RegStore *RegStoreCaller) BalanceOf(opts *bind.CallOpts, owner common.Address) (*big.Int, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "balanceOf", owner)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address owner) view returns(uint256)
func (_RegStore *RegStoreSession) BalanceOf(owner common.Address) (*big.Int, error) {
	return _RegStore.Contract.BalanceOf(&_RegStore.CallOpts, owner)
}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address owner) view returns(uint256)
func (_RegStore *RegStoreCallerSession) BalanceOf(owner common.Address) (*big.Int, error) {
	return _RegStore.Contract.BalanceOf(&_RegStore.CallOpts, owner)
}

// GetApproved is a free data retrieval call binding the contract method 0x081812fc.
//
// Solidity: function getApproved(uint256 tokenId) view returns(address)
func (_RegStore *RegStoreCaller) GetApproved(opts *bind.CallOpts, tokenId *big.Int) (common.Address, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "getApproved", tokenId)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// GetApproved is a free data retrieval call binding the contract method 0x081812fc.
//
// Solidity: function getApproved(uint256 tokenId) view returns(address)
func (_RegStore *RegStoreSession) GetApproved(tokenId *big.Int) (common.Address, error) {
	return _RegStore.Contract.GetApproved(&_RegStore.CallOpts, tokenId)
}

// GetApproved is a free data retrieval call binding the contract method 0x081812fc.
//
// Solidity: function getApproved(uint256 tokenId) view returns(address)
func (_RegStore *RegStoreCallerSession) GetApproved(tokenId *big.Int) (common.Address, error) {
	return _RegStore.Contract.GetApproved(&_RegStore.CallOpts, tokenId)
}

// HasAtLeastAccess is a free data retrieval call binding the contract method 0x45174ff3.
//
// Solidity: function hasAtLeastAccess(uint256 storeId, address addr, uint8 want) view returns(bool)
func (_RegStore *RegStoreCaller) HasAtLeastAccess(opts *bind.CallOpts, storeId *big.Int, addr common.Address, want uint8) (bool, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "hasAtLeastAccess", storeId, addr, want)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// HasAtLeastAccess is a free data retrieval call binding the contract method 0x45174ff3.
//
// Solidity: function hasAtLeastAccess(uint256 storeId, address addr, uint8 want) view returns(bool)
func (_RegStore *RegStoreSession) HasAtLeastAccess(storeId *big.Int, addr common.Address, want uint8) (bool, error) {
	return _RegStore.Contract.HasAtLeastAccess(&_RegStore.CallOpts, storeId, addr, want)
}

// HasAtLeastAccess is a free data retrieval call binding the contract method 0x45174ff3.
//
// Solidity: function hasAtLeastAccess(uint256 storeId, address addr, uint8 want) view returns(bool)
func (_RegStore *RegStoreCallerSession) HasAtLeastAccess(storeId *big.Int, addr common.Address, want uint8) (bool, error) {
	return _RegStore.Contract.HasAtLeastAccess(&_RegStore.CallOpts, storeId, addr, want)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address owner, address operator) view returns(bool)
func (_RegStore *RegStoreCaller) IsApprovedForAll(opts *bind.CallOpts, owner common.Address, operator common.Address) (bool, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "isApprovedForAll", owner, operator)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address owner, address operator) view returns(bool)
func (_RegStore *RegStoreSession) IsApprovedForAll(owner common.Address, operator common.Address) (bool, error) {
	return _RegStore.Contract.IsApprovedForAll(&_RegStore.CallOpts, owner, operator)
}

// IsApprovedForAll is a free data retrieval call binding the contract method 0xe985e9c5.
//
// Solidity: function isApprovedForAll(address owner, address operator) view returns(bool)
func (_RegStore *RegStoreCallerSession) IsApprovedForAll(owner common.Address, operator common.Address) (bool, error) {
	return _RegStore.Contract.IsApprovedForAll(&_RegStore.CallOpts, owner, operator)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_RegStore *RegStoreCaller) Name(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "name")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_RegStore *RegStoreSession) Name() (string, error) {
	return _RegStore.Contract.Name(&_RegStore.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_RegStore *RegStoreCallerSession) Name() (string, error) {
	return _RegStore.Contract.Name(&_RegStore.CallOpts)
}

// OwnerOf is a free data retrieval call binding the contract method 0x6352211e.
//
// Solidity: function ownerOf(uint256 tokenId) view returns(address)
func (_RegStore *RegStoreCaller) OwnerOf(opts *bind.CallOpts, tokenId *big.Int) (common.Address, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "ownerOf", tokenId)

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// OwnerOf is a free data retrieval call binding the contract method 0x6352211e.
//
// Solidity: function ownerOf(uint256 tokenId) view returns(address)
func (_RegStore *RegStoreSession) OwnerOf(tokenId *big.Int) (common.Address, error) {
	return _RegStore.Contract.OwnerOf(&_RegStore.CallOpts, tokenId)
}

// OwnerOf is a free data retrieval call binding the contract method 0x6352211e.
//
// Solidity: function ownerOf(uint256 tokenId) view returns(address)
func (_RegStore *RegStoreCallerSession) OwnerOf(tokenId *big.Int) (common.Address, error) {
	return _RegStore.Contract.OwnerOf(&_RegStore.CallOpts, tokenId)
}

// RelayReg is a free data retrieval call binding the contract method 0x38887dde.
//
// Solidity: function relayReg() view returns(address)
func (_RegStore *RegStoreCaller) RelayReg(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "relayReg")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// RelayReg is a free data retrieval call binding the contract method 0x38887dde.
//
// Solidity: function relayReg() view returns(address)
func (_RegStore *RegStoreSession) RelayReg() (common.Address, error) {
	return _RegStore.Contract.RelayReg(&_RegStore.CallOpts)
}

// RelayReg is a free data retrieval call binding the contract method 0x38887dde.
//
// Solidity: function relayReg() view returns(address)
func (_RegStore *RegStoreCallerSession) RelayReg() (common.Address, error) {
	return _RegStore.Contract.RelayReg(&_RegStore.CallOpts)
}

// Relays is a free data retrieval call binding the contract method 0xb08cfd15.
//
// Solidity: function relays(uint256 , uint256 ) view returns(uint256)
func (_RegStore *RegStoreCaller) Relays(opts *bind.CallOpts, arg0 *big.Int, arg1 *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "relays", arg0, arg1)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Relays is a free data retrieval call binding the contract method 0xb08cfd15.
//
// Solidity: function relays(uint256 , uint256 ) view returns(uint256)
func (_RegStore *RegStoreSession) Relays(arg0 *big.Int, arg1 *big.Int) (*big.Int, error) {
	return _RegStore.Contract.Relays(&_RegStore.CallOpts, arg0, arg1)
}

// Relays is a free data retrieval call binding the contract method 0xb08cfd15.
//
// Solidity: function relays(uint256 , uint256 ) view returns(uint256)
func (_RegStore *RegStoreCallerSession) Relays(arg0 *big.Int, arg1 *big.Int) (*big.Int, error) {
	return _RegStore.Contract.Relays(&_RegStore.CallOpts, arg0, arg1)
}

// RequireOnlyAdminOrHigher is a free data retrieval call binding the contract method 0x385b38bb.
//
// Solidity: function requireOnlyAdminOrHigher(uint256 storeId, address who) view returns()
func (_RegStore *RegStoreCaller) RequireOnlyAdminOrHigher(opts *bind.CallOpts, storeId *big.Int, who common.Address) error {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "requireOnlyAdminOrHigher", storeId, who)

	if err != nil {
		return err
	}

	return err

}

// RequireOnlyAdminOrHigher is a free data retrieval call binding the contract method 0x385b38bb.
//
// Solidity: function requireOnlyAdminOrHigher(uint256 storeId, address who) view returns()
func (_RegStore *RegStoreSession) RequireOnlyAdminOrHigher(storeId *big.Int, who common.Address) error {
	return _RegStore.Contract.RequireOnlyAdminOrHigher(&_RegStore.CallOpts, storeId, who)
}

// RequireOnlyAdminOrHigher is a free data retrieval call binding the contract method 0x385b38bb.
//
// Solidity: function requireOnlyAdminOrHigher(uint256 storeId, address who) view returns()
func (_RegStore *RegStoreCallerSession) RequireOnlyAdminOrHigher(storeId *big.Int, who common.Address) error {
	return _RegStore.Contract.RequireOnlyAdminOrHigher(&_RegStore.CallOpts, storeId, who)
}

// RootHashes is a free data retrieval call binding the contract method 0x53b93557.
//
// Solidity: function rootHashes(uint256 ) view returns(bytes32)
func (_RegStore *RegStoreCaller) RootHashes(opts *bind.CallOpts, arg0 *big.Int) ([32]byte, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "rootHashes", arg0)

	if err != nil {
		return *new([32]byte), err
	}

	out0 := *abi.ConvertType(out[0], new([32]byte)).(*[32]byte)

	return out0, err

}

// RootHashes is a free data retrieval call binding the contract method 0x53b93557.
//
// Solidity: function rootHashes(uint256 ) view returns(bytes32)
func (_RegStore *RegStoreSession) RootHashes(arg0 *big.Int) ([32]byte, error) {
	return _RegStore.Contract.RootHashes(&_RegStore.CallOpts, arg0)
}

// RootHashes is a free data retrieval call binding the contract method 0x53b93557.
//
// Solidity: function rootHashes(uint256 ) view returns(bytes32)
func (_RegStore *RegStoreCallerSession) RootHashes(arg0 *big.Int) ([32]byte, error) {
	return _RegStore.Contract.RootHashes(&_RegStore.CallOpts, arg0)
}

// StoresToUsers is a free data retrieval call binding the contract method 0xb253af66.
//
// Solidity: function storesToUsers(uint256 , address ) view returns(uint8)
func (_RegStore *RegStoreCaller) StoresToUsers(opts *bind.CallOpts, arg0 *big.Int, arg1 common.Address) (uint8, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "storesToUsers", arg0, arg1)

	if err != nil {
		return *new(uint8), err
	}

	out0 := *abi.ConvertType(out[0], new(uint8)).(*uint8)

	return out0, err

}

// StoresToUsers is a free data retrieval call binding the contract method 0xb253af66.
//
// Solidity: function storesToUsers(uint256 , address ) view returns(uint8)
func (_RegStore *RegStoreSession) StoresToUsers(arg0 *big.Int, arg1 common.Address) (uint8, error) {
	return _RegStore.Contract.StoresToUsers(&_RegStore.CallOpts, arg0, arg1)
}

// StoresToUsers is a free data retrieval call binding the contract method 0xb253af66.
//
// Solidity: function storesToUsers(uint256 , address ) view returns(uint8)
func (_RegStore *RegStoreCallerSession) StoresToUsers(arg0 *big.Int, arg1 common.Address) (uint8, error) {
	return _RegStore.Contract.StoresToUsers(&_RegStore.CallOpts, arg0, arg1)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_RegStore *RegStoreCaller) SupportsInterface(opts *bind.CallOpts, interfaceId [4]byte) (bool, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "supportsInterface", interfaceId)

	if err != nil {
		return *new(bool), err
	}

	out0 := *abi.ConvertType(out[0], new(bool)).(*bool)

	return out0, err

}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_RegStore *RegStoreSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _RegStore.Contract.SupportsInterface(&_RegStore.CallOpts, interfaceId)
}

// SupportsInterface is a free data retrieval call binding the contract method 0x01ffc9a7.
//
// Solidity: function supportsInterface(bytes4 interfaceId) view returns(bool)
func (_RegStore *RegStoreCallerSession) SupportsInterface(interfaceId [4]byte) (bool, error) {
	return _RegStore.Contract.SupportsInterface(&_RegStore.CallOpts, interfaceId)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_RegStore *RegStoreCaller) Symbol(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "symbol")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_RegStore *RegStoreSession) Symbol() (string, error) {
	return _RegStore.Contract.Symbol(&_RegStore.CallOpts)
}

// Symbol is a free data retrieval call binding the contract method 0x95d89b41.
//
// Solidity: function symbol() view returns(string)
func (_RegStore *RegStoreCallerSession) Symbol() (string, error) {
	return _RegStore.Contract.Symbol(&_RegStore.CallOpts)
}

// TokenURI is a free data retrieval call binding the contract method 0xc87b56dd.
//
// Solidity: function tokenURI(uint256 tokenId) view returns(string)
func (_RegStore *RegStoreCaller) TokenURI(opts *bind.CallOpts, tokenId *big.Int) (string, error) {
	var out []interface{}
	err := _RegStore.contract.Call(opts, &out, "tokenURI", tokenId)

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// TokenURI is a free data retrieval call binding the contract method 0xc87b56dd.
//
// Solidity: function tokenURI(uint256 tokenId) view returns(string)
func (_RegStore *RegStoreSession) TokenURI(tokenId *big.Int) (string, error) {
	return _RegStore.Contract.TokenURI(&_RegStore.CallOpts, tokenId)
}

// TokenURI is a free data retrieval call binding the contract method 0xc87b56dd.
//
// Solidity: function tokenURI(uint256 tokenId) view returns(string)
func (_RegStore *RegStoreCallerSession) TokenURI(tokenId *big.Int) (string, error) {
	return _RegStore.Contract.TokenURI(&_RegStore.CallOpts, tokenId)
}

// Approve is a paid mutator transaction binding the contract method 0x095ea7b3.
//
// Solidity: function approve(address to, uint256 tokenId) returns()
func (_RegStore *RegStoreTransactor) Approve(opts *bind.TransactOpts, to common.Address, tokenId *big.Int) (*types.Transaction, error) {
	return _RegStore.contract.Transact(opts, "approve", to, tokenId)
}

// Approve is a paid mutator transaction binding the contract method 0x095ea7b3.
//
// Solidity: function approve(address to, uint256 tokenId) returns()
func (_RegStore *RegStoreSession) Approve(to common.Address, tokenId *big.Int) (*types.Transaction, error) {
	return _RegStore.Contract.Approve(&_RegStore.TransactOpts, to, tokenId)
}

// Approve is a paid mutator transaction binding the contract method 0x095ea7b3.
//
// Solidity: function approve(address to, uint256 tokenId) returns()
func (_RegStore *RegStoreTransactorSession) Approve(to common.Address, tokenId *big.Int) (*types.Transaction, error) {
	return _RegStore.Contract.Approve(&_RegStore.TransactOpts, to, tokenId)
}

// RegisterStore is a paid mutator transaction binding the contract method 0x6238a220.
//
// Solidity: function registerStore(uint256 storeId, address owner, bytes32 rootHash) returns()
func (_RegStore *RegStoreTransactor) RegisterStore(opts *bind.TransactOpts, storeId *big.Int, owner common.Address, rootHash [32]byte) (*types.Transaction, error) {
	return _RegStore.contract.Transact(opts, "registerStore", storeId, owner, rootHash)
}

// RegisterStore is a paid mutator transaction binding the contract method 0x6238a220.
//
// Solidity: function registerStore(uint256 storeId, address owner, bytes32 rootHash) returns()
func (_RegStore *RegStoreSession) RegisterStore(storeId *big.Int, owner common.Address, rootHash [32]byte) (*types.Transaction, error) {
	return _RegStore.Contract.RegisterStore(&_RegStore.TransactOpts, storeId, owner, rootHash)
}

// RegisterStore is a paid mutator transaction binding the contract method 0x6238a220.
//
// Solidity: function registerStore(uint256 storeId, address owner, bytes32 rootHash) returns()
func (_RegStore *RegStoreTransactorSession) RegisterStore(storeId *big.Int, owner common.Address, rootHash [32]byte) (*types.Transaction, error) {
	return _RegStore.Contract.RegisterStore(&_RegStore.TransactOpts, storeId, owner, rootHash)
}

// RegisterUser is a paid mutator transaction binding the contract method 0x3785096a.
//
// Solidity: function registerUser(uint256 storeId, address addr, uint8 acl) returns()
func (_RegStore *RegStoreTransactor) RegisterUser(opts *bind.TransactOpts, storeId *big.Int, addr common.Address, acl uint8) (*types.Transaction, error) {
	return _RegStore.contract.Transact(opts, "registerUser", storeId, addr, acl)
}

// RegisterUser is a paid mutator transaction binding the contract method 0x3785096a.
//
// Solidity: function registerUser(uint256 storeId, address addr, uint8 acl) returns()
func (_RegStore *RegStoreSession) RegisterUser(storeId *big.Int, addr common.Address, acl uint8) (*types.Transaction, error) {
	return _RegStore.Contract.RegisterUser(&_RegStore.TransactOpts, storeId, addr, acl)
}

// RegisterUser is a paid mutator transaction binding the contract method 0x3785096a.
//
// Solidity: function registerUser(uint256 storeId, address addr, uint8 acl) returns()
func (_RegStore *RegStoreTransactorSession) RegisterUser(storeId *big.Int, addr common.Address, acl uint8) (*types.Transaction, error) {
	return _RegStore.Contract.RegisterUser(&_RegStore.TransactOpts, storeId, addr, acl)
}

// RemoveUser is a paid mutator transaction binding the contract method 0x0c8f91a9.
//
// Solidity: function removeUser(uint256 storeId, address who) returns()
func (_RegStore *RegStoreTransactor) RemoveUser(opts *bind.TransactOpts, storeId *big.Int, who common.Address) (*types.Transaction, error) {
	return _RegStore.contract.Transact(opts, "removeUser", storeId, who)
}

// RemoveUser is a paid mutator transaction binding the contract method 0x0c8f91a9.
//
// Solidity: function removeUser(uint256 storeId, address who) returns()
func (_RegStore *RegStoreSession) RemoveUser(storeId *big.Int, who common.Address) (*types.Transaction, error) {
	return _RegStore.Contract.RemoveUser(&_RegStore.TransactOpts, storeId, who)
}

// RemoveUser is a paid mutator transaction binding the contract method 0x0c8f91a9.
//
// Solidity: function removeUser(uint256 storeId, address who) returns()
func (_RegStore *RegStoreTransactorSession) RemoveUser(storeId *big.Int, who common.Address) (*types.Transaction, error) {
	return _RegStore.Contract.RemoveUser(&_RegStore.TransactOpts, storeId, who)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0x42842e0e.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 tokenId) returns()
func (_RegStore *RegStoreTransactor) SafeTransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, tokenId *big.Int) (*types.Transaction, error) {
	return _RegStore.contract.Transact(opts, "safeTransferFrom", from, to, tokenId)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0x42842e0e.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 tokenId) returns()
func (_RegStore *RegStoreSession) SafeTransferFrom(from common.Address, to common.Address, tokenId *big.Int) (*types.Transaction, error) {
	return _RegStore.Contract.SafeTransferFrom(&_RegStore.TransactOpts, from, to, tokenId)
}

// SafeTransferFrom is a paid mutator transaction binding the contract method 0x42842e0e.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 tokenId) returns()
func (_RegStore *RegStoreTransactorSession) SafeTransferFrom(from common.Address, to common.Address, tokenId *big.Int) (*types.Transaction, error) {
	return _RegStore.Contract.SafeTransferFrom(&_RegStore.TransactOpts, from, to, tokenId)
}

// SafeTransferFrom0 is a paid mutator transaction binding the contract method 0xb88d4fde.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) returns()
func (_RegStore *RegStoreTransactor) SafeTransferFrom0(opts *bind.TransactOpts, from common.Address, to common.Address, tokenId *big.Int, data []byte) (*types.Transaction, error) {
	return _RegStore.contract.Transact(opts, "safeTransferFrom0", from, to, tokenId, data)
}

// SafeTransferFrom0 is a paid mutator transaction binding the contract method 0xb88d4fde.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) returns()
func (_RegStore *RegStoreSession) SafeTransferFrom0(from common.Address, to common.Address, tokenId *big.Int, data []byte) (*types.Transaction, error) {
	return _RegStore.Contract.SafeTransferFrom0(&_RegStore.TransactOpts, from, to, tokenId, data)
}

// SafeTransferFrom0 is a paid mutator transaction binding the contract method 0xb88d4fde.
//
// Solidity: function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) returns()
func (_RegStore *RegStoreTransactorSession) SafeTransferFrom0(from common.Address, to common.Address, tokenId *big.Int, data []byte) (*types.Transaction, error) {
	return _RegStore.Contract.SafeTransferFrom0(&_RegStore.TransactOpts, from, to, tokenId, data)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_RegStore *RegStoreTransactor) SetApprovalForAll(opts *bind.TransactOpts, operator common.Address, approved bool) (*types.Transaction, error) {
	return _RegStore.contract.Transact(opts, "setApprovalForAll", operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_RegStore *RegStoreSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _RegStore.Contract.SetApprovalForAll(&_RegStore.TransactOpts, operator, approved)
}

// SetApprovalForAll is a paid mutator transaction binding the contract method 0xa22cb465.
//
// Solidity: function setApprovalForAll(address operator, bool approved) returns()
func (_RegStore *RegStoreTransactorSession) SetApprovalForAll(operator common.Address, approved bool) (*types.Transaction, error) {
	return _RegStore.Contract.SetApprovalForAll(&_RegStore.TransactOpts, operator, approved)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 tokenId) returns()
func (_RegStore *RegStoreTransactor) TransferFrom(opts *bind.TransactOpts, from common.Address, to common.Address, tokenId *big.Int) (*types.Transaction, error) {
	return _RegStore.contract.Transact(opts, "transferFrom", from, to, tokenId)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 tokenId) returns()
func (_RegStore *RegStoreSession) TransferFrom(from common.Address, to common.Address, tokenId *big.Int) (*types.Transaction, error) {
	return _RegStore.Contract.TransferFrom(&_RegStore.TransactOpts, from, to, tokenId)
}

// TransferFrom is a paid mutator transaction binding the contract method 0x23b872dd.
//
// Solidity: function transferFrom(address from, address to, uint256 tokenId) returns()
func (_RegStore *RegStoreTransactorSession) TransferFrom(from common.Address, to common.Address, tokenId *big.Int) (*types.Transaction, error) {
	return _RegStore.Contract.TransferFrom(&_RegStore.TransactOpts, from, to, tokenId)
}

// UpdateRelays is a paid mutator transaction binding the contract method 0xdca1a5a9.
//
// Solidity: function updateRelays(uint256 storeId, uint256[] _relays) returns()
func (_RegStore *RegStoreTransactor) UpdateRelays(opts *bind.TransactOpts, storeId *big.Int, _relays []*big.Int) (*types.Transaction, error) {
	return _RegStore.contract.Transact(opts, "updateRelays", storeId, _relays)
}

// UpdateRelays is a paid mutator transaction binding the contract method 0xdca1a5a9.
//
// Solidity: function updateRelays(uint256 storeId, uint256[] _relays) returns()
func (_RegStore *RegStoreSession) UpdateRelays(storeId *big.Int, _relays []*big.Int) (*types.Transaction, error) {
	return _RegStore.Contract.UpdateRelays(&_RegStore.TransactOpts, storeId, _relays)
}

// UpdateRelays is a paid mutator transaction binding the contract method 0xdca1a5a9.
//
// Solidity: function updateRelays(uint256 storeId, uint256[] _relays) returns()
func (_RegStore *RegStoreTransactorSession) UpdateRelays(storeId *big.Int, _relays []*big.Int) (*types.Transaction, error) {
	return _RegStore.Contract.UpdateRelays(&_RegStore.TransactOpts, storeId, _relays)
}

// UpdateRootHash is a paid mutator transaction binding the contract method 0xd5e0bb66.
//
// Solidity: function updateRootHash(uint256 storeId, bytes32 hash) returns()
func (_RegStore *RegStoreTransactor) UpdateRootHash(opts *bind.TransactOpts, storeId *big.Int, hash [32]byte) (*types.Transaction, error) {
	return _RegStore.contract.Transact(opts, "updateRootHash", storeId, hash)
}

// UpdateRootHash is a paid mutator transaction binding the contract method 0xd5e0bb66.
//
// Solidity: function updateRootHash(uint256 storeId, bytes32 hash) returns()
func (_RegStore *RegStoreSession) UpdateRootHash(storeId *big.Int, hash [32]byte) (*types.Transaction, error) {
	return _RegStore.Contract.UpdateRootHash(&_RegStore.TransactOpts, storeId, hash)
}

// UpdateRootHash is a paid mutator transaction binding the contract method 0xd5e0bb66.
//
// Solidity: function updateRootHash(uint256 storeId, bytes32 hash) returns()
func (_RegStore *RegStoreTransactorSession) UpdateRootHash(storeId *big.Int, hash [32]byte) (*types.Transaction, error) {
	return _RegStore.Contract.UpdateRootHash(&_RegStore.TransactOpts, storeId, hash)
}

// RegStoreApprovalIterator is returned from FilterApproval and is used to iterate over the raw logs and unpacked data for Approval events raised by the RegStore contract.
type RegStoreApprovalIterator struct {
	Event *RegStoreApproval // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RegStoreApprovalIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RegStoreApproval)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RegStoreApproval)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RegStoreApprovalIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RegStoreApprovalIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RegStoreApproval represents a Approval event raised by the RegStore contract.
type RegStoreApproval struct {
	Owner    common.Address
	Approved common.Address
	TokenId  *big.Int
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApproval is a free log retrieval operation binding the contract event 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925.
//
// Solidity: event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)
func (_RegStore *RegStoreFilterer) FilterApproval(opts *bind.FilterOpts, owner []common.Address, approved []common.Address, tokenId []*big.Int) (*RegStoreApprovalIterator, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var approvedRule []interface{}
	for _, approvedItem := range approved {
		approvedRule = append(approvedRule, approvedItem)
	}
	var tokenIdRule []interface{}
	for _, tokenIdItem := range tokenId {
		tokenIdRule = append(tokenIdRule, tokenIdItem)
	}

	logs, sub, err := _RegStore.contract.FilterLogs(opts, "Approval", ownerRule, approvedRule, tokenIdRule)
	if err != nil {
		return nil, err
	}
	return &RegStoreApprovalIterator{contract: _RegStore.contract, event: "Approval", logs: logs, sub: sub}, nil
}

// WatchApproval is a free log subscription operation binding the contract event 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925.
//
// Solidity: event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)
func (_RegStore *RegStoreFilterer) WatchApproval(opts *bind.WatchOpts, sink chan<- *RegStoreApproval, owner []common.Address, approved []common.Address, tokenId []*big.Int) (event.Subscription, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var approvedRule []interface{}
	for _, approvedItem := range approved {
		approvedRule = append(approvedRule, approvedItem)
	}
	var tokenIdRule []interface{}
	for _, tokenIdItem := range tokenId {
		tokenIdRule = append(tokenIdRule, tokenIdItem)
	}

	logs, sub, err := _RegStore.contract.WatchLogs(opts, "Approval", ownerRule, approvedRule, tokenIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RegStoreApproval)
				if err := _RegStore.contract.UnpackLog(event, "Approval", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseApproval is a log parse operation binding the contract event 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925.
//
// Solidity: event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)
func (_RegStore *RegStoreFilterer) ParseApproval(log types.Log) (*RegStoreApproval, error) {
	event := new(RegStoreApproval)
	if err := _RegStore.contract.UnpackLog(event, "Approval", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RegStoreApprovalForAllIterator is returned from FilterApprovalForAll and is used to iterate over the raw logs and unpacked data for ApprovalForAll events raised by the RegStore contract.
type RegStoreApprovalForAllIterator struct {
	Event *RegStoreApprovalForAll // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RegStoreApprovalForAllIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RegStoreApprovalForAll)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RegStoreApprovalForAll)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RegStoreApprovalForAllIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RegStoreApprovalForAllIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RegStoreApprovalForAll represents a ApprovalForAll event raised by the RegStore contract.
type RegStoreApprovalForAll struct {
	Owner    common.Address
	Operator common.Address
	Approved bool
	Raw      types.Log // Blockchain specific contextual infos
}

// FilterApprovalForAll is a free log retrieval operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed owner, address indexed operator, bool approved)
func (_RegStore *RegStoreFilterer) FilterApprovalForAll(opts *bind.FilterOpts, owner []common.Address, operator []common.Address) (*RegStoreApprovalForAllIterator, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _RegStore.contract.FilterLogs(opts, "ApprovalForAll", ownerRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return &RegStoreApprovalForAllIterator{contract: _RegStore.contract, event: "ApprovalForAll", logs: logs, sub: sub}, nil
}

// WatchApprovalForAll is a free log subscription operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed owner, address indexed operator, bool approved)
func (_RegStore *RegStoreFilterer) WatchApprovalForAll(opts *bind.WatchOpts, sink chan<- *RegStoreApprovalForAll, owner []common.Address, operator []common.Address) (event.Subscription, error) {

	var ownerRule []interface{}
	for _, ownerItem := range owner {
		ownerRule = append(ownerRule, ownerItem)
	}
	var operatorRule []interface{}
	for _, operatorItem := range operator {
		operatorRule = append(operatorRule, operatorItem)
	}

	logs, sub, err := _RegStore.contract.WatchLogs(opts, "ApprovalForAll", ownerRule, operatorRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RegStoreApprovalForAll)
				if err := _RegStore.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseApprovalForAll is a log parse operation binding the contract event 0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31.
//
// Solidity: event ApprovalForAll(address indexed owner, address indexed operator, bool approved)
func (_RegStore *RegStoreFilterer) ParseApprovalForAll(log types.Log) (*RegStoreApprovalForAll, error) {
	event := new(RegStoreApprovalForAll)
	if err := _RegStore.contract.UnpackLog(event, "ApprovalForAll", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// RegStoreTransferIterator is returned from FilterTransfer and is used to iterate over the raw logs and unpacked data for Transfer events raised by the RegStore contract.
type RegStoreTransferIterator struct {
	Event *RegStoreTransfer // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *RegStoreTransferIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(RegStoreTransfer)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(RegStoreTransfer)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *RegStoreTransferIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *RegStoreTransferIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// RegStoreTransfer represents a Transfer event raised by the RegStore contract.
type RegStoreTransfer struct {
	From    common.Address
	To      common.Address
	TokenId *big.Int
	Raw     types.Log // Blockchain specific contextual infos
}

// FilterTransfer is a free log retrieval operation binding the contract event 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef.
//
// Solidity: event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)
func (_RegStore *RegStoreFilterer) FilterTransfer(opts *bind.FilterOpts, from []common.Address, to []common.Address, tokenId []*big.Int) (*RegStoreTransferIterator, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}
	var tokenIdRule []interface{}
	for _, tokenIdItem := range tokenId {
		tokenIdRule = append(tokenIdRule, tokenIdItem)
	}

	logs, sub, err := _RegStore.contract.FilterLogs(opts, "Transfer", fromRule, toRule, tokenIdRule)
	if err != nil {
		return nil, err
	}
	return &RegStoreTransferIterator{contract: _RegStore.contract, event: "Transfer", logs: logs, sub: sub}, nil
}

// WatchTransfer is a free log subscription operation binding the contract event 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef.
//
// Solidity: event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)
func (_RegStore *RegStoreFilterer) WatchTransfer(opts *bind.WatchOpts, sink chan<- *RegStoreTransfer, from []common.Address, to []common.Address, tokenId []*big.Int) (event.Subscription, error) {

	var fromRule []interface{}
	for _, fromItem := range from {
		fromRule = append(fromRule, fromItem)
	}
	var toRule []interface{}
	for _, toItem := range to {
		toRule = append(toRule, toItem)
	}
	var tokenIdRule []interface{}
	for _, tokenIdItem := range tokenId {
		tokenIdRule = append(tokenIdRule, tokenIdItem)
	}

	logs, sub, err := _RegStore.contract.WatchLogs(opts, "Transfer", fromRule, toRule, tokenIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(RegStoreTransfer)
				if err := _RegStore.contract.UnpackLog(event, "Transfer", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseTransfer is a log parse operation binding the contract event 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef.
//
// Solidity: event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)
func (_RegStore *RegStoreFilterer) ParseTransfer(log types.Log) (*RegStoreTransfer, error) {
	event := new(RegStoreTransfer)
	if err := _RegStore.contract.UnpackLog(event, "Transfer", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
