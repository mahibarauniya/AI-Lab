# Summary: agent.py

Brief description

- `agent.py` is a minimal interactive command-line assistant that sends user prompts to an Anthropic LLM and prints the model's replies.

What it does

- Loads environment variables from a `.env` file (the script prefers a `.env` in `donotcheckin-personalkeyinfo` one level up, falling back to default locations).
- Reads `LLM_API_KEY` (required) and `LLM_MODEL` (optional) from environment variables.
- Creates an `Anthropic` client using the API key.
- Starts a blocking REPL-style loop:
  - Prompts the user with `You:` and reads input.
  - If the user types `goodbye`, the script prints a farewell and exits.
  - Otherwise it sends the input to the LLM via `anthropic_client.messages.create(...)` with a system instruction `"You are a helpful assistant."` and prints the response pieces.

How to run

1. Ensure you have a valid `.env` containing `LLM_API_KEY` (and optionally `LLM_MODEL`). Place it in `donotcheckin-personalkeyinfo/.env` one level above the script to use the preferred location, or any default `.env` location.
2. From the folder containing `agent.py` run:

```
python agent.py
```

Notes and tips

- The script raises an error early if `LLM_API_KEY` is missing.
- The code uses `anthropic_client.messages.create` and expects the returned `message.content` to be iterable; the script prints `response.text` for each piece.
- If you want to experiment with tool integration (MCP), see the example files under `mcp_examples/02_host_w_client_interface/` in this repository.
