{
  description = "Mass Market Contracts";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    utils.url = "github:numtide/flake-utils";
    foundry = {
      url = "github:shazow/foundry.nix/monthly";
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
  };

  outputs = {
    nixpkgs,
    utils,
    foundry,
    forge-std,
    openzeppelin-contracts,
    ds-tests,
    ...
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          foundry.overlay
        ];
      };

      deploy_market = pkgs.writeShellScriptBin "deploy-market" ''
        export PATH=$PATH:${pkgs.solc}/bin
        tmp=$(mktemp -d)
        pushd $PWD
        ${pkgs.foundry-bin}/bin/forge \
          script $PWD/script/deploy.s.sol --target-contract Deploy \
          --root=$PWD --lib-paths=$PWD \
          --fork-url http://localhost:8545 --broadcast --no-auto-detect -o $tmp --cache-path=$tmp/cache
        popd
      '';

      buildInputs = with pkgs; [
        # smart contract dependencies
        foundry-bin
        nodePackages.pnpm
        solc
        deploy_market
      ];

      remappings-txt = ''
        forge-std/=${forge-std}/src
        openzeppelin-contracts/=${openzeppelin-contracts}/
        ds-test/=${ds-tests}/src
      '';
      remappings = pkgs.writeText "remapping.txt" remappings-txt;
    in {
      devShell = pkgs.mkShell {
        inherit buildInputs;

        shellHook = ''
          export PS1="[contracts] $PS1"
          export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
          ln -sfn ${remappings} remappings.txt
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
            cp ${remappings} ./remappings.txt
            forge compile --no-auto-detect
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
            mkdir -p $out/{bin,script,abi};
            cp ${remappings} $out/remappings.txt
            cp ./script/* $out/script/
            cp ./update_env.sh $out/bin/
            cp ${deploy_market}/bin/deploy-market $out/bin/deploy-market
            substituteInPlace $out/bin/deploy-market \
               --replace "pushd \$PWD" "pushd $out" \
               --replace "script \$PWD/" "script $out/" \
               --replace "root=\$PWD" "root=$out" \
               --replace "lib-paths=\$PWD" "lib-paths=$out"
            cp -r ./src $out/src
            ln -s /tmp/ $out/broadcast
            #
          '';
        };
      };
    });
}
