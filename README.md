<!--
SPDX-FileCopyrightText: 2024 Mass Labs

SPDX-License-Identifier: GPL-3.0-or-later
-->

# DMP SMART CONTRACTS

The smart contracts that implement the Decentralized Market Protocol.

# OVERVIEW

This repo contains shop registry and the payments factory.

# DEVELOP

[nix](nixos.wiki) is used for dependancy managment.

Run `nix develop` to enter the devShell.

## Delpoy to local test nest

To create and delopy the contract to a local testnet first

- start anvil and deploy the contract locally run `run-and-deploy`
- to redeploy the contract run `deploy-market`

# TESTING

`forge test `

# DEPLOYMENTS

[deploymentAddresses.json](./deploymentAddresses.json)

# LICENSE

GPL-3
