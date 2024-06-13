# SPDX-FileCopyrightText: 2024 Mass Labs
#
# SPDX-License-Identifier: GPL-3.0-or-later
{
  description = "Mass Market Contracts";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    foundry.url = "github:shazow/foundry.nix/monthly";
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
    nixpkgs,
    foundry,
    forge-std,
    permit2,
    solady,
    ds-test,
    self,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        private_key = "export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
        mk_deploy_market = path: immut: (pkgs.writeShellScriptBin "deploy-market" ''
          ${
            if immut
            then ''
              tmp=$(mktemp -d)
              export FOUNDRY_BROADCAST=$tmp/broadcast
              export FOUNDRY_CACHE_PATH=$tmp/cache
              export FOUNDRY_OUT=$tmp
            ''
            else ""
          }
            set -e
            if [ -z "$PRIVATE_KEY" ]; then
              echo "PRIVATE_KEY not set, using default"
              ${private_key}
            fi
            export FOUNDRY_ROOT=${path}
            export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
            pushd ${path}
            ${pkgs.foundry-bin}/bin/forge script ${path}/script/deploy.s.sol:Deploy -s "${
            if immut
            then "runTestDeployImmut()"
            else "runTestDeploy()"
          }" --fork-url http://localhost:8545 --broadcast
            popd
        '');

        mk_run_and_deploy = deploy:
          pkgs.writeShellScriptBin "run-and-deploy" ''
            ${pkgs.foundry-bin}/bin/anvil | (grep -m 1 "Listening on "; ${deploy}/bin/deploy-market)
          '';

        update_env = pkgs.writeShellScriptBin "update_env.sh" ''
          set -e

          function get_addr()
          {
              local dir=$(dirname "$0")
              local reg=$1
              local addr=$(jq -r ".''${reg}" "''${dir}/../deploymentAddresses.json")
              eval $reg="'$addr'"
          }

          get_addr RelayReg
          echo "RELAY_REGISTRY_ADDRESS=$RelayReg"

          get_addr ShopReg
          echo "SHOP_REGISTRY_ADDRESS=$ShopReg"

          get_addr PaymentFactory
          echo "PAYMENT_FACTORY_ADDRESS=$PaymentFactory"

          get_addr Eddies
          test -n "$EuroDollarToken" && echo "ERC20_TOKEN_ADDRESS=$Eddies"
        '';

        deploy_market_local = mk_deploy_market "." false;
        deploy_market_shop = mk_deploy_market self true;
        deploy_market_sepolia = pkgs.writeShellScriptBin "deploy-sepolia" ''
          ${pkgs.foundry-bin}/bin/forge script --verifier sourcify ./script/deploy.s.sol:Deploy --rpc-url https://rpc.sepolia.org/ --broadcast
        '';

        run_and_deploy_local = mk_run_and_deploy deploy_market_local;
        run_and_deploy_shop = mk_run_and_deploy deploy_market_shop;

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
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;

        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            foundry.overlay
          ];
        };

        devShells.default = pkgs.mkShell {
          # local devshell scripts need to come first.
          buildInputs =
            [
              deploy_market_local
              run_and_deploy_local
              deploy_market_sepolia
            ]
            ++ buildInputs;

          shellHook = ''
            ${private_key}
             export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
             export PS1="[contracts] $PS1"
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
            buildInputs =
              [
                deploy_market_shop
                run_and_deploy_shop
              ]
              ++ buildInputs;
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
              ln -s ${deploy_market_shop}/bin/deploy-market $out/bin/deploy-market
              ln -s ${run_and_deploy_shop}/bin/run-and-deploy $out/bin/run-and-deploy
              ln -s ${update_env}/bin/update_env.sh $out/bin/update_env.sh
            '';
          };
        };
      };
    };
}
