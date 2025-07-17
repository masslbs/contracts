# SPDX-FileCopyrightText: 2024 Mass Labs
#
# SPDX-License-Identifier: GPL-3.0-or-later
{
  description = "Mass Market Contracts";
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    process-compose-flake = {
      url = "github:Platonic-Systems/process-compose-flake";
    };
    flake-root.url = "github:srid/flake-root";
    services-flake.url = "github:juspay/services-flake";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        processComposeModules.default = ./services.nix;
      };

      perSystem = {
        pkgs,
        config,
        ...
      }: let
        buildInputs = with pkgs; [
          jq
          solc
          reuse
          foundry
        ];

        remappings = pkgs.writeText "remapping.txt" ''
          forge-std/=${forge-std}/src
          openzeppelin/=${openzeppelin}
          ds-test/=${ds-test}/src
          solady=${solady}/
        '';
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
            ]
            ++ config.pre-commit.settings.enabledPackages;

          shellHook = ''
            ${config.pre-commit.settings.installationScript}
            export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
            export PS1="[contracts] $PS1"
            # remove solidity cache (it not always notices branch changes)
            test -d $FLAKE_ROOT/cache && rm -r $FLAKE_ROOT/cache
            # check contents
            cp -f ${remappings} $FLAKE_ROOT/remappings.txt
          '';
        };
        packages = rec {
          default = mass-contracts;

          source-with-deps = pkgs.stdenv.mkDerivation {
            name = "source-with-deps";
            src = ./.;
            buildPhase = ''
              cp -r $src $out
              chmod -R +w $out
              cp ${remappings} $out/remappings.txt
            '';
          };

          mass-contracts = pkgs.stdenv.mkDerivation {
            inherit buildInputs;
            name = "mass-contracts";

            src = ./.;
            dontPatch = true;
            dontConfigure = true;
            doCheck = true;

            buildPhase = ''
              cp ${remappings} remappings.txt
              export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
              forge compile
              # forge script will fail trying to load SSL_CERT_FILE
              # unset SSL_CERT_FILE
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
