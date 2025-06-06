# SPDX-FileCopyrightText: 2024 Mass Labs
#
# SPDX-License-Identifier: GPL-3.0-or-later
{
  description = "Mass Market Contracts";
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    flake-root.url = "github:srid/flake-root";
    process-compose-flake = {
      url = "github:Platonic-Systems/process-compose-flake";
    };
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
    forge-std,
    permit2,
    openzeppelin,
    solady,
    ds-test,
    systems,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import systems;
      imports = [
        inputs.flake-root.flakeModule
        inputs.pre-commit-hooks.flakeModule
        inputs.process-compose-flake.flakeModule
      ];

      flake = {
        processComposeModules.default = ./services.nix;
      };

      perSystem = {
        pkgs,
        system,
        config,
        self',
        lib,
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
          permit2/=${permit2}/
          solady=${solady}/
        '';
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
        };
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
          local-testnet-dev = {
            inherit imports cli;
            services =
              services
              // {
                deploy-contracts = {
                  enable = true;
                  path = "''$(${lib.getExe config.flake-root.package})";
                };
              };
          };
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
          # local devshell scripts need to come first.
          buildInputs =
            buildInputs
            ++ [
              self'.packages.local-testnet-dev
              pkgs.typos-lsp # code spell checker
              pkgs.nixd
            ]
            ++ config.pre-commit.settings.enabledPackages;

          shellHook = ''
            ${config.pre-commit.settings.installationScript}
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
            doCheck = true;

            buildPhase = ''
              cp ${remappings} remappings.txt
              export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
              forge compile
              # forge script will fail trying to load SSL_CERT_FILE
              unset SSL_CERT_FILE
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
