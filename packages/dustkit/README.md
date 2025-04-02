# dustkit

> Dust client SDK

## Dust apps

Dust supports "embedded apps" - modular web apps that integrate directly into the game client UI and interact with in-game objects and physics. Apps let developers build on top of the world and extend the game client with custom functionality like shops and marketplaces.

### What is a Dust app?

A Dust app is:

- A web app hosted at a URL
- Described by a JSON manifest ([schema](https://esm.sh/pr/dustproject/dust/dustkit@d9cb17b/json-schemas/embed-config.json))
- Registered onchain (once per manifest URL)
- Launched manually (e.g. installing into client's "desktop" view) or contextually (e.g. opening a chest)

### Architecture Overview

```
User action (e.g. opens chest)
└─> Dust client (detects program + associated app)
      └─> <iframe> (loads app.startUrl)
          └─> DustKit SDK (postMessage bridge)
              └─> App signals 'ready'
                  └─> Client sends context to app:
                      - entityId
                      - world address
                      - user address
                      - client version
                      ...
```

### App lifecycle

1. **Registration**: Developer interacts with the App Registry to register the app's manifest URL.
2. **Discovery**: The Dust client detects app registrations and lets users install them.
3. **Installation**: The user installs the app, reviewing and approving its declared scopes.
4. **Launch**:
   - Manual: User opens via their desktop
   - Contextual: Interacts with an in-game entity (e.g. chest)
5. **Communication**:
   - App loads in iframe
   - DustKit sets up postMessage channel
   - App sends `ready` message
   - Client sends contextual info (e.g. `entityId` of chest that opened the app)
6. **Permissions**:
   - JSON manifest changes triggers user to "update app"
   - Any actions requiring permissions not declared/approved by manifest triggers user prompt
