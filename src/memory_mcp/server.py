import asyncio
import logging
import os
import uuid

from dotenv import load_dotenv
from fastmcp import FastMCP
from fastmcp.exceptions import ToolError
from fastmcp.server.dependencies import get_http_headers
from langgraph.store.postgres import AsyncPostgresStore

# Load environment variables
load_dotenv()
DB_URI = os.getenv("DB_URI")

logger = logging.getLogger(__name__)

mcp = FastMCP(name="Memory")


def get_user_id():
    """Get the requesting user ID."""
    headers = get_http_headers()
    print(headers)
    user_id = headers.get("x-user-id")
    if user_id is None:
        logger.error("Missing X-User-Id header")
        raise ToolError("User did not provide their user ID in the X-User-Id header")
    return user_id


async def setup_store():
    """Set up the database memory store."""
    async with AsyncPostgresStore.from_conn_string(DB_URI) as store:
        await store.setup()


@mcp.tool()
async def search_memory(
    query: str,
) -> list[dict[str, str]]:
    """
    Search the database for memories about the user.

    This will return a list of memories. Each memory will have an ID, content, and context.

    Args:
        query: Search query. For example: "What are the user's interests?"

    Returns:
        list[dict]: List of memories, including ID, content, and context.
    """
    # Query the database for memories that match the query
    user_id = get_user_id()
    namespace = ("memories", user_id)
    async with AsyncPostgresStore.from_conn_string(DB_URI) as store:
        memories = await store.asearch(namespace, query=query)

    memories = [{"id": m.key, "content": m.value["content"], "context": m.value["context"]} for m in memories]
    return memories


@mcp.tool()
async def upsert_memory(
    content: str,
    context: str,
    *,
    memory_id: uuid.UUID | None = None,
):
    """
    Upsert a memory about the user in the database.

    If a memory conflicts with an existing one, then just UPDATE the
    existing one by passing in memory_id - don't create two memories
    that are the same. If the user corrects a memory, UPDATE it.

    Args:
        content: The main content of the memory. For example:
            "User expressed interest in learning about French."
        context: Additional context for the memory. For example:
            "This was mentioned while discussing career options in Europe."
        memory_id: ONLY PROVIDE IF UPDATING AN EXISTING MEMORY.
        The memory to overwrite.

    Returns:
        str: A success message
    """
    user_id = get_user_id()

    mem_id = memory_id or uuid.uuid4()
    namespace = ("memories", user_id)
    async with AsyncPostgresStore.from_conn_string(DB_URI) as store:
        await store.aput(
            namespace,
            key=str(mem_id),
            value={"content": content, "context": context},
        )
    return f"Stored memory {mem_id}"


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(name)s - %(message)s")
    asyncio.run(setup_store())
    mcp.run(transport="http", host="0.0.0.0", port=1313)
