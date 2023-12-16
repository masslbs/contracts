# DMP SMART CONTRACTS

The smart contracts that implement the Decentralized Market Protocol.

# OVERVIEW

This repo contains store registry and the payments factory.

- Solidity Documention: https://dm-foundation.github.io/contracts
- Stack
  - [nix](nixos.wiki) - used for dependancy managment
  - [Foundry](https://getfoundry.sh/) - Ethereum ToolKit; used for testing, deploying and compiling the contracts

# DEVELOP

Run `nix develop` to enter the devShell.

## Delpoy to local test nest
To create and delopy the contract to a local testnet first
- start anvil run  `anvil`
- in a seprate terminal run `deploy-market` which will delopy the contrat to the local testnet 

## Generating ABI.ts
To generate the ABI bindings for use in in viem.sh 
- Go to the abi directory. `cd ./abis/js`
- install the dependancies `pnpm install .`
- run wagmi cli `pnpm wagmi generate`

The resulting binding should be written to `src/abi.ts` 

## Generate Go abi

```
rm -rf abis/sol
solc --abi --base-path . --include-path lib/  --input-file src/store-reg.sol --input-file src/relay-reg.sol -o abis/sol
abigen --abi abis/sol/StoreReg.abi --pkg main --type RegStore --out abis/go/registry-store.go
abigen --abi abis/sol/RelayReg.abi --pkg main --type RegRelay --out abis/go/registry-relay.go
```

**TODO**: need to find a way to include deployed addresses

# TESTING

`forge test --no-auto-detect`

# DEPLOYMENT

Currently Depolyed

- Sepolia `0xe7ed90d1ef91c23ee8531567419cc5554a4303b6`
- Mainnet `0x200eE24fd0d1a88E3b83dE1dA10B413963e1B2Ea`

# LICENSE

GPL-3
