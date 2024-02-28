# Everlon

Everlon is on-chain Minecraft. This repo hosts the contracts.

### Running

```
pnpm run dev
```

### Installation

1. Make sure sure you have:

- [Node.js v18](https://nodejs.org/en/download/package-manager)
- [pnpm](https://pnpm.io/)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

2. Clone our mud fork at https://github.com/tenetxyz/mud and place it in the same directory as this directory:

```
development/
   everlon-contracts/
   mud/
```

- Note: We've forked MUD so we can modify some of the packages. This repo depends on our fork of MUD.

3. In our mud fork, run pnpm install (to install all dependencies)
4. In our mud fork, run pnpm build (to build all packages)
5. `pnpm install`
