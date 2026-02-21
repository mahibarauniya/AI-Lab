"""
Multi-API Agent – uses Claude tool-use to route user prompts to three endpoints:
  1. Employees API  (local, port 8001) – reads employees.csv
  2. Products API   (local, port 8002) – reads products.csv
  3. Open-Meteo API (public, free, no API key) – current weather by city name

Usage:
  1. Start both local services in separate terminals:
       uvicorn services.employees_api:app --port 8001 --reload
       uvicorn services.products_api:app  --port 8002 --reload
  2. Run this agent:
       python agent.py

Example prompts:
  - "List all employees in the Engineering department"
  - "Show me products in the Electronics category"
  - "What is the weather in Tokyo?"
  - "Find employees whose name contains Kim"
"""

import json
import os
from pathlib import Path

import httpx
from anthropic import Anthropic
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Environment / API key setup (mirrors proj1 approach)
# ---------------------------------------------------------------------------
base_dir = Path(__file__).parent
private_env = base_dir.parent / "donotcheckin-personalkeyinfo" / ".env"
if private_env.exists():
    load_dotenv(private_env)
    print(f"Loaded environment from: {private_env}")
else:
    load_dotenv()
    print("Loaded environment from default locations (no private .env found)")

LLM_API_KEY = os.environ.get("LLM_API_KEY")
if not LLM_API_KEY:
    raise ValueError("LLM_API_KEY is not set. Add it to your .env file.")

MODEL = os.environ.get("LLM_MODEL", "claude-sonnet-4-20250514")

EMPLOYEES_API_BASE = os.environ.get("EMPLOYEES_API_BASE", "http://localhost:8001")
PRODUCTS_API_BASE = os.environ.get("PRODUCTS_API_BASE", "http://localhost:8002")

client = Anthropic(api_key=LLM_API_KEY)

# ---------------------------------------------------------------------------
# Tool implementations – each one calls its respective API
# ---------------------------------------------------------------------------

def get_employees(department: str | None = None, name: str | None = None, employee_id: int | None = None) -> dict:
    """Call the local Employees API."""
    with httpx.Client(timeout=10) as http:
        if employee_id is not None:
            resp = http.get(f"{EMPLOYEES_API_BASE}/employees/{employee_id}")
        elif name:
            resp = http.get(f"{EMPLOYEES_API_BASE}/employees/search", params={"name": name})
        else:
            params = {"department": department} if department else {}
            resp = http.get(f"{EMPLOYEES_API_BASE}/employees", params=params)
        resp.raise_for_status()
        return resp.json()


def get_products(category: str | None = None, name: str | None = None, product_id: int | None = None) -> dict:
    """Call the local Products API."""
    with httpx.Client(timeout=10) as http:
        if product_id is not None:
            resp = http.get(f"{PRODUCTS_API_BASE}/products/{product_id}")
        elif name:
            resp = http.get(f"{PRODUCTS_API_BASE}/products/search", params={"name": name})
        else:
            params = {"category": category} if category else {}
            resp = http.get(f"{PRODUCTS_API_BASE}/products", params=params)
        resp.raise_for_status()
        return resp.json()


def get_weather(city: str) -> dict:
    """Resolve city to coordinates via Open-Meteo geocoding, then fetch current weather."""
    with httpx.Client(timeout=10) as http:
        # Step 1 – geocode the city name
        geo = http.get(
            "https://geocoding-api.open-meteo.com/v1/search",
            params={"name": city, "count": 1, "language": "en", "format": "json"},
        )
        geo.raise_for_status()
        geo_data = geo.json()
        if not geo_data.get("results"):
            return {"error": f"Could not find coordinates for city: {city}"}
        result = geo_data["results"][0]
        lat, lon = result["latitude"], result["longitude"]
        city_full = result.get("name", city)

        # Step 2 – fetch current weather
        weather = http.get(
            "https://api.open-meteo.com/v1/forecast",
            params={
                "latitude": lat,
                "longitude": lon,
                "current": "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code",
                "timezone": "auto",
            },
        )
        weather.raise_for_status()
        weather_data = weather.json()
        current = weather_data.get("current", {})
        return {
            "city": city_full,
            "latitude": lat,
            "longitude": lon,
            "temperature_celsius": current.get("temperature_2m"),
            "humidity_percent": current.get("relative_humidity_2m"),
            "wind_speed_kmh": current.get("wind_speed_10m"),
            "weather_code": current.get("weather_code"),
        }


# ---------------------------------------------------------------------------
# Tool definitions (Claude tool-use schema)
# ---------------------------------------------------------------------------

TOOLS = [
    {
        "name": "get_employees",
        "description": (
            "Fetch employee records from the local Employees API (reads employees.csv). "
            "You can list all employees, filter by department, search by name, or look up a specific employee by ID."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "department": {
                    "type": "string",
                    "description": "Filter employees by department name (e.g. 'Engineering', 'Marketing').",
                },
                "name": {
                    "type": "string",
                    "description": "Partial name search – returns employees whose name contains this string.",
                },
                "employee_id": {
                    "type": "integer",
                    "description": "Fetch a single employee by their numeric ID.",
                },
            },
        },
    },
    {
        "name": "get_products",
        "description": (
            "Fetch product records from the local Products API (reads products.csv). "
            "You can list all products, filter by category, search by name, or look up a specific product by ID."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "category": {
                    "type": "string",
                    "description": "Filter products by category (e.g. 'Electronics', 'Furniture', 'Books').",
                },
                "name": {
                    "type": "string",
                    "description": "Partial name search – returns products whose name contains this string.",
                },
                "product_id": {
                    "type": "integer",
                    "description": "Fetch a single product by its numeric ID.",
                },
            },
        },
    },
    {
        "name": "get_weather",
        "description": (
            "Get the current weather for a city using the public Open-Meteo API (no API key required). "
            "Returns temperature, humidity, and wind speed."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "city": {
                    "type": "string",
                    "description": "Name of the city to get weather for (e.g. 'Tokyo', 'New York', 'London').",
                },
            },
            "required": ["city"],
        },
    },
]

# ---------------------------------------------------------------------------
# Tool dispatcher
# ---------------------------------------------------------------------------

TOOL_FUNCTIONS = {
    "get_employees": get_employees,
    "get_products": get_products,
    "get_weather": get_weather,
}


def run_tool(tool_name: str, tool_input: dict) -> str:
    """Execute the requested tool and return the result as a JSON string."""
    fn = TOOL_FUNCTIONS.get(tool_name)
    if fn is None:
        return json.dumps({"error": f"Unknown tool: {tool_name}"})
    try:
        result = fn(**tool_input)
        return json.dumps(result, indent=2)
    except httpx.ConnectError as exc:
        return json.dumps({"error": f"Could not connect to API: {exc}"})
    except httpx.HTTPStatusError as exc:
        return json.dumps({"error": f"API returned HTTP {exc.response.status_code}: {exc.response.text}"})
    except Exception as exc:  # noqa: BLE001
        return json.dumps({"error": str(exc)})


# ---------------------------------------------------------------------------
# Agentic loop
# ---------------------------------------------------------------------------

def run_agent(user_prompt: str) -> str:
    """
    Send the user prompt to Claude with the three tools available.
    Claude will call tools as needed and return a final text answer.
    """
    messages = [{"role": "user", "content": user_prompt}]

    while True:
        response = client.messages.create(
            model=MODEL,
            max_tokens=2048,
            system=(
                "You are a helpful data assistant. You have access to three tools:\n"
                "1. get_employees – fetch employee data from a local CSV-backed API\n"
                "2. get_products  – fetch product data from a local CSV-backed API\n"
                "3. get_weather   – fetch current weather from the public Open-Meteo API\n\n"
                "Always use the appropriate tool to answer the user's question. "
                "Present results in a clear, readable format."
            ),
            tools=TOOLS,
            messages=messages,
        )

        # If Claude wants to call tools, execute them and continue the loop
        if response.stop_reason == "tool_use":
            # Append Claude's response (which contains tool_use blocks) to the conversation
            messages.append({"role": "assistant", "content": response.content})

            # Build tool_result blocks for every tool_use block
            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    tool_output = run_tool(block.name, block.input)
                    print(f"  [tool: {block.name}({block.input})]")
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": tool_output,
                    })

            messages.append({"role": "user", "content": tool_results})

        else:
            # Claude has finished – extract the final text reply
            for block in response.content:
                if hasattr(block, "text"):
                    return block.text
            return "(No text response)"


# ---------------------------------------------------------------------------
# REPL
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("=" * 60)
    print("Multi-API Agent")
    print("Endpoints: Employees API (8001) | Products API (8002) | Open-Meteo (public)")
    print("Model:", MODEL)
    print("Type 'goodbye' to quit.")
    print("=" * 60)

    while True:
        user_input = input("\nYou: ").strip()
        if not user_input:
            continue
        if user_input.lower() == "goodbye":
            print("Agent: Goodbye!")
            break
        answer = run_agent(user_input)
        print(f"\nAgent: {answer}")
