# Memory MCP

A persistent, cross-provider memory server using FastMCP, Langchain, and Postgres.

## Features

- MCP Server that agents can use to store facts about the user
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

3. Add the following config to your agent:

    ```json
    {
        "mcpServers": {
            "memory": {
                "transport": "http",
                "url": "http://localhost:1313/mcp",
                "headers": {
                    "X-User-Id": "your_user_id"
                }
            }
    }
    ```

### Openshift

1. (Optional) Update the postgres username and password in [secret.yaml](./deploy/secret.yaml)

2. Deploy the resources
   
    ```sh
    oc apply -n <your-namespace> -f deploy
    ```
