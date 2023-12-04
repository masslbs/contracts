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
- Go to the abi directory. `cd ./abi`
- install the dependancies `pnpm install .`
- run wagmi cli `pnpm wagmi`

The resulting binding should be written to `src/abi.ts` 

## Generate Go abi

tool requirement: `go install github.com/ethereum/go-ethereum/cmd/abigen@latest`

```
rm -rf abi
solc --abi --base-path . --include-path lib/  --input-file src/store-reg.sol --input-file src/relay-reg.sol -o abi
abigen --abi abi/StoreReg.abi --pkg main --type RegStore --out goabi/registry-store.go
abigen --abi abi/RelayReg.abi --pkg main --type RegRelay --out goabi/registry-relay.go
```

# TESTING

`forge test --no-auto-detect`

# DEPLOYMENT

Currently Depolyed

- Sepolia `0xe7ed90d1ef91c23ee8531567419cc5554a4303b6`
- Mainnet `0x200eE24fd0d1a88E3b83dE1dA10B413963e1B2Ea`

# LICENSE

GPL-3
