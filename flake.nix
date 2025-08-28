# SPDX-FileCopyrightText: 2024 Mass Labs
#
# SPDX-License-Identifier: GPL-3.0-or-later
{
  description = "Mass Market Contracts";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # services definitions
    process-compose-flake = {
      url = "github:Platonic-Systems/process-compose-flake";
    };
    flake-root.url = "github:srid/flake-root";
    services-flake.url = "github:juspay/services-flake";
    # solidity dependencies
    forge-std = {
      url = "github:foundry-rs/forge-std";
      flake = false;
    };
    solady = {
      url = "github:Vectorized/solady";
      flake = false;
    };
    openzeppelin = {
      url = "github:OpenZeppelin/openzeppelin-contracts";
      flake = false;
    };
    ds-test = {
      url = "github:dapphub/ds-test";
      flake = false;
    };
  };

  outputs = inputs @ {
    flake-parts,
    flake-root,
    forge-std,
    openzeppelin,
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
        inputs.flake-root.flakeModule
      ];

      flake = {
        processComposeModules.default = (import ./services.nix) {inherit inputs;};
      };

      perSystem = {
        pkgs,
        config,
        self',
        ...
      }: let
        buildInputs = with pkgs; [
          jq
          solc
          reuse
          foundry
        ];
        remappings = pkgs.writeTextDir "remappings.txt" ''
          forge-std/=${inputs.forge-std}/src
          openzeppelin/=${inputs.openzeppelin}
          ds-test/=${inputs.ds-test}/src
          solady=${inputs.solady}/
        '';
        src = pkgs.symlinkJoin {
          name = "deploy-contracts-src";
          paths = [remappings ./.];
        };
      in {
        process-compose = let
          cli = {
            options = {
              no-server = false;
              port = 8321;
            };
          };
          imports = [
            inputs.services-flake.processComposeModules.default
            inputs.self.processComposeModules.default
          ];
          services = {
            anvil.enable = true;
            deploy-contracts.enable = true;
          };
        in {
          local-testnet = {
            inherit imports services cli;
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
          inputsFrom = [config.flake-root.devShell]; # Provides $FLAKE_ROOT in dev shell
          # local devshell scripts need to come first.
          buildInputs =
            buildInputs
            ++ [
              pkgs.typos-lsp # code spell checker
              pkgs.nixd
              self'.packages.deploy-market
            ]
            ++ config.pre-commit.settings.enabledPackages;

          shellHook = ''
            ${config.pre-commit.settings.installationScript}
            export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
            export PS1="[contracts] $PS1"
            # remove solidity cache (it not always notices branch changes)
            test -d $FLAKE_ROOT/cache && rm -r $FLAKE_ROOT/cache
            # check contents
            cp -f ${remappings}/remappings.txt $FLAKE_ROOT/remappings.txt
          '';
        };
        packages = rec {
          default = mass-contracts;
          deploy-market = pkgs.writeShellScriptBin "deploy-market" ''
            tmp=$(mktemp -d)
            export FOUNDRY_BROADCAST=$tmp/broadcast
            export FOUNDRY_CACHE_PATH=$tmp/cache
            export FOUNDRY_OUT=$tmp
            export FOUNDRY_ROOT=${src}
            export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
            pushd $FOUNDRY_ROOT
            ${pkgs.foundry}/bin/forge script ./script/deploy.s.sol:Deploy -s "deployContracts(bool, bool)" true false --broadcast --private-key $PRIVATE_KEY
            popd
          '';

          source-with-deps = pkgs.stdenv.mkDerivation {
            name = "source-with-deps";
            inherit src;
          };

          mass-contracts = pkgs.stdenv.mkDerivation {
            inherit buildInputs;
            name = "mass-contracts";

            src = ./.;
            dontPatch = true;
            dontConfigure = true;
            doCheck = true;

            buildPhase = ''
              cp ${remappings}/remappings.txt remappings.txt
              export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
              forge compile
              forge script ./script/deploy.s.sol:Deploy -s "deployContracts(bool, bool)" true true
            '';

            checkPhase = ''
              forge test
            '';

            installPhase = ''
              mkdir -p $out/{bin,abi};
              cp ./deploymentAddresses.json $out/deploymentAddresses.json
              # create ABI files for codegen
              for artifact in {ERC20,RelayReg,ShopReg,OrderPayments}; do
              cd out/$artifact.sol/
              for contract in *.json; do
                jq .abi $contract > $out/abi/$contract
              done
              cd ../../
              done
              jq .abi out/deploy.s.sol/EuroDollar.json > $out/abi/Eddies.json
            '';
          };
        };
      };
    };
}
