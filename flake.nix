{
  description = "MASS_MARKET";
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    foundry.url = "github:shazow/foundry.nix"; # Use monthly branch for permanent releases
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
        forge script ./script/store-reg.s.sol:MyScript --fork-url http://localhost:8545 --broadcast --no-auto-detect --via-ir
      '';

      update_abi = pkgs.writeShellScriptBin "updateABI" ''
        forge build --no-auto-detect --via-ir --silent &&  ${pkgs.jq}/bin/jq '.abi' ./out/store-reg.sol/Store.json > ./store-reg-abi.json
      '';

      buildInputs = with pkgs; [
        # smart contracct dependencies
        foundry-bin
        solc
        deploy_market
        update_abi
      ];
    in {
      devShell = pkgs.mkShell {
        inherit buildInputs;

        # Decorative prompt override so we know when we're in a dev shell
        shellHook = ''
          export PS1="[dev] $PS1"
          export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        '';
      };
      packages = {
        test = pkgs.stdenv.mkDerivation {
          inherit buildInputs;
          name = "DMP contracts";

          unpackPhase = ":";

          buildPhase = ''
            forge compile --no-auto-detect
          '';

          checkPhase = ''
            forge test --no-auto-detect
          '';

          installPhase = "mkdir -p $out";

          doCheck = true;
        };
      };
    });
}
