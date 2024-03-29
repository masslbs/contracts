<!--
SPDX-FileCopyrightText: 2024 Mass Labs

SPDX-License-Identifier: GPL-3.0-or-later
-->

# DMP SMART CONTRACTS

The smart contracts that implement the Decentralized Market Protocol.

# OVERVIEW

This repo contains store registry, relay registry and the payments factory.

# DEVELOP

[nix](nixos.wiki) is used for dependancy managment.

Run `nix develop` to enter the devShell.

## Delpoy to local test nest

To create and delopy the contract to a local testnet first

- start anvil and deploy the contract locally run `run-and-deploy`
- to redeploy the contract run `deploy-market`

## Generate Go abi

```
rm -rf abis/sol
solc --abi --base-path . --include-path lib/  \
  --input-file src/store-reg.sol \
  --input-file src/relay-reg.sol \
  --input-file src/payment-factory.sol \
  -o abis/sol
# overwrite for abis/sol/IERC1155Errors.abi
solc --abi --input-file lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol -o abis/sol --overwrite
abigen --abi abis/sol/StoreReg.abi --pkg main --type RegStore --out abis/go/registry-store.go
abigen --abi abis/sol/RelayReg.abi --pkg main --type RegRelay --out abis/go/registry-relay.go
```

**TODO**: need to find a way to include deployed addresses

## Generate TS ABI

The TS interface for the ABI is generated by [wagmi cli](https://wagmi.sh/cli/getting-started). The generated code will be stored in ./abis/js/src/

To update the code run the following.

```
cd  abis/js
pnpm install
pnpm wagmi generate
```

# TESTING

`forge test --no-auto-detect`

# DEPLOYMENT

Currently Depolyed

- Sepolia `0xe7ed90d1ef91c23ee8531567419cc5554a4303b6`
- Mainnet `0x200eE24fd0d1a88E3b83dE1dA10B413963e1B2Ea`

# LICENSE

GPL-3
