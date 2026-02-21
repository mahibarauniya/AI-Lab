# proj-2 – Multi-API Agent with FastAPI + Claude Tool-Use

An AI agent that routes natural-language prompts to **three data endpoints**:

| # | Type | What it serves | Base URL |
|---|------|----------------|----------|
| 1 | Local FastAPI | `data/employees.csv` | `http://localhost:8001` |
| 2 | Local FastAPI | `data/products.csv` | `http://localhost:8002` |
| 3 | Public REST API | Open-Meteo weather (free, no API key) | `https://api.open-meteo.com` |

The agent (Claude with tool-use) automatically decides which endpoint to call based on the user's prompt.

---

## Project structure

```
proj-2-agent read data from two endpoints using FastAPI/
├── data/
│   ├── employees.csv          # 15 sample employee records
│   └── products.csv           # 15 sample product records
├── services/
│   ├── employees_api.py       # FastAPI app – port 8001
│   └── products_api.py        # FastAPI app – port 8002
├── agent.py                   # Agentic loop (Claude + 3 tools)
├── requirements.txt
└── README.md
```

---

## Prerequisites

- Python 3.11+
- An `LLM_API_KEY` (Anthropic API key) in a `.env` file

Place your `.env` in `donotcheckin-personalkeyinfo/.env` (one level above the project root) **or** in the project directory itself:

```
LLM_API_KEY=sk-ant-...
# LLM_MODEL=claude-sonnet-4-20250514   # optional override
```

---

## Setup

```bash
# From inside this project folder
pip install -r requirements.txt
```

---

## Running

### Step 1 – Start the local APIs (two separate terminals)

```bash
# Terminal 1 – Employees API on port 8001
uvicorn services.employees_api:app --port 8001 --reload

# Terminal 2 – Products API on port 8002
uvicorn services.products_api:app --port 8002 --reload
```

Once running you can verify them directly:
- http://localhost:8001/docs  (Swagger UI for Employees API)
- http://localhost:8002/docs  (Swagger UI for Products API)

### Step 2 – Start the agent (third terminal)

```bash
python agent.py
```

---

## API reference

### Employees API (`http://localhost:8001`)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/employees` | List all employees; add `?department=Engineering` to filter |
| GET | `/employees/{id}` | Get one employee by numeric ID |
| GET | `/employees/search?name=Kim` | Search employees by partial name |

### Products API (`http://localhost:8002`)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/products` | List all products; add `?category=Electronics` to filter |
| GET | `/products/{id}` | Get one product by numeric ID |
| GET | `/products/search?name=book` | Search products by partial name |

### Public Weather API (Open-Meteo)

Called transparently by the agent's `get_weather` tool – no setup needed.

---

## Example agent prompts

```
You: List all employees in the Engineering department
You: Show me products in the Electronics category
You: What is the current weather in Tokyo?
You: Find employees whose name contains Kim
You: How many products does BookWorld supply?
You: What is the salary range for employees in Finance?
You: Get weather for London and Paris
goodbye
```

---

## How it works

```
User prompt
    │
    ▼
Claude (tool-use)
    │
    ├── get_employees  ──► http://localhost:8001  (reads employees.csv)
    ├── get_products   ──► http://localhost:8002  (reads products.csv)
    └── get_weather    ──► https://api.open-meteo.com  (public API)
    │
    ▼
Final natural-language answer
```

1. The user types a natural-language prompt.
2. Claude analyses the prompt and emits one or more `tool_use` blocks.
3. `agent.py` executes the appropriate HTTP calls and returns the JSON results.
4. Claude synthesises a readable answer from the tool results.
