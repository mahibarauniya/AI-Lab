"""
proj-3: AI Data Explorer – Streamlit app
Deployable for free on Streamlit Community Cloud (share.streamlit.io)

Tabs:
  🤖 AI Chat   – Claude agent with tool-use (employees, products, weather)
  👥 Employees – Browse / filter employees CSV
  📦 Products  – Browse / filter products CSV
  🌤️ Weather   – Current weather via Open-Meteo (no API key needed)

API key priority:
  1. st.secrets["LLM_API_KEY"]   – Streamlit Community Cloud secrets
  2. Sidebar text-input           – quick local testing
"""

from __future__ import annotations

import json
import os
from pathlib import Path

import httpx
import pandas as pd
import streamlit as st
from anthropic import Anthropic

# ---------------------------------------------------------------------------
# Page config (must be first Streamlit call)
# ---------------------------------------------------------------------------
st.set_page_config(
    page_title="AI Data Explorer",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
DATA_DIR = Path(__file__).parent / "data"
EMPLOYEES_CSV = DATA_DIR / "employees.csv"
PRODUCTS_CSV = DATA_DIR / "products.csv"

# ---------------------------------------------------------------------------
# Helper: load CSVs (cached so they are read only once per session)
# ---------------------------------------------------------------------------

@st.cache_data
def load_employees() -> pd.DataFrame:
    return pd.read_csv(EMPLOYEES_CSV)


@st.cache_data
def load_products() -> pd.DataFrame:
    return pd.read_csv(PRODUCTS_CSV)

# ---------------------------------------------------------------------------
# Sidebar – API key input
# ---------------------------------------------------------------------------
with st.sidebar:
    st.title("⚙️ Configuration")

    # Try Streamlit secrets first, then fall back to user input
    api_key_from_secrets = st.secrets.get("LLM_API_KEY", "") if hasattr(st, "secrets") else ""
    if api_key_from_secrets:
        llm_api_key = api_key_from_secrets
        st.success("API key loaded from secrets ✅")
    else:
        llm_api_key = st.text_input(
            "Anthropic API Key",
            type="password",
            placeholder="sk-ant-...",
            help="Required for the AI Chat tab. Get yours at console.anthropic.com",
        )

    llm_model = st.selectbox(
        "Claude model",
        options=[
            "claude-sonnet-4-20250514",
            "claude-3-5-haiku-20241022",
            "claude-opus-4-20250514",
        ],
        index=0,
    )

    st.divider()
    st.markdown(
        "**Data sources**\n"
        "- 👥 `data/employees.csv`\n"
        "- 📦 `data/products.csv`\n"
        "- 🌤️ [Open-Meteo](https://open-meteo.com/) (public API)"
    )
    st.divider()
    st.markdown(
        "**Deploy this app free** → [Streamlit Community Cloud](https://share.streamlit.io)"
    )

# ---------------------------------------------------------------------------
# Tabs
# ---------------------------------------------------------------------------
tab_chat, tab_emp, tab_prod, tab_weather = st.tabs(
    ["🤖 AI Chat", "👥 Employees", "📦 Products", "🌤️ Weather"]
)

# ===========================================================================
# TAB 1 – AI Chat
# ===========================================================================
with tab_chat:
    st.header("🤖 AI Data Assistant")
    st.caption(
        "Ask anything about employees, products, or current weather. "
        "Claude will call the right tool automatically."
    )

    # --- Tool implementations (read CSVs / call Open-Meteo directly) --------

    def tool_get_employees(
        department: str | None = None,
        name: str | None = None,
        employee_id: int | None = None,
    ) -> dict:
        df = load_employees()
        if employee_id is not None:
            row = df[df["id"] == int(employee_id)]
            if row.empty:
                return {"error": f"No employee with id={employee_id}"}
            return row.iloc[0].to_dict()
        if name:
            df = df[df["name"].str.contains(name, case=False, na=False)]
        if department:
            df = df[df["department"].str.lower() == department.lower()]
        return {"count": len(df), "employees": df.to_dict(orient="records")}

    def tool_get_products(
        category: str | None = None,
        name: str | None = None,
        product_id: int | None = None,
    ) -> dict:
        df = load_products()
        if product_id is not None:
            row = df[df["id"] == int(product_id)]
            if row.empty:
                return {"error": f"No product with id={product_id}"}
            return row.iloc[0].to_dict()
        if name:
            df = df[df["name"].str.contains(name, case=False, na=False)]
        if category:
            df = df[df["category"].str.lower() == category.lower()]
        return {"count": len(df), "products": df.to_dict(orient="records")}

    def tool_get_weather(city: str) -> dict:
        try:
            with httpx.Client(timeout=10) as http:
                geo = http.get(
                    "https://geocoding-api.open-meteo.com/v1/search",
                    params={"name": city, "count": 1, "language": "en", "format": "json"},
                )
                geo.raise_for_status()
                results = geo.json().get("results")
                if not results:
                    return {"error": f"City not found: {city}"}
                loc = results[0]
                lat, lon = loc["latitude"], loc["longitude"]
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
                cur = weather.json().get("current", {})
                return {
                    "city": loc.get("name", city),
                    "latitude": lat,
                    "longitude": lon,
                    "temperature_celsius": cur.get("temperature_2m"),
                    "humidity_percent": cur.get("relative_humidity_2m"),
                    "wind_speed_kmh": cur.get("wind_speed_10m"),
                    "weather_code": cur.get("weather_code"),
                }
        except httpx.ConnectError:
            return {"error": "Could not reach the weather API. Check your network connection."}
        except httpx.HTTPStatusError as exc:
            return {
                "error": (
                    f"Weather API returned HTTP {exc.response.status_code}: "
                    f"{exc.response.text[:200]}"
                )
            }

    TOOL_FNS = {
        "get_employees": tool_get_employees,
        "get_products": tool_get_products,
        "get_weather": tool_get_weather,
    }

    TOOLS = [
        {
            "name": "get_employees",
            "description": (
                "Fetch employee records from employees.csv. "
                "Supports filtering by department, searching by name, or fetching by ID."
            ),
            "input_schema": {
                "type": "object",
                "properties": {
                    "department": {"type": "string", "description": "Filter by department name."},
                    "name": {"type": "string", "description": "Partial name search."},
                    "employee_id": {"type": "integer", "description": "Exact employee ID."},
                },
            },
        },
        {
            "name": "get_products",
            "description": (
                "Fetch product records from products.csv. "
                "Supports filtering by category, searching by name, or fetching by ID."
            ),
            "input_schema": {
                "type": "object",
                "properties": {
                    "category": {"type": "string", "description": "Filter by category name."},
                    "name": {"type": "string", "description": "Partial name search."},
                    "product_id": {"type": "integer", "description": "Exact product ID."},
                },
            },
        },
        {
            "name": "get_weather",
            "description": "Get current weather for a city via Open-Meteo (no API key needed).",
            "input_schema": {
                "type": "object",
                "properties": {
                    "city": {"type": "string", "description": "City name, e.g. 'Tokyo'."},
                },
                "required": ["city"],
            },
        },
    ]

    def run_tool(name: str, inputs: dict) -> str:
        fn = TOOL_FNS.get(name)
        if fn is None:
            return json.dumps({"error": f"Unknown tool: {name}"})
        try:
            return json.dumps(fn(**inputs), indent=2)
        except Exception as exc:  # noqa: BLE001
            return json.dumps({"error": f"Tool '{name}' failed: {exc}"})

    def run_agent(messages: list[dict], api_key: str, model: str) -> str:
        anthropic = Anthropic(api_key=api_key)
        while True:
            resp = anthropic.messages.create(
                model=model,
                max_tokens=2048,
                system=(
                    "You are a helpful data assistant with access to three tools:\n"
                    "• get_employees – employee data from a CSV file\n"
                    "• get_products  – product data from a CSV file\n"
                    "• get_weather   – current weather via Open-Meteo\n\n"
                    "Always use the appropriate tool to answer the user's question. "
                    "Present results in a clear, readable format using markdown."
                ),
                tools=TOOLS,
                messages=messages,
            )
            if resp.stop_reason == "tool_use":
                messages.append({"role": "assistant", "content": resp.content})
                tool_results = []
                for block in resp.content:
                    if block.type == "tool_use":
                        output = run_tool(block.name, block.input)
                        tool_results.append({
                            "type": "tool_result",
                            "tool_use_id": block.id,
                            "content": output,
                        })
                messages.append({"role": "user", "content": tool_results})
            else:
                for block in resp.content:
                    if hasattr(block, "text"):
                        return block.text
                return "(No response)"

    # --- Chat UI -----------------------------------------------------------

    if "chat_messages" not in st.session_state:
        st.session_state.chat_messages = []  # list of {"role", "content"}

    # Display conversation history
    for msg in st.session_state.chat_messages:
        if msg["role"] in ("user", "assistant"):
            with st.chat_message(msg["role"]):
                st.markdown(msg["content"])

    # Example prompts
    if not st.session_state.chat_messages:
        st.info(
            "💡 **Try asking:**\n"
            "- *List all employees in the Engineering department*\n"
            "- *Show me Electronics products*\n"
            "- *What is the weather in Tokyo?*\n"
            "- *How many products does BookWorld supply?*"
        )

    # Input box
    user_input = st.chat_input("Ask me about employees, products, or weather…")
    if user_input:
        if not llm_api_key:
            st.error("Please enter your Anthropic API key in the sidebar first.")
        else:
            # Show user message immediately
            with st.chat_message("user"):
                st.markdown(user_input)
            st.session_state.chat_messages.append({"role": "user", "content": user_input})

            # Build messages list (only simple user/assistant text turns)
            api_messages = [
                {"role": m["role"], "content": m["content"]}
                for m in st.session_state.chat_messages
                if m["role"] in ("user", "assistant")
            ]

            with st.chat_message("assistant"):
                with st.spinner("Thinking…"):
                    try:
                        answer = run_agent(api_messages, llm_api_key, llm_model)
                    except Exception as exc:  # noqa: BLE001
                        exc_str = str(exc)
                        if "api_key" in exc_str.lower() or "authentication" in exc_str.lower() or "401" in exc_str:
                            answer = "⚠️ **Invalid or missing API key.** Please check the key you entered in the sidebar."
                        elif "rate_limit" in exc_str.lower() or "429" in exc_str:
                            answer = "⚠️ **Rate limit reached.** Please wait a moment and try again."
                        elif "connect" in exc_str.lower() or "network" in exc_str.lower():
                            answer = "⚠️ **Network error.** Could not reach the Anthropic API. Check your connection."
                        else:
                            answer = f"⚠️ **Unexpected error:** {exc_str}"
                st.markdown(answer)

            st.session_state.chat_messages.append({"role": "assistant", "content": answer})

    if st.session_state.chat_messages:
        if st.button("🗑️ Clear chat"):
            st.session_state.chat_messages = []
            st.rerun()

# ===========================================================================
# TAB 2 – Employees
# ===========================================================================
with tab_emp:
    st.header("👥 Employees")

    df_emp = load_employees()

    col1, col2 = st.columns([1, 2])
    with col1:
        dept_options = ["All"] + sorted(df_emp["department"].unique().tolist())
        selected_dept = st.selectbox("Filter by department", dept_options, key="emp_dept")
    with col2:
        name_filter = st.text_input("Search by name", placeholder="e.g. Kim", key="emp_name")

    filtered = df_emp.copy()
    if selected_dept != "All":
        filtered = filtered[filtered["department"] == selected_dept]
    if name_filter:
        filtered = filtered[filtered["name"].str.contains(name_filter, case=False, na=False)]

    st.caption(f"Showing {len(filtered)} of {len(df_emp)} employees")
    st.dataframe(filtered, use_container_width=True, hide_index=True)

    st.divider()
    st.subheader("📊 Headcount by Department")
    dept_counts = df_emp.groupby("department").size().reset_index(name="count")
    st.bar_chart(dept_counts.set_index("department")["count"])

# ===========================================================================
# TAB 3 – Products
# ===========================================================================
with tab_prod:
    st.header("📦 Products")

    df_prod = load_products()

    col1, col2 = st.columns([1, 2])
    with col1:
        cat_options = ["All"] + sorted(df_prod["category"].unique().tolist())
        selected_cat = st.selectbox("Filter by category", cat_options, key="prod_cat")
    with col2:
        prod_name_filter = st.text_input("Search by name", placeholder="e.g. book", key="prod_name")

    filtered_prod = df_prod.copy()
    if selected_cat != "All":
        filtered_prod = filtered_prod[filtered_prod["category"] == selected_cat]
    if prod_name_filter:
        filtered_prod = filtered_prod[
            filtered_prod["name"].str.contains(prod_name_filter, case=False, na=False)
        ]

    st.caption(f"Showing {len(filtered_prod)} of {len(df_prod)} products")
    st.dataframe(filtered_prod, use_container_width=True, hide_index=True)

    st.divider()
    st.subheader("📊 Products by Category")
    cat_counts = df_prod.groupby("category").size().reset_index(name="count")
    st.bar_chart(cat_counts.set_index("category")["count"])

# ===========================================================================
# TAB 4 – Weather
# ===========================================================================
with tab_weather:
    st.header("🌤️ Current Weather")
    st.caption("Powered by [Open-Meteo](https://open-meteo.com/) – free, no API key required.")

    WEATHER_CODES = {
        0: ("Clear sky", "☀️"),
        1: ("Mainly clear", "🌤️"),
        2: ("Partly cloudy", "⛅"),
        3: ("Overcast", "☁️"),
        45: ("Fog", "🌫️"),
        48: ("Icy fog", "🌫️"),
        51: ("Light drizzle", "🌦️"),
        53: ("Drizzle", "🌦️"),
        55: ("Heavy drizzle", "🌧️"),
        61: ("Slight rain", "🌧️"),
        63: ("Moderate rain", "🌧️"),
        65: ("Heavy rain", "🌧️"),
        71: ("Slight snow", "🌨️"),
        73: ("Moderate snow", "❄️"),
        75: ("Heavy snow", "❄️"),
        80: ("Slight showers", "🌦️"),
        81: ("Moderate showers", "🌧️"),
        82: ("Heavy showers", "⛈️"),
        95: ("Thunderstorm", "⛈️"),
    }

    city_input = st.text_input("Enter a city name", placeholder="e.g. Tokyo, London, New York")
    if st.button("Get Weather", type="primary") and city_input:
        with st.spinner(f"Fetching weather for {city_input}…"):
            data = tool_get_weather(city_input)

        if "error" in data:
            st.error(data["error"])
        else:
            code = data.get("weather_code", -1)
            description, emoji = WEATHER_CODES.get(code, ("Unknown", "🌡️"))

            st.subheader(f"{emoji} {data['city']}")
            c1, c2, c3 = st.columns(3)
            c1.metric("🌡️ Temperature", f"{data['temperature_celsius']} °C")
            c2.metric("💧 Humidity", f"{data['humidity_percent']} %")
            c3.metric("💨 Wind Speed", f"{data['wind_speed_kmh']} km/h")
            st.caption(f"Condition: {description}  •  Lat {data['latitude']}, Lon {data['longitude']}")
