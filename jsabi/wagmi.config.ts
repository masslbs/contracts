import { foundry } from "@wagmi/cli/plugins";
import * as chains from "wagmi/chains";
import depolyerTx from "../broadcast/store-reg.s.sol/31337/run-latest.json" assert { type: "json" };

const address: string = depolyerTx.transactions[0].contractAddress;

export default {
  out: "src/abi.ts",
  plugins: [
    foundry({
      deployments: {
        Store: {
          [chains.foundry.id]: address as `0x${string}`,
        },
      },
      include: ["payment-factory.sol/*.json", "store-reg.sol/*.json"],
      forge: {
        build: false,
      },
      project: "../",
    }),
  ],
};
