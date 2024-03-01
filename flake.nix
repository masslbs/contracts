{
  description = "Mass Market Contracts";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    utils.url = "github:numtide/flake-utils";
    foundry = {
      url = "github:shazow/foundry.nix?rev=883243b30a4b8dbb1b515b79b750e2caf7df1a79";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    forge-std = {
      url = "github:foundry-rs/forge-std";
      flake = false;
    };
    openzeppelin-contracts = {
      url = "github:OpenZeppelin/openzeppelin-contracts";
      flake = false;
    };
    ds-tests = {
      url = "github:dapphub/ds-test";
      flake = false;
    };
    solady = {
      url = "github:Vectorized/solady";
      flake = false;
    };
    permit2 = {
      url = "git+https://github.com/uniswap/permit2.git?submodules=1";
      flake = false;
    };
  };

  outputs = {
    nixpkgs,
    utils,
    foundry,
    forge-std,
    openzeppelin-contracts,
    ds-tests,
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
      deploy_market = mk_deploy_market "deploy-market" self "Deploy" true;
      deploy_market_test = mk_deploy_market "deploy-test-market" self "TestingDeploy" true;

      run_and_deploy_local = mk_run_and_deploy deploy_market_local;
      run_and_deploy = mk_run_and_deploy deploy_market;

      buildInputs = with pkgs; [
        foundry-bin
        nodePackages.pnpm
        solc
        deploy_market
        run_and_deploy
      ];

      remappings-txt = ''
        forge-std/=${forge-std}/src
        openzeppelin-contracts/=${openzeppelin-contracts}/
        ds-test/=${ds-tests}/src
        @openzeppelin/=${openzeppelin-contracts}/
        permit2/=${permit2}/
        solady=${solady}/
      '';
      remappings = pkgs.writeText "remapping.txt" remappings-txt;
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
            solc ${builtins.replaceStrings ["\n"] [" "] remappings-txt} --abi   \
              --input-file src/store-reg.sol \
              --input-file src/relay-reg.sol \
              --input-file src/payment-factory.sol \
              -o $out/abi
            # overwrite for abis/sol/IERC1155Errors.abi
            solc --abi --allow-paths  ${openzeppelin-contracts} --input-file ${openzeppelin-contracts}/contracts/token/ERC20/ERC20.sol -o $out/abi --overwrite
          '';

          checkPhase = ''
            forge test --no-auto-detect
          '';

          installPhase = ''
            mkdir -p $out/{bin,abi};
            cp ./update_env.sh $out/bin/
            ln -s ${deploy_market}/bin/deploy-market $out/bin/deploy-market
            ln -s ${deploy_market_test}/bin/deploy-test-market $out/bin/deploy-test-market
            ln -s ${run_and_deploy}/bin/run-and-deploy $out/bin/run-and-deploy
          '';
        };
      };
    });
}
