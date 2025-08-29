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
    openzeppelin = {
      url = "github:OpenZeppelin/openzeppelin-contracts";
      flake = false;
    };
    ds-test = {
      url = "github:dapphub/ds-test";
      flake = false;
    };
    solady = {
      url = "github:Vectorized/solady";
      flake = false;
    };
  };

  outputs = inputs @ {
    flake-parts,
    flake-root,
    forge-std,
    solady,
    openzeppelin,
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
        libs = pkgs.runCommand "contracts-libs" {} ''
          mkdir -p $out/libs
          ln -s ${forge-std} $out/libs/forge-std
          ln -s ${openzeppelin} $out/libs/openzeppelin
          ln -s ${ds-test} $out/libs/ds-test
          ln -s ${solady} $out/libs/solady
        '';
        src = pkgs.symlinkJoin {
          name = "deploy-contracts-src";
          paths = [./. libs];
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
            # remove solidity cache (it not always notices branch changes)
            test -d $FLAKE_ROOT/cache && rm -r $FLAKE_ROOT/cache
            # check contents
            rm $FLAKE_ROOT/libs
            ln -s ${libs}/libs $FLAKE_ROOT/libs
          '';
        };
        packages = rec {
          default = mass-contracts;
          deploy-market = pkgs.writeShellScriptBin "deploy-market" ''
            tmp=$(mktemp -d)
            export FOUNDRY_BROADCAST=$tmp/broadcast
            export FOUNDRY_CACHE_PATH=$tmp/cache
            export FOUNDRY_OUT=$tmp
            export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
            export FOUNDRY_ROOT=${src}
            pushd $FOUNDRY_ROOT
            ${pkgs.foundry}/bin/forge script ./script/deploy.s.sol:Deploy -s "deployContracts(bool, bool)" true false --broadcast --private-key $PRIVATE_KEY "$@"
            popd
          '';

          source-with-deps = pkgs.stdenv.mkDerivation {
            name = "source-with-deps";
            inherit src;
          };

          mass-contracts = pkgs.stdenv.mkDerivation {
            inherit buildInputs src;
            name = "mass-contracts";

            dontPatch = true;
            dontConfigure = true;
            doCheck = true;

            buildPhase = ''
              export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
              forge script ./script/deploy.s.sol:Deploy -s "deployContracts(bool, bool)" true true
            '';

            checkPhase = ''
              forge test
            '';

            installPhase = ''
              mkdir -p $out/{bin,abi};
              cp ./deploymentAddresses.json $out/deploymentAddresses.json
              # create ABI files for codegen
              for artifact in {ERC20,ShopReg,OrderPayments}; do
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
