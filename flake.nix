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

      mk_deploy_market = name: path: contract: immut: (pkgs.writeShellScriptBin name ''
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
          if [ -z "$PRIVATE_KEY" ]; then
            echo "PRIVATE_KEY not set, using default"
            ${private_key}
          fi
          export FOUNDRY_ROOT=${path}
          export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
          pushd ${path}
          ${pkgs.foundry-bin}/bin/forge \
          script ${path}/script/deploy.s.sol --target-contract ${contract} \
            --fork-url http://localhost:8545 --broadcast
          popd
      '');

      mk_run_and_deploy = deploy:
        pkgs.writeShellScriptBin "run-and-deploy" ''
          ${pkgs.foundry-bin}/bin/anvil | (grep -m 1 "Listening on "; ${deploy}/bin/deploy-market)
        '';

      deploy_market_local = mk_deploy_market "deploy-market" "." "TestingDeploy" false;
      deploy_market_test = mk_deploy_market "deploy-test-market" self "TestingDeploy" true;
      deploy_market_sepolia = pkgs.writeShellScriptBin "deploy-sepolia" ''
        ${pkgs.foundry-bin}/bin/forge script --verifier sourcify ./script/deploy.s.sol:Deploy --rpc-url https://rpc.sepolia.org/ --broadcast --vvvv --no-auto-detect
      '';

      run_and_deploy_local = mk_run_and_deploy deploy_market_local;
      run_and_deploy_test = mk_run_and_deploy deploy_market_test;

      buildInputs = with pkgs; [
        solc
        reuse
        foundry-bin
        nodePackages.pnpm
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
          '';

          checkPhase = ''
            forge test --no-auto-detect
          '';

          installPhase = ''
            mkdir -p $out/{bin,abi};
            cp ./update_env.sh $out/bin/
            cp -r ./out/{ERC20.sol,RelayReg.sol,StoreReg.sol,Payments.sol,payment-factory.sol} $out/abi
            ln -s ${deploy_market_test}/bin/deploy-test-market $out/bin/deploy-test-market
            ln -s ${run_and_deploy_test}/bin/run-and-deploy $out/bin/run-and-deploy
          '';
        };
      };
    });
}
