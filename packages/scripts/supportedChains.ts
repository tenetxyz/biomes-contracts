import { garnet, mudFoundry, redstone } from "@latticexyz/common/chains";

import { Chain } from "viem";

export const biomesTestnet = {
  name: "Biomes Testnet",
  id: 1337,
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
} satisfies Chain;

/*
 * See https://mud.dev/tutorials/minimal/deploy#run-the-user-interface
 * for instructions on how to add networks.
 */
export const supportedChains: Chain[] = [mudFoundry, biomesTestnet, garnet, redstone];
