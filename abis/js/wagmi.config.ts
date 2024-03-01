// SPDX-FileCopyrightText: 2024 Mass Labs
//
// SPDX-License-Identifier: GPL-3.0-or-later

import { foundry } from "@wagmi/cli/plugins";
import * as chains from "wagmi/chains";
import depolyerTx from "../../broadcast/deploy.s.sol/31337/run-latest.json" assert { type: "json" };

function getAddress(name: string): `0x${string}` {
  return (
    (depolyerTx.transactions.find((a) => a.contractName === name)
      ?.contractAddress as `0x${string}`) ?? "0x00" //nullish coalescing
  );
}

console.log(getAddress("StoreReg"))

export default {
  out: "src/abi.ts",
  plugins: [
    foundry({
      deployments: {
        PaymentFactory: {
          [chains.foundry.id]: getAddress("PaymentFactory"),
        },
        StoreReg: {
          [chains.foundry.id]: getAddress("StoreReg"),
        },
        RelayReg: {
          [chains.foundry.id]: getAddress("RelayReg"),
        },
      },
      include: [
        "payment-factory.sol/*.json",
        "store-reg.sol/*.json",
        "relay-reg.sol/*.json",
      ],
      forge: {
        build: false,
      },
      project: "../../",
    }),
  ],
};
