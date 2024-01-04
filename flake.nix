{
  description = "Mass Market Contracts";
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    foundry.url = "github:shazow/foundry.nix/monthly";
  };

  outputs = {
    nixpkgs,
    utils,
    foundry,
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
        ${pkgs.foundry-bin}/bin/forge script ./script/deploy.s.sol:Deploy --root=$PWD --fork-url http://localhost:8545 --broadcast --no-auto-detect -o $tmp --cache-path=$tmp/cache
      '';

      buildInputs = with pkgs; [
        # smart contract dependencies
        foundry-bin
        nodePackages.pnpm
        solc
        deploy_market
      ];
    in {
      devShell = pkgs.mkShell {
        inherit buildInputs;

        shellHook = ''
          export PS1="[contracts] $PS1"
          export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        '';
      };
      packages = {
        market-deploy = deploy_market;
        market-build = pkgs.stdenv.mkDerivation {
          inherit buildInputs;
          name = "mass-contracts";

          src = ./.;
          dontPatch = true;
          dontConfigure = true;

          buildPhase = ''
            forge compile --no-auto-detect
          '';

          checkPhase = ''
            forge test --no-auto-detect
          '';

          installPhase = ''
              mkdir -p $out/{bin,script,src,abi};
              ls > $out/files
              cp ${deploy_market}/bin/deploy-market $out/bin/deploy-market
              substituteInPlace $out/bin/deploy-market \
                --replace "root=\$PWD" "root=$out"
              cp -r ./src/* $out/src/
              cp -r ./script/* $out/script/
              cp -r ./lib $out/lib
solc --abi --base-path . --include-path lib/  \
  --input-file src/store-reg.sol \
  --input-file src/relay-reg.sol \
  --input-file src/payment-factory.sol \
  -o $out/abi
# overwrite for abis/sol/IERC1155Errors.abi
solc --abi --input-file lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol -o $out/abi --overwrite
          '';

          #doCheck = true;
        };
      };
    });
}
