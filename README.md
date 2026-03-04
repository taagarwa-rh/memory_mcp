# Memory MCP

A persistent, cross-provider memory server using FastMCP, Langchain, and Postgres.

## Features

- MCP Server that agents can use to store facts about the user
- Transferrable across providers - usable across multiple agents
- Compatible with any MCP-capable agent (Claude Desktop, Claude Code, Opencode, etc.)
- Backed by Postgres to ensure data persistence and scalability
- Support multiple users from a single server
- Exposes two tools to your agent:
  - `search_memory`: Search the database for memories about the user
  - `upsert_memory`: Add/update memories for the user

## Prerequisites

- Docker/Podman compose
- Openshift CLI

## Usage

### Local

1. Clone the repository:

    ```sh
    git clone https://github.com/taagarwa-rh/memory_mcp.git
    cd memory_mcp
    ```

2. Spin up the services:

    ```sh
    # For Podman
    podman compose up -d

    # For Docker
    docker compose up -d
    ```

    The MCP server will now be available at `http://localhost:1313/mcp`

### Openshift

1. (Optional) Update the postgres username and password in [secret.yaml](./deploy/secret.yaml)

2. Deploy the resources
   
    ```sh
    oc apply -n <your-namespace> -f deploy
    ```

3. Fetch the route:

    ```sh
    ROUTE=$(oc get route memory-mcp -o jsonpath='{.spec.host}')
    ROUTE="https://$ROUTE/mcp"
    echo $ROUTE
    ```

## Connect to Agents

### Claude Desktop

```json
{
    "mcpServers": {
        "memory": {
            "transport": "http",
            "url": "<mcp-route>",
            "headers": {
                "X-User-Id": "your_user_id"
            }
        }
    }
}
```

### Claude Code

```sh
claude mcp add --transport http memory https://<mcp-route>/mcp --header "X-User-Id: <your-username>"
```

### OpenCode

```sh
opencode mcp add
```

Location: Either
Name: memory
Type: Remote
URL: https://<mcp-route>/mcp

Then in your `opencode.json`, add the user ID header:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "memory": {
      "type": "remote",
      "url": "https://<mcp-route>/mcp",
      "headers": {
        "X-User-Id": "<your-username>"
      }
    }
  }
}
```
