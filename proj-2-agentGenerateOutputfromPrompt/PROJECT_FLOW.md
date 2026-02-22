# Currency & Country Analysis Agent — Complete Project Flow

## Overview

This project is a **Currency and Country Analysis Agent** built using:
- **Claude (Anthropic)** as the reasoning/decision layer
- **Direct tool integration** (no separate MCP server required in basic flow)
- **Local CSV files** as data sources (via FastAPI endpoints)
- **Live Exchange Rates API** (open.er-api.com) for real-time currency data
- **CSV output format** for saving results

---

## Project Structure

```
proj-2-agentGenerateOutputfromPrompt/
│
├── .env                              # Config: API keys (in donotcheckin-personalkeyinfo/)
├── main.py                           # Entry point - loads tools, runs agent, saves CSV
├── test_main.py                      # Test file for the application
│
├── data/
│   ├── countries.csv                 # country_code, country_name
│   └── country_currency.csv          # country_name, currency_name, currency_code
│
├── tools/
│   ├── country_tool.py               # Reads countries.csv
│   ├── country_currency_tool.py      # Reads country_currency.csv from FastAPI
│   └── currency_rates_tool.py        # Calls live Exchange Rates API
│
├── agent/
│   └── agent.py                      # Claude LLM agentic loop with tool execution
│
├── api/
│   ├── countries.py                  # FastAPI endpoint for countries (port 5001)
│   ├── country_currency.py           # FastAPI endpoint for country-currency (port 5003)
│   └── __init__.py
│
├── mcp_server/
│   └── server.py                     # MCP server (optional - alternative architecture)
│
├── output/                           # Generated CSV reports land here
│
└── PROJECT_FLOW.md                   # This file
```

---

## Data Sources

| Source | Type | File / URL |
|---|---|---|
| Country Data | Local CSV | `data/countries.csv` |
| Currency Data | Local CSV | `data/country_currency.csv` |
| Exchange Rates | Live API | `https://open.er-api.com/v6/latest/USD` |

### How the Data Sources Interlink

```
countries.csv                    country_currency.csv
─────────────────                ──────────────────────────────
country_code                     country_name  ──→  links to countries.csv
country_name  ──────────────────→country_name
                                 currency_name
                                 currency_code ──→  Exchange Rates API
                                                         ↓
                                               GET /v6/latest/USD
                                               returns live exchange rates (INR: 90.97147, etc.)
```

**Linking Keys:**
- `countries.country_name` → `country_currency.country_name`
- `country_currency.currency_code` → Exchange Rates API currency code (e.g., INR, EUR, JPY)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        USER INPUT                               │
│   "What is the exchange rate for India?"                        │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        main.py                                  │
│   1. Load .env configuration (API keys)                         │
│   2. Create LLM client (Claude)                                 │
│   3. Initialize tool instances:                                 │
│      - CurrencyRatesTool()                                      │
│      - CountryCurrencyTool()                                    │
│   4. Define tools schema for Claude                             │
│   5. Define tool_handler function                               │
│   6. Call run_agent_conversation()                              │
│   7. Parse and save result to CSV                               │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  agent/agent.py                                 │
│  run_agent_conversation(llm_client, model, tools, message,      │
│                         tool_handler)                           │
│                                                                 │
│  Agentic Loop:                                                  │
│  1. Send user message to Claude with tools schema               │
│  2. Claude responds with tool_use or final answer               │
│  3. If tool_use: call tool_handler, append result to messages   │
│  4. Loop until Claude gives final text answer                   │
│  5. Return natural language response                            │
└──────────┬──────────────────────────────────────┬───────────────┘
           │                                      │
           │ Claude requests tools                │ Results returned
           ▼                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│              tool_handler (defined in main.py)                  │
│                                                                 │
│  Routes tool calls:                                             │
│  - get_currency_by_country  → CountryCurrencyTool               │
│  - get_exchange_rate        → CurrencyRatesTool                 │
│                                                                 │
│  Executes tool and returns result string to agent               │
└───────┬─────────────────────────────┬───────────────────────────┘
        │                             │
        ▼                             ▼
┌────────────────────────┐   ┌─────────────────────────┐
│ CountryCurrencyTool    │   │ CurrencyRatesTool       │
│                        │   │                         │
│ - get_by_country_name()│   │ - get_rate(code)        │
│                        │   │                         │
│ Calls:                 │   │ Calls:                  │
│ http://localhost:5003  │   │ https://open.er-api.com │
│ (FastAPI endpoint)     │   │ (Live public API)       │
└────────────────────────┘   └─────────────────────────┘
        │                             │
        ▼                             ▼
┌────────────────────────┐   ┌─────────────────────────┐
│ country_currency.csv   │   │ Live Exchange Rates     │
│ (via FastAPI)          │   │ INR: 90.97147           │
│                        │   │ EUR: 0.93...            │
└────────────────────────┘   │ JPY: 149.5...           │
                             └─────────────────────────┘
```

---

## Step by Step Detailed Flow

### STEP 1 — User Runs `main.py`

```bash
python main.py
```

**What happens:**

```python
main.py
  │
  ├── setup_environment()       # Loads .env from donotcheckin-personalkeyinfo/
  ├── load_config()             # Gets LLM_API_KEY and MODEL
  ├── create_llm_client()       # Creates Anthropic client
  ├── print welcome message
  ├── input("Your question: ")  # Waits for user input
  └── calls run_agent(user_input, llm_client, model)
```

---

### STEP 2 — Agent Initializes Tools

```python
run_agent(user_input, llm_client, model):
  │
  ├── Initialize tool instances:
  │     currency_rates_tool = CurrencyRatesTool()
  │     country_currency_tool = CountryCurrencyTool()
  │
  ├── Define tools schema (2 tools):
  │     [
  │       {
  │         "name": "get_currency_by_country",
  │         "description": "Get the official currency...",
  │         "input_schema": {...}
  │       },
  │       {
  │         "name": "get_exchange_rate",
  │         "description": "Get the current live exchange rate...",
  │         "input_schema": {...}
  │       }
  │     ]
  │
  └── Define tool_handler(tool_name, tool_input) function
```

---

### STEP 3 — Call Agent Conversation Loop

```python
result = run_agent_conversation(
    llm_client, 
    model, 
    tools,           # 2 tool schemas
    user_input,      # "What is the exchange rate for India?"
    tool_handler     # Function to execute tools
)
```

---

### STEP 4 — Agent Sends First Message to Claude

```python
agent/agent.py → run_agent_conversation()
  │
  ├── Build messages list:
  │     messages = [
  │       {
  │         "role": "user",
  │         "content": "What is the exchange rate for India?"
  │       }
  │     ]
  │
  ├── Build system prompt (embedded in agent.py):
  │     "You are a helpful AI assistant with access to ONLY 2 tools:
  │      1. get_currency_by_country
  │      2. get_exchange_rate"
  │
  └── Send to Claude:
        response = llm_client.messages.create(
            model=model,
            max_tokens=4096,
            system=system_prompt,
            tools=tools,              # Tool schemas
            messages=messages
        )
```

---

### STEP 5 — Claude Decides to Use Tools

Claude receives the message and thinks:

```
User asked: "What is the exchange rate for India?"
  → I need to find India's currency first
  → Call: get_currency_by_country(country="India")
```

Claude responds with `stop_reason == "tool_use"` and a tool call:

```json
{
  "content": [
    {
      "type": "tool_use",
      "id": "toolu_abc123",
      "name": "get_currency_by_country",
      "input": {"country": "India"}
    }
  ]
}
```

---

### STEP 6 — Agent Executes Tool via Handler

```python
agent/agent.py detects tool_use:
  │
  ├── Extract: tool_name = "get_currency_by_country"
  ├── Extract: tool_input = {"country": "India"}
  │
  └── Call: result = tool_handler("get_currency_by_country", {"country": "India"})
```

```python
tool_handler in main.py:
  │
  ├── if tool_name == "get_currency_by_country":
  │     result = country_currency_tool.get_by_country_name("India")
  │     # Returns: {"currency_name": "Indian Rupee", "currency_code": "INR"}
  │     
  │     return "The currency of India is Indian Rupee (INR)."
```

**CountryCurrencyTool** calls FastAPI endpoint:
```python
GET http://localhost:5003/?country_name=India
  → Reads country_currency.csv
  → Returns: {"currency_name": "Indian Rupee", "currency_code": "INR"}
```

---

### STEP 7 — Tool Result Sent Back to Claude

```python
agent/agent.py:
  │
  ├── Append tool result to messages:
  │     {
  │       "type": "tool_result",
  │       "tool_use_id": "toolu_abc123",
  │       "content": "The currency of India is Indian Rupee (INR)."
  │     }
  │
  ├── Append to conversation:
  │     messages.append({
  │       "role": "user",
  │       "content": [tool_result]
  │     })
  │
  └── Send back to Claude for next decision
```

---

### STEP 8 — Claude Calls Second Tool

Claude now knows India's currency is INR. It decides:

```
Now I know the currency code is INR
  → Call: get_exchange_rate(currency="INR")
```

Response:

```json
{
  "content": [
    {
      "type": "tool_use",
      "id": "toolu_def456",
      "name": "get_exchange_rate",
      "input": {"currency": "INR"}
    }
  ]
}
```

---

### STEP 9 — Agent Calls Exchange Rate Tool

```python
tool_handler("get_exchange_rate", {"currency": "INR"}):
  │
  └── result = currency_rates_tool.get_rate("INR")
        │
        └── GET https://open.er-api.com/v6/latest/USD
              │
              └── Returns: {
                    "currency": "INR",
                    "rate": 90.97147,
                    "base": "USD",
                    "timestamp": "Sat, 22 Feb 2026 00:00:01 +0000"
                  }
      
      return "The current exchange rate for INR (Indian Rupee) is 1 USD = 90.97147 INR."
```

---

### STEP 10 — Claude Produces Final Answer

Agent sends tool result back to Claude. Claude now has all the info:
- Country: India
- Currency: INR (Indian Rupee)
- Exchange rate: 1 USD = 90.97147 INR

Claude produces **final text response** (not a tool call):

```
"The current exchange rate for the Indian Rupee (INR) is **1 USD = 90.97 INR**.
This means that 1 US Dollar can be exchanged for approximately 90.97 Indian Rupees 
at the current market rate."
```

`stop_reason == "end_turn"` → Loop ends

---

### STEP 11 — `main.py` Parses and Saves Result

```python
main.py:
  │
  ├── result = run_agent() 
  │     # Returns Claude's final text answer
  │
  ├── parse_result(user_input, result)
  │     # Uses regex to extract:
  │     # - country: "India"
  │     # - currency_code: "INR"
  │     # - currency_name: "Rupee"
  │     # - exchange_rate: "90.97"
  │
  ├── save_result_to_file(user_input, parsed_data)
  │     # Creates: output/india_exchange_rate_20260222_003841.csv
  │     # Content:
  │     #   timestamp,question,country,currency_code,currency_name,exchange_rate,base_currency
  │     #   2026-02-22 00:38:41,India exchange rate,India,INR,Rupee,90.97,USD
  │
  └── print("✓ Result saved to: ...")
```

---

## Complete Message Timeline (Agent Loop)

```
Round 1:
  SEND  →  [user: "What is the exchange rate for India?"]
  RECV  ←  tool_use: get_currency_by_country(country="India")

Round 2:
  SEND  →  [user, assistant(tool_use), user(tool_result: "...Indian Rupee (INR)")]
  RECV  ←  tool_use: get_exchange_rate(currency="INR")

Round 3:
  SEND  →  [user, assistant(tool_use), user(tool_result), 
            assistant(tool_use), user(tool_result: "...90.97147 INR")]
  RECV  ←  Final text answer: "The current exchange rate for the Indian Rupee..."
           stop_reason: "end_turn" → Loop ends
```

---

## Tools Available

| Tool Name | Description | Input | Output |
|---|---|---|---|
| `get_currency_by_country` | Get currency for a country | `country` (string) | Currency name and code |
| `get_exchange_rate` | Get live exchange rate | `currency` (string) | Rate vs USD from live API |

---

## What Each File Does

| File | Role |
|---|---|
| `.env` | Stores API keys (LLM_API_KEY, LLM_MODEL) in donotcheckin-personalkeyinfo/ |
| `main.py` | Entry point: loads tools, runs agent, parses result, saves CSV |
| `agent/agent.py` | Claude agentic loop: sends messages, handles tool calls, returns answer |
| `tools/currency_rates_tool.py` | Calls live API (open.er-api.com) for exchange rates |
| `tools/country_currency_tool.py` | Calls FastAPI endpoint (localhost:5003) for currency data |
| `data/countries.csv` | Master list of countries + codes |
| `data/country_currency.csv` | Maps country → currency name + code |
| `api/country_currency.py` | FastAPI endpoint serving country_currency.csv data |
| `output/` | All generated CSV reports land here |
| `mcp_server/server.py` | Alternative MCP architecture (not used in main flow) |

---

## Output Format

Results are saved as **CSV files** with this structure:

```csv
timestamp,question,country,currency_code,currency_name,exchange_rate,base_currency
2026-02-22 00:38:41,India exchange rate,India,INR,Rupee,90.97,USD
```

**Filename format:** `{concise_key_terms}_{timestamp}.csv`

Examples:
- `india_exchange_rate_20260222_003841.csv`
- `capital_france_20260222_120000.csv`
- `currency_rates_japan_20260222_150000.csv`

**Key features:**
- Stop words removed ("what", "is", "the", etc.)
- Maximum 25 characters (concise)
- Only first 3-4 key terms used
- Timestamp ensures uniqueness

---

## Common Query Examples

| User Query | Tools Called | Output |
|---|---|---|
| `What is the exchange rate for India?` | `get_currency_by_country` → `get_exchange_rate` | Country, currency, live rate |
| `India exchange rate` | `get_currency_by_country` → `get_exchange_rate` | Country, currency, live rate |
| `What currency does Japan use?` | `get_currency_by_country` | Currency name and code |
| `EUR to USD rate` | `get_exchange_rate` | Live exchange rate for EUR |

---

## How to Run

### Option 1: Basic Flow (Current Implementation)

```bash
# Step 1 — Install dependencies
pip install anthropic requests python-dotenv

# Step 2 — Add your Claude API key to .env
# Location: donotcheckin-personalkeyinfo/.env
LLM_API_KEY=sk-ant-your-key-here
LLM_MODEL=claude-sonnet-4-20250514

# Step 3 — (Optional) Start FastAPI endpoint for country-currency data
# Terminal 1:
uvicorn api.country_currency:app --reload --port 5003

# Step 4 — Run the Agent
# Terminal 2:
python main.py
```

### Option 2: MCP Server Architecture (Alternative)

```bash
# Terminal 1: Start MCP Server
uvicorn mcp_server.server:app --host 0.0.0.0 --port 8000 --reload

# Terminal 2: Run agent (configured to use MCP server)
python main.py
```

---

## Key Improvements in Current Version

✅ **CSV Output** - Structured data format instead of JSON
✅ **Concise Filenames** - Smart stop-word removal, max 25 chars
✅ **Live API Integration** - Real exchange rates from open.er-api.com
✅ **Direct Tool Integration** - No separate MCP server required for basic flow
✅ **Claude Integration** - Using Anthropic's Claude instead of OpenAI
✅ **Tool Handler** - Clean separation between tool definition and execution
✅ **Regex Parsing** - Extracts key data from natural language responses

---

## API Dependencies

| Service | Port | Purpose | Required |
|---|---|---|---|
| country_currency API | 5003 | Serves country-currency CSV data | Optional* |
| Exchange Rates API | N/A | Live currency rates (public internet) | Yes |
| MCP Server | 8000 | Alternative architecture | Optional |

*CountryCurrencyTool can fall back to reading CSV directly if FastAPI is not running

---

## Error Handling

The system handles:
- ❌ Missing API keys → Clear error message
- ❌ API connection failures → Graceful fallback with error message
- ❌ Invalid country names → "Could not find..." message
- ❌ Invalid currency codes → "Could not fetch..." message
- ❌ Empty results → CSV saved with available data
- ❌ Parsing failures → Default values in CSV

---

*Last Updated: February 22, 2026*
*AI-Lab Project — Currency & Country Analysis Agent*
