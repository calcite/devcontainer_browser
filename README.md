# Devcontainer Browser

An isolated Chromium browser designed for AI agents running inside development containers.

When started, this project launches Chromium inside a dedicated Docker container. The browser exposes its Chrome DevTools Protocol (CDP) endpoint through:

```text
0.0.0.0:9223
```

AI agents can connect to this browser from another devcontainer and control it using tools such as Playwright.

## Quick Start

Run:

```bash
curl https://raw.githubusercontent.com/calcite/devcontainer_browser/refs/heads/master/dev_browser.sh | sh
```

This starts the Chromium container and exposes its debugging endpoint on port `9223`.

## Devcontainer Configuration

To make the Docker host accessible from your devcontainer, add the following entry to `extra_hosts`:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

For example, in `docker-compose.yml`:

```yaml
services:
  devcontainer:
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

The browser is then available from inside the devcontainer at:

```text
http://host.docker.internal:9223
```

## Using It with an AI Agent

Once the browser is running, instruct your AI agent to connect to the existing Chromium instance using Playwright over CDP.

For example:

```javascript
const { chromium } = require("playwright");

const browser = await chromium.connectOverCDP(
  "http://host.docker.internal:9223"
);
```

This keeps the browser isolated in its own container while allowing agents running in development containers to interact with a real Chromium instance.

