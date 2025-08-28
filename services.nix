{inputs}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services;
in {
  options = {
    services.anvil = {
      enable = lib.mkEnableOption "Start anvil";
    };
    services.deploy-contracts = {
      enable = lib.mkEnableOption "Deploy contracts";
      rpcUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:8545";
        description = "The Ethereum RPC URL to be used";
      };
      privateKey = lib.mkOption {
        type = lib.types.str;
        default = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
        description = "The private key to be used";
      };
    };
  };
  config = {
    settings.processes = lib.mkMerge [
      (lib.mkIf cfg.deploy-contracts.enable {
        deploy-contracts = {
          environment = {
            PRIVATE_KEY = cfg.deploy-contracts.privateKey;
            FOUNDRY_ETH_RPC_URL = cfg.deploy-contracts.rpcUrl;
          };
          command = inputs.self.packages.${pkgs.system}.deploy-market;
          depends_on = lib.mkIf cfg.anvil.enable {
            "anvil".condition = "process_log_ready";
          };
          log_location = "$FLAKE_ROOT/logs/deploy.log";
        };
      })
      (lib.mkIf cfg.anvil.enable {
        anvil = {
          command = "${pkgs.foundry}/bin/anvil";
          ready_log_line = "Listening on";
          log_location = "$FLAKE_ROOT/logs/anvil.log";
        };
      })
    ];
  };
}
