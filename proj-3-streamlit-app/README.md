# proj-3 – AI Data Explorer (Streamlit)

A multi-tab Streamlit web app that lets you explore employee & product data and get live weather – all powered by an Anthropic Claude AI agent.

**Deployed for free** on [Streamlit Community Cloud](https://share.streamlit.io).

---

## What the app does

| Tab | Description |
|-----|-------------|
| 🤖 **AI Chat** | Chat with a Claude agent that auto-selects the right tool (employees, products, weather) |
| 👥 **Employees** | Browse & filter `data/employees.csv` with an interactive table and department chart |
| 📦 **Products** | Browse & filter `data/products.csv` with an interactive table and category chart |
| 🌤️ **Weather** | Fetch current weather for any city via [Open-Meteo](https://open-meteo.com/) (free, no key) |

---

## Project structure

```
proj-3-streamlit-app/
├── streamlit_app.py          ← main app (entry point for Streamlit)
├── requirements.txt          ← dependencies
├── data/
│   ├── employees.csv         ← 15 sample employee records
│   └── products.csv          ← 15 sample product records
├── .streamlit/
│   └── config.toml           ← theme & server settings
└── README.md
```

---

## Run locally

```bash
cd proj-3-streamlit-app
pip install -r requirements.txt
streamlit run streamlit_app.py
```

Open `http://localhost:8501` in your browser.

### API key for local dev

Create a `.streamlit/secrets.toml` file (**never commit this file**):

```toml
LLM_API_KEY = "sk-ant-..."
```

Or paste the key into the sidebar's API key field at runtime.

---

## Deploy for free on Streamlit Community Cloud

Streamlit Community Cloud is the official free hosting platform for Streamlit apps. Follow these steps:

### Step 1 – Push your code to a public GitHub repo

Your app must be in a **public** GitHub repository (this repo already qualifies).

### Step 2 – Create a free account

Go to [share.streamlit.io](https://share.streamlit.io) and sign in with your GitHub account.

### Step 3 – Create a new app

1. Click **"New app"** (or **"Deploy an app"**).
2. Fill in:
   - **Repository**: `mahibarauniya/AI-Lab`
   - **Branch**: `main` (or your branch)
   - **Main file path**: `proj-3-streamlit-app/streamlit_app.py`
3. Click **"Deploy!"**

Streamlit Cloud will install `requirements.txt` and start the app automatically.

### Step 4 – Add your API key as a secret

1. In your deployed app's dashboard, click **"⋮ → Settings → Secrets"**.
2. Add:
   ```toml
   LLM_API_KEY = "sk-ant-..."
   ```
3. Save – the app restarts and picks up the key automatically.

Your app will be live at a URL like:
```
https://<your-github-username>-ai-lab-proj-3-streamlit-app-<hash>.streamlit.app
```

---

## Alternative free deployment options

| Platform | Free tier | Notes |
|----------|-----------|-------|
| **Streamlit Community Cloud** ⭐ | ✅ Unlimited public apps | Best for Streamlit, one-click GitHub deploy |
| **Hugging Face Spaces** | ✅ Free CPU instances | Supports Streamlit natively |
| **Render** | ✅ Free web service (spins down after inactivity) | Needs a `Dockerfile` or `render.yaml` |
| **Railway** | ✅ Small monthly credit | Supports Python apps |

---

## Example chat prompts

```
List all employees in the Engineering department
Show me Electronics products
What is the weather in Tokyo?
How many products does BookWorld supply?
Find employees whose name contains Kim
What is the salary range for Finance employees?
Get weather for Paris and compare it to London
```

---

## Notes

- The **AI Chat** tab requires an Anthropic API key. The other tabs (Employees, Products, Weather) work without one.
- The weather tab always works because Open-Meteo is a free, no-key public API.
- CSV data is loaded once per session using `@st.cache_data` for performance.
