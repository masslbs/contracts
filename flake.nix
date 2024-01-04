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
        forge script ./script/deploy.s.sol:Deploy --fork-url http://localhost:8545 --broadcast --no-auto-detect
      '';

      buildInputs = with pkgs; [
        # smart contracct dependencies
        foundry-bin
        nodePackages.pnpm
        solc
        deploy_market
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
        deploy = deploy_market;
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
