/*
 * The supported chains.
 * By default, there are only two chains here:
 *
 * - mudFoundry, the chain running on anvil that pnpm dev
 *   starts by default. It is similar to the viem anvil chain
 *   (see https://viem.sh/docs/clients/test.html), but with the
 *   basefee set to zero to avoid transaction fees.
 * - latticeTestnet, our public test network.
 *

 */

import { latticeTestnet, mudFoundry } from "@latticexyz/common/chains";

import { defineChain, Chain } from "viem";

export const tenetTestnet = defineChain(
  {
    name: "Tenet Testnet",
    id: 1337,
    network: "geth",
    nativeCurrency: { decimals: 18, name: "Ether", symbol: "ETH" },
    rpcUrls: {
      default: {
        http: ["https://testnet.biomes.aw"],
        webSocket: ["wss://testnet.biomes.aw"],
      },
      public: {
        http: ["https://testnet.biomes.aw"],
        webSocket: ["wss://testnet.biomes.aw"],
      },
    },
  },
  {
    fees: {
      defaultPriorityFee: 0n,
    },
  }
);

const sourceId: number = 17000;
export const garnetHolesky = {
  id: 17069,
  sourceId,
  name: "Garnet Holesky",
  nativeCurrency: { name: "Holesky Ether", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: {
      http: ["https://rpc.garnet.qry.live"],
      webSocket: ["wss://rpc.garnet.qry.live"],
    },
    public: {
      http: ["https://rpc.garnet.qry.live"],
      webSocket: ["wss://rpc.garnet.qry.live"],
    },
    erc4337Bundler: {
      http: ["https://bundler.garnet.qry.live"],
    },
  },
  blockExplorers: {
    default: {
      name: "Blockscout",
      url: "https://explorer.garnet.qry.live",
    },
  },
  contracts: {
    gasTank: {
      address: "0x0cc60b66279359950bf5f257e46e89d1545daf50",
    },
    optimismPortal: {
      [sourceId]: {
        address: "0x49048044D57e1C92A77f79988d21Fa8fAF74E97e",
      },
    },
  },
} satisfies Chain;

/*
 * See https://mud.dev/tutorials/minimal/deploy#run-the-user-interface
 * for instructions on how to add networks.
 */
export const supportedChains: Chain[] = [mudFoundry, latticeTestnet, tenetTestnet, garnetHolesky];
