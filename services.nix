{ config, lib, pkgs, ... }:
let
cfg = config.services;
mk_deploy_market =  (pkgs.writeShellScriptBin "deploy-market" ''
    tmp=$(mktemp -d)
    export FOUNDRY_BROADCAST=$tmp/broadcast
    export FOUNDRY_CACHE_PATH=$tmp/cache
    export FOUNDRY_OUT=$tmp
    export PRIVATE_KEY=${cfg.deploy.privateKey}
    set -e
    export FOUNDRY_ROOT=./
    export FOUNDRY_SOLC_VERSION=${pkgs.solc}/bin/solc
    pushd ./
    ${pkgs.foundry-bin}/bin/forge script ./script/deploy.s.sol:Deploy -s "runTestDeployImmut()" --fork-url http://localhost:8545 --broadcast
    popd
'');
in
{
    options = {
        services.anvil = {
            enable = lib.mkEnableOption "Deploy contracts";
        };
        services.deploy = {
            enable = lib.mkEnableOption "Deploy contracts";
            privateKey = lib.mkOption {
                type = lib.types.str;
                default = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
                description = "The private key to be used";
            };
        };
    };
    config = {
        settings.processes = {
            deploy = {
                command = mk_deploy_market; # | (grep -m 1 "Listening on ";
                depends_on."anvil".condition = "process_log_ready";
            };
            anvil = {
                command = "${pkgs.foundry-bin}/bin/anvil";
                ready_log_line = "Listening on";
            };
        };
    };
}