import { foundry } from "@wagmi/cli/plugins";
import * as chains from "wagmi/chains";
import depolyerTx from "../broadcast/registires.s.sol/31337/run-latest.json" assert { type: "json" };

const relayAddress: string = depolyerTx.transactions[0].contractAddress;
const storeAddress: string = depolyerTx.transactions[1].contractAddress;

export default {
  out: "src/abi.ts",
  plugins: [
    foundry({
      deployments: {
        StoreReg: {
          [chains.foundry.id]: storeAddress as `0x${string}`,
        },
        RelayReg: {
          [chains.foundry.id]: relayAddress as `0x${string}`,
        },
      },
      include: ["payment-factory.sol/*.json", "store-reg.sol/*.json", "relay-reg.sol/*.json"],
      forge: {
        build: false,
      },
      project: "../",
    }),
  ],
};
