# SPDX-FileCopyrightText: 2024 Mass Labs
#
# SPDX-License-Identifier: GPL-3.0-or-later
{
  description = "Mass Market Contracts";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
    };
    foundry.url = "github:shazow/foundry.nix/monthly";
    foundry.inputs.nixpkgs.follows = "nixpkgs";
    forge-std = {
      url = "github:foundry-rs/forge-std";
      flake = false;
    };
    solady = {
      url = "github:Vectorized/solady";
      flake = false;
    };
    permit2 = {
      url = "github:uniswap/permit2";
      flake = false;
    };
    ds-test = {
      url = "github:dapphub/ds-test";
      flake = false;
    };
  };

  outputs = inputs @ {
    flake-parts,
    foundry,
    forge-std,
    permit2,
    solady,
    ds-test,
    systems,
    ...
  }:
  flake-parts.lib.mkFlake {inherit inputs;} {
    systems = import systems;
    imports = [
      inputs.pre-commit-hooks.flakeModule
      inputs.process-compose-flake.flakeModule
    ];

    flake.processComposeModules.default = ./services.nix;
    perSystem = {
      pkgs,
      system,
      config,
      ...
    }: let
    buildInputs = with pkgs; [
      jq
      solc
      reuse
      foundry-bin
    ];

    remappings = pkgs.writeText "remapping.txt" ''
      forge-std/=${forge-std}/src
      ds-test/=${ds-test}/src
      permit2/=${permit2}/
      solady=${solady}/
    '';
    in {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          foundry.overlay
        ];
      };
      process-compose.local-testnet = {
        imports = [
          inputs.services-flake.processComposeModules.default
          inputs.self.processComposeModules.default
        ];
        services = {
          anvil.enable = true;
          deploy.enable = true;
        };
      };

      pre-commit = {
        check.enable = true;
        settings = {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            typos.enable = true;
          };
        };
      };

      devShells.default = pkgs.mkShell {
        # local devshell scripts need to come first.
        buildInputs = buildInputs ++ [
          pkgs.typos-lsp # code spell checker
          pkgs.nixd
        ] ++ config.pre-commit.settings.enabledPackages;

        shellHook = ''
          export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
          export PS1="[contracts] $PS1"
          # remove solidity cache (it not always notices branch changes)
          test -d cache && rm -r cache
          # check contents
          cp -f ${remappings} remappings.txt
          # check remappings
          while read line; do
          dir=$(echo $line | cut -d'=' -f2-)
          test -d "$dir" || {
          echo "WARNING: remapping not found: $line"
          exit 1
          }
          done < remappings.txt
        '';
      };
      packages = rec {
        default = mass-contracts;
        mass-contracts = pkgs.stdenv.mkDerivation {
          inherit buildInputs;
          name = "mass-contracts";

          src = ./.;
          dontPatch = true;
          dontConfigure = true;

          buildPhase = ''
            cp ${remappings} remappings.txt
            export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
            forge compile
            # forge script will fail trying to load SSL_CERT_FILE
            unset SSL_CERT_FILE
            export PRIVATE_KEY=0x1
            forge script ./script/deploy.s.sol:Deploy -s "runTestDeploy()"
          '';

          checkPhase = ''
            forge test
          '';

          installPhase = ''
            mkdir -p $out/{bin,abi};
            cp ./deploymentAddresses.json $out/deploymentAddresses.json
            # create ABI files for codegen
            for artifact in {ERC20,RelayReg,ShopReg,Payments,PaymentsByAddress}; do
            cd out/$artifact.sol/
            jq .abi $(ls -1 . | head -n 1) > $out/abi/$artifact.json
            cd ../../
            done
            jq .abi out/deploy.s.sol/EuroDollar.json > $out/abi/Eddies.json
          '';
        };
      };
    };
  };
}
