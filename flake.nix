# SPDX-FileCopyrightText: 2024 Mass Labs
#
# SPDX-License-Identifier: GPL-3.0-or-later
{
  description = "Mass Market Contracts";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    utils.url = "github:numtide/flake-utils";
    foundry = {
      url = "git+https://github.com/shazow/foundry.nix.git?ref=monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    forge-std = {
      url = "git+https://github.com/foundry-rs/forge-std?submodules=1";
      flake = false;
    };
    solady = {
      url = "github:Vectorized/solady";
      flake = false;
    };
    permit2 = {
      url = "git+https://github.com/uniswap/permit2.git";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    utils,
    foundry,
    forge-std,
    permit2,
    solady,
    self, # This is the output of the flake itself, e.g. the location in nix/store of the source code
    ...
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          foundry.overlay
        ];
      };

      private_key = "export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

      mk_deploy_market = name: path: immut: (pkgs.writeShellScriptBin name ''
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
          ${pkgs.foundry-bin}/bin/forge \
          script ${path}/script/deploy.s.sol:Deploy -s "runTestDeploy()"  \
            --fork-url http://localhost:8545 --broadcast
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

        get_addr StoreReg
        echo "STORE_REGISTRY_ADDRESS=$StoreReg"

        get_addr PaymentFactory
        echo "PAYMENT_FACTORY_ADDRESS=$PaymentFactory"

        get_addr Eddies
        test -n "$EuroDollarToken" && echo "ERC20_TOKEN_ADDRESS=$Eddies"
      '';

      deploy_market_local = mk_deploy_market "deploy-market" "." false;
      deploy_market_test = mk_deploy_market "deploy-test-market" self true;
      deploy_market_sepolia = pkgs.writeShellScriptBin "deploy-sepolia" ''
        ${pkgs.foundry-bin}/bin/forge script --verifier sourcify ./script/deploy.s.sol:Deploy --rpc-url https://rpc.sepolia.org/ --broadcast --vvvv --no-auto-detect
      '';

      run_and_deploy_local = mk_run_and_deploy deploy_market_local;
      run_and_deploy_test = mk_run_and_deploy deploy_market_test;

      buildInputs = with pkgs; [
        jq
        solc
        reuse
        foundry-bin
        deploy_market_test
        run_and_deploy_test
        deploy_market_sepolia
      ];

      remappings = pkgs.writeText "remapping.txt" ''
        forge-std/=${forge-std}/src
        ds-test/=${forge-std}/lib/ds-test/src
        permit2/=${permit2}/
        solady=${solady}/
      '';
    in {
      devShell = pkgs.mkShell {
        # local devshell scripts need to come first.
        buildInputs =
          [
            deploy_market_local
            run_and_deploy_local
          ]
          ++ buildInputs;

        shellHook = ''
          ${private_key}
           export PS1="[contracts] $PS1"
           cp -f ${remappings} remappings.txt
        '';
      };
      packages = {
        market-build = pkgs.stdenv.mkDerivation {
          inherit buildInputs;
          name = "mass-contracts";

          src = ./.;
          dontPatch = true;
          dontConfigure = true;

          buildPhase = ''
            cp ${remappings} remappings.txt
            forge compile --no-auto-detect
            # forge script will fail trying to load SSL_CERT_FILE
            unset SSL_CERT_FILE
            export PRIVATE_KEY=0x1
            forge script ./script/deploy.s.sol:Deploy -s "runTestDeploy()" --no-auto-detect
          '';

          checkPhase = ''
            forge test --no-auto-detect
          '';

          installPhase = ''
            mkdir -p $out/{bin,abi};
            cp ./deploymentAddresses.json $out/deploymentAddresses.json
            # create ABI files for codegen
            for artifact in {ERC20,RelayReg,StoreReg,Payments,PaymentFactory}; do
                cd out/$artifact.sol/
                jq .abi $(ls -1 . | head -n 1) > $out/abi/$artifact.json
                cd ../../
            done
            jq .abi out/deploy.s.sol/EuroDollar.json > $out/abi/Eddies.json
            ln -s ${deploy_market_test}/bin/deploy-test-market $out/bin/deploy-test-market
            ln -s ${run_and_deploy_test}/bin/run-and-deploy $out/bin/run-and-deploy
            ln -s ${update_env}/bin/update_env.sh $out/bin/update_env.sh
          '';
        };
      };
    });
}
