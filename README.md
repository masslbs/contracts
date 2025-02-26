<!--
SPDX-FileCopyrightText: 2024 Mass Labs

SPDX-License-Identifier: GPL-3.0-or-later
-->

# OVERVIEW

The smart contracts that implement the Mass Market Protocol. This repo contains shop registry and the payments factory.

# DEVELOP

[nix](nixos.wiki) is used for dependency management.

Run `nix develop` to enter the devShell.

## Deploy to local test nest

To create and delopy the contract to a local testnet first

- start anvil and deploy the contract locally run `nix .#local-testnet`

# TESTING

`forge test `

# LICENSE

GPL-3
