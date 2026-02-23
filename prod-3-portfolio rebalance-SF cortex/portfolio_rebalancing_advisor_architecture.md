# 🏗️ Architecture Guide: Portfolio Rebalancing Advisory Tool

## Overview

This application sits **on top of your existing Portfolio Analysis Engine (PAE)** and uses **Snowflake Cortex AI** to provide intelligent rebalancing suggestions for Financial Advisors (FAs) and clients across various "what-if" scenarios.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                          │
│              Streamlit in Snowflake (SiS) Dashboard                │
│  ┌───────────┐  ┌───────────────┐  ┌─────────────────────────┐    │
│  │ Portfolio  │  │  What-If      │  │  Rebalancing            │    │
│  │ Overview   │  │  Scenario     │  │  Recommendations        │    │
│  │ & Scores   │  │  Simulator    │  │  & Trade Suggestions    │    │
│  └───────────┘  └───────────────┘  └─────────────────────────┘    │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────┐
│                     INTELLIGENCE LAYER                              │
│                    (Snowflake Cortex AI)                            │
│                                                                     │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │ Cortex LLM       │  │ Cortex ML        │  │ Cortex Search    │  │
│  │ (Complete/LLama) │  │ (Forecasting +   │  │ (RAG over        │  │
│  │                  │  │  Anomaly Det.)   │  │  Market Research)│  │
│  │ • NL Scenario    │  │ • Risk Scoring   │  │ • Fed Policy     │  │
│  │   Interpretation │  │ • Return Forecast│  │   Documents      │  │
│  │ • Recommendation │  │ • Concentration  │  │ • Disaster       │  │
│  │   Narrative      │  │   Detection      │  │   Impact Data    │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────┐
│                   ORCHESTRATION LAYER                               │
│               (Snowflake Stored Procedures + UDFs)                  │
│                                                                     │
│  ┌──────────────┐ ┌───────────────┐ ┌────────────────────────────┐ │
│  │ Scenario     │ │ Rebalance     │ │ Constraint Solver          │ │
│  │ Engine       │ │ Optimizer     │ │ (Tax-loss, Min Trade Size, │ │
│  │ (What-If     │ │ (Target       │ │  Sector Caps, Client Pref) │ │
│  │  Simulation) │ │  Allocation)  │ │                            │ │
│  └──────────────┘ └───────────────┘ └────────────────────────────┘ │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────────────────┐
│                      DATA LAYER (Snowflake)                        │
│                                                                     │
│  ┌─────────────────────────────────────────────────┐               │
│  │  Portfolio Analysis Engine (PAE) — EXISTING     │               │
│  │  (Read-Only Consumption via Views/Shares)       │               │
│  │  • Holdings  • Performance  • Risk Metrics      │               │
│  └─────────────────────────────────────────────────┘               │
│                                                                     │
│  ┌──────────────┐ ┌───────────────┐ ┌────────────────────────────┐ │
│  │ Market &     │ │ Scenario      │ │ Rebalancing                │ │
│  │ Reference    │ │ Library       │ │ History                    │ │
│  │ Data         │ │               │ │                            │ │
│  │ • Sector Map │ │ • Pre-built   │ │ • Past Suggestions         │ │
│  │ • Benchmarks │ │   Templates   │ │ • Accepted/Rejected        │ │
│  │ • Macro Ind. │ │ • Custom      │ │ • Outcome Tracking         │ │
│  │ • Hist. Crises│ │  Scenarios   │ │                            │ │
│  └──────────────┘ └───────────────┘ └────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Detailed Layer Breakdown

### 1. 📊 Data Layer — Snowflake Tables & Views

This is how you **articulate the existing PAE** as a read-only data source and add your own tables around it.

```sql
-- ============================================================
-- A) CONSUME FROM EXISTING PORTFOLIO ANALYSIS ENGINE (PAE)
--    These are VIEWS on top of PAE tables (read-only bridge)
-- ============================================================

CREATE OR REPLACE VIEW rebal_app.pae_bridge.v_client_holdings AS
SELECT
    client_id,
    account_id,
    ticker,
    asset_class,
    sector,
    quantity,
    market_value,
    cost_basis,
    weight_pct,           -- % of total portfolio
    unrealized_gain_loss,
    holding_date
FROM portfolio_analysis_engine.public.holdings;

CREATE OR REPLACE VIEW rebal_app.pae_bridge.v_portfolio_performance AS
SELECT
    client_id,
    account_id,
    as_of_date,
    total_return_ytd,
    total_return_1y,
    annualized_return_3y,
    sharpe_ratio,
    sortino_ratio,
    max_drawdown,
    volatility_annualized,
    benchmark_id
FROM portfolio_analysis_engine.public.performance_summary;

CREATE OR REPLACE VIEW rebal_app.pae_bridge.v_risk_metrics AS
SELECT
    client_id,
    account_id,
    risk_score,
    var_95,               -- Value at Risk 95%
    cvar_95,
    beta,
    tracking_error,
    sector_concentration_hhi,  -- Herfindahl index
    top_10_holding_pct
FROM portfolio_analysis_engine.public.risk_metrics;


-- ============================================================
-- B) NEW TABLES FOR THE REBALANCING APP
-- ============================================================

-- Sector & Asset reference data
CREATE OR REPLACE TABLE rebal_app.reference.sector_master (
    sector_code       VARCHAR(20) PRIMARY KEY,
    sector_name       VARCHAR(100),
    asset_class       VARCHAR(50),
    benchmark_weight  FLOAT,        -- weight in S&P 500 or chosen benchmark
    avg_beta          FLOAT,
    disaster_sensitivity  VARCHAR(20)  -- HIGH / MEDIUM / LOW
);

-- Macro indicators (Fed rate, VIX, GDP, etc.)
CREATE OR REPLACE TABLE rebal_app.reference.macro_indicators (
    indicator_date  DATE,
    fed_funds_rate  FLOAT,
    us_10y_yield    FLOAT,
    vix             FLOAT,
    gdp_growth_qoq  FLOAT,
    cpi_yoy         FLOAT,
    unemployment_rate FLOAT
);

-- Pre-built scenario library
CREATE OR REPLACE TABLE rebal_app.scenarios.scenario_library (
    scenario_id       VARCHAR(50) PRIMARY KEY,
    scenario_name     VARCHAR(200),
    scenario_type     VARCHAR(50),  -- RATE_CHANGE | NATURAL_DISASTER | CONCENTRATION | CUSTOM
    description       TEXT,
    sector_impact_json VARIANT,     -- {"Technology": -0.15, "Utilities": +0.05, ...}
    macro_shift_json   VARIANT,     -- {"fed_funds_rate": +0.50, "vix": +12}
    is_template        BOOLEAN DEFAULT TRUE,
    created_by         VARCHAR(100),
    created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Rebalancing suggestions & audit trail
CREATE OR REPLACE TABLE rebal_app.results.rebalancing_suggestions (
    suggestion_id     VARCHAR(50) DEFAULT UUID_STRING(),
    client_id         VARCHAR(50),
    scenario_id       VARCHAR(50),
    run_timestamp     TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    current_allocation VARIANT,   -- JSON snapshot
    proposed_allocation VARIANT,  -- JSON snapshot
    trades_json        VARIANT,   -- suggested trades
    projected_return   FLOAT,
    projected_risk     FLOAT,
    concentration_score_before FLOAT,
    concentration_score_after  FLOAT,
    rationale_text     TEXT,       -- LLM-generated narrative
    fa_action          VARCHAR(20), -- PENDING | ACCEPTED | REJECTED | MODIFIED
    fa_notes           TEXT
);

-- Historical crisis impact data (for RAG)
CREATE OR REPLACE TABLE rebal_app.reference.crisis_impact_history (
    event_name     VARCHAR(200),
    event_type     VARCHAR(50),
    event_date     DATE,
    recovery_days  INT,
    sector_impact_json VARIANT,
    description    TEXT
);

-- Seed example scenarios
INSERT INTO rebal_app.scenarios.scenario_library
(scenario_id, scenario_name, scenario_type, description, sector_impact_json, macro_shift_json)
VALUES
('FED_RATE_CUT_50BPS', 'Fed Rate Cut 50bps', 'RATE_CHANGE',
 'Federal Reserve cuts interest rates by 50 basis points',
 PARSE_JSON('{"Technology":0.08,"Real Estate":0.10,"Utilities":0.06,"Financials":-0.04,"Consumer Discretionary":0.05}'),
 PARSE_JSON('{"fed_funds_rate":-0.50,"us_10y_yield":-0.30}')),

('EARTHQUAKE_WEST_COAST', 'Major West Coast Earthquake', 'NATURAL_DISASTER',
 'Magnitude 7+ earthquake hitting California / Pacific Northwest',
 PARSE_JSON('{"Technology":-0.12,"Real Estate":-0.15,"Insurance":-0.20,"Construction":0.10,"Utilities":-0.08}'),
 PARSE_JSON('{"vix":15}')),

('TECH_CONCENTRATION_ALERT', 'High Tech Concentration', 'CONCENTRATION',
 'Portfolio has >40% in Technology sector — needs diversification',
 PARSE_JSON('{"Technology":-0.10}'),
 PARSE_JSON('{}'));
```

---

### 2. 🧠 Intelligence Layer — Snowflake Cortex AI

```sql
-- ============================================================
-- A) CONCENTRATION DETECTION UDF
--    Flags sectors exceeding safe thresholds
-- ============================================================

CREATE OR REPLACE FUNCTION rebal_app.analytics.detect_concentration(
    p_client_id VARCHAR
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
    SELECT OBJECT_AGG(sector, concentration_detail) AS result
    FROM (
        SELECT
            h.sector,
            OBJECT_CONSTRUCT(
                'weight_pct', ROUND(SUM(h.market_value) /
                    NULLIF(SUM(SUM(h.market_value)) OVER (), 0) * 100, 2),
                'benchmark_weight', s.benchmark_weight * 100,
                'overweight_pct', ROUND(
                    (SUM(h.market_value) /
                     NULLIF(SUM(SUM(h.market_value)) OVER (), 0) * 100)
                    - (s.benchmark_weight * 100), 2),
                'risk_flag', CASE
                    WHEN SUM(h.market_value) /
                         NULLIF(SUM(SUM(h.market_value)) OVER (), 0) > 0.35
                    THEN 'CRITICAL'
                    WHEN SUM(h.market_value) /
                         NULLIF(SUM(SUM(h.market_value)) OVER (), 0) > 0.25
                    THEN 'WARNING'
                    ELSE 'OK'
                END
            ) AS concentration_detail
        FROM rebal_app.pae_bridge.v_client_holdings h
        JOIN rebal_app.reference.sector_master s
            ON h.sector = s.sector_code
        WHERE h.client_id = p_client_id
        GROUP BY h.sector, s.benchmark_weight
    )
$$;


-- ============================================================
-- B) SCENARIO STRESS TEST — Apply sector shocks to portfolio
-- ============================================================

CREATE OR REPLACE FUNCTION rebal_app.analytics.apply_scenario_stress(
    p_client_id VARCHAR,
    p_scenario_id VARCHAR
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
    WITH scenario AS (
        SELECT sector_impact_json
        FROM rebal_app.scenarios.scenario_library
        WHERE scenario_id = p_scenario_id
    ),
    holdings AS (
        SELECT
            h.sector,
            SUM(h.market_value) AS current_mv,
            SUM(h.market_value) / NULLIF(SUM(SUM(h.market_value)) OVER (), 0) AS weight
        FROM rebal_app.pae_bridge.v_client_holdings h
        WHERE h.client_id = p_client_id
        GROUP BY h.sector
    )
    SELECT OBJECT_CONSTRUCT(
        'client_id', p_client_id,
        'scenario_id', p_scenario_id,
        'total_current_mv', SUM(h.current_mv),
        'total_stressed_mv', SUM(
            h.current_mv * (1 + COALESCE(s.sector_impact_json:Technology::FLOAT, 0))
        ),
        'sector_detail', ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'sector', h.sector,
                'current_mv', h.current_mv,
                'impact_pct', COALESCE(
                    GET(s.sector_impact_json, h.sector)::FLOAT, 0
                ),
                'stressed_mv', h.current_mv * (
                    1 + COALESCE(GET(s.sector_impact_json, h.sector)::FLOAT, 0)
                )
            )
        )
    )
    FROM holdings h
    CROSS JOIN scenario s
$$;


-- ============================================================
-- C) CORTEX LLM — Generate rebalancing recommendations
--    Uses SNOWFLAKE.CORTEX.COMPLETE()
-- ============================================================

CREATE OR REPLACE PROCEDURE rebal_app.analytics.generate_rebalancing_advice(
    p_client_id VARCHAR,
    p_scenario_id VARCHAR
)
RETURNS TEXT
LANGUAGE SQL
AS
$$
DECLARE
    v_concentration VARIANT;
    v_stress_result VARIANT;
    v_performance   VARIANT;
    v_scenario_desc TEXT;
    v_prompt        TEXT;
    v_recommendation TEXT;
BEGIN
    -- Step 1: Gather concentration data
    v_concentration := (
        SELECT rebal_app.analytics.detect_concentration(:p_client_id)
    );

    -- Step 2: Run stress test
    v_stress_result := (
        SELECT rebal_app.analytics.apply_scenario_stress(:p_client_id, :p_scenario_id)
    );

    -- Step 3: Get current performance
    v_performance := (
        SELECT OBJECT_CONSTRUCT(*)
        FROM rebal_app.pae_bridge.v_portfolio_performance
        WHERE client_id = :p_client_id
        ORDER BY as_of_date DESC
        LIMIT 1
    );

    -- Step 4: Get scenario description
    v_scenario_desc := (
        SELECT description
        FROM rebal_app.scenarios.scenario_library
        WHERE scenario_id = :p_scenario_id
    );

    -- Step 5: Build LLM prompt
    v_prompt := '
You are an expert portfolio advisor. Analyze the following portfolio data and provide
specific rebalancing recommendations.

## Scenario Being Evaluated
' || :v_scenario_desc || '

## Current Portfolio Concentration
' || :v_concentration::TEXT || '

## Stress Test Results Under This Scenario
' || :v_stress_result::TEXT || '

## Current Performance Metrics
' || :v_performance::TEXT || '

## Instructions
1. Identify the TOP 3 risks in this portfolio under this scenario.
2. Propose specific SELL trades (reduce overweight sectors) with target weights.
3. Propose specific BUY trades (increase underweight sectors) to absorb the proceeds.
4. Ensure the total portfolio value remains the same (dollar-neutral rebalancing).
5. Estimate the projected improvement in risk-adjusted return (Sharpe ratio).
6. Keep the language professional but accessible for a client conversation.
7. Format output as:
   - RISK SUMMARY
   - RECOMMENDED TRADES (table: Ticker/Sector | Action | Current Weight | Target Weight | Rationale)
   - PROJECTED IMPACT (before vs after metrics)
   - TALKING POINTS FOR CLIENT
';

    -- Step 6: Call Cortex LLM
    v_recommendation := (
        SELECT SNOWFLAKE.CORTEX.COMPLETE(
            'llama3.1-70b',
            v_prompt
        )
    );

    -- Step 7: Store the suggestion
    INSERT INTO rebal_app.results.rebalancing_suggestions
    (client_id, scenario_id, current_allocation, proposed_allocation,
     rationale_text, concentration_score_before)
    VALUES (
        :p_client_id, :p_scenario_id,
        :v_concentration, :v_stress_result,
        :v_recommendation,
        (SELECT r.sector_concentration_hhi
         FROM rebal_app.pae_bridge.v_risk_metrics r
         WHERE r.client_id = :p_client_id LIMIT 1)
    );

    RETURN v_recommendation;
END;
$$;


-- ============================================================
-- D) CORTEX LLM — Free-form "What-If" via Natural Language
--    FA types: "What if there's a 25% crash in semiconductor stocks?"
-- ============================================================

CREATE OR REPLACE PROCEDURE rebal_app.analytics.freeform_what_if(
    p_client_id VARCHAR,
    p_user_question TEXT
)
RETURNS TEXT
LANGUAGE SQL
AS
$$
DECLARE
    v_holdings TEXT;
    v_prompt   TEXT;
    v_answer   TEXT;
BEGIN
    -- Gather current holdings summary
    v_holdings := (
        SELECT ARRAY_AGG(
            OBJECT_CONSTRUCT(
                'sector', sector,
                'weight_pct', ROUND(SUM(market_value) /
                    NULLIF(SUM(SUM(market_value)) OVER (), 0) * 100, 2),
                'market_value', SUM(market_value)
            )
        )::TEXT
        FROM rebal_app.pae_bridge.v_client_holdings
        WHERE client_id = :p_client_id
        GROUP BY sector
    );

    v_prompt := '
You are a portfolio risk advisor. A financial advisor asks:

"' || :p_user_question || '"

Here is the client portfolio breakdown by sector:
' || :v_holdings || '

Based on this question:
1. Interpret what market event or scenario the FA is worried about.
2. Estimate the impact on each sector (use your financial knowledge).
3. Calculate approximate portfolio impact (dollar loss & percentage).
4. Suggest specific rebalancing moves to mitigate the risk.
5. Ensure suggestions maintain similar expected return profile.
6. Be specific with numbers and percentages.
';

    v_answer := (
        SELECT SNOWFLAKE.CORTEX.COMPLETE('llama3.1-70b', v_prompt)
    );

    RETURN v_answer;
END;
$$;
```

---

### 3. 🖥️ Presentation Layer — Streamlit in Snowflake

```python
import streamlit as st
from snowflake.snowpark.context import get_active_session

session = get_active_session()

# ── App Config ──────────────────────────────────────────────
st.set_page_config(page_title="Portfolio Rebalancing Advisor", layout="wide")
st.title("📊 Portfolio Rebalancing Advisor")
st.caption("Powered by Portfolio Analysis Engine + Snowflake Cortex AI")

# ── Sidebar: Client Selection ──────────────────────────────
with st.sidebar:
    st.header("🔍 Client Selection")
    clients = session.sql(
        "SELECT DISTINCT client_id FROM rebal_app.pae_bridge.v_client_holdings ORDER BY 1"
    ).to_pandas()
    selected_client = st.selectbox("Select Client", clients["CLIENT_ID"].tolist())

    st.divider()
    st.header("⚙️ Analysis Mode")
    mode = st.radio(
        "Choose mode:",
        ["📋 Portfolio Overview", "🧪 Scenario Stress Test",
         "💬 Free-form What-If", "🔄 Rebalancing History"]
    )

# ── Tab 1: Portfolio Overview ──────────────────────────────
if mode == "📋 Portfolio Overview":
    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Sector Allocation")
        holdings = session.sql(f"""
            SELECT sector,
                   ROUND(SUM(market_value), 2) as market_value,
                   ROUND(SUM(market_value) / NULLIF(SUM(SUM(market_value)) OVER (), 0) * 100, 2) as weight_pct
            FROM rebal_app.pae_bridge.v_client_holdings
            WHERE client_id = '{selected_client}'
            GROUP BY sector
            ORDER BY market_value DESC
        """).to_pandas()
        st.dataframe(holdings, use_container_width=True)
        st.bar_chart(holdings.set_index("SECTOR")["WEIGHT_PCT"])

    with col2:
        st.subheader("Concentration Analysis")
        concentration = session.sql(f"""
            SELECT rebal_app.analytics.detect_concentration('{selected_client}') as result
        """).to_pandas()
        import json
        conc_data = json.loads(concentration["RESULT"].iloc[0])
        for sector, detail in conc_data.items():
            flag = detail.get("risk_flag", "OK")
            icon = "🔴" if flag == "CRITICAL" else "🟡" if flag == "WARNING" else "🟢"
            st.metric(
                label=f"{icon} {sector}",
                value=f"{detail['weight_pct']}%",
                delta=f"{detail['overweight_pct']}% vs benchmark"
            )

    st.divider()
    st.subheader("Performance & Risk Snapshot")
    perf = session.sql(f"""
        SELECT * FROM rebal_app.pae_bridge.v_portfolio_performance
        WHERE client_id = '{selected_client}'
        ORDER BY as_of_date DESC LIMIT 1
    """).to_pandas()
    risk = session.sql(f"""
        SELECT * FROM rebal_app.pae_bridge.v_risk_metrics
        WHERE client_id = '{selected_client}' LIMIT 1
    """).to_pandas()

    p1, p2, p3, p4 = st.columns(4)
    if not perf.empty:
        p1.metric("YTD Return", f"{perf['TOTAL_RETURN_YTD'].iloc[0]:.2%}")
        p2.metric("Sharpe Ratio", f"{perf['SHARPE_RATIO'].iloc[0]:.2f}")
    if not risk.empty:
        p3.metric("VaR (95%)", f"{risk['VAR_95'].iloc[0]:.2%}")
        p4.metric("Top 10 Holding %", f"{risk['TOP_10_HOLDING_PCT'].iloc[0]:.1f}%")


# ── Tab 2: Scenario Stress Test ────────────────────────────
elif mode == "🧪 Scenario Stress Test":
    st.subheader("Run a Pre-built Scenario")

    scenarios = session.sql("""
        SELECT scenario_id, scenario_name, scenario_type, description
        FROM rebal_app.scenarios.scenario_library
        WHERE is_template = TRUE
        ORDER BY scenario_name
    """).to_pandas()

    selected_scenario = st.selectbox(
        "Select Scenario",
        scenarios["SCENARIO_ID"].tolist(),
        format_func=lambda x: scenarios[
            scenarios["SCENARIO_ID"] == x
        ]["SCENARIO_NAME"].iloc[0]
    )

    desc = scenarios[scenarios["SCENARIO_ID"] == selected_scenario]["DESCRIPTION"].iloc[0]
    st.info(f"📌 **Scenario:** {desc}")

    if st.button("🚀 Run Stress Test & Get Recommendations", type="primary"):
        with st.spinner("Running scenario analysis with Cortex AI..."):
            result = session.sql(f"""
                CALL rebal_app.analytics.generate_rebalancing_advice(
                    '{selected_client}', '{selected_scenario}'
                )
            """).to_pandas()

            recommendation = result.iloc[0, 0]
            st.subheader("🤖 AI Rebalancing Recommendation")
            st.markdown(recommendation)

            st.success("✅ Recommendation saved to history.")


# ── Tab 3: Free-form What-If ───────────────────────────────
elif mode == "💬 Free-form What-If":
    st.subheader("Ask Any What-If Question")
    st.caption("Examples: 'What if semiconductors crash 30%?', "
               "'What happens if Fed raises rates by 75bps?', "
               "'Hurricane hits Florida — impact on my portfolio?'")

    user_question = st.text_area(
        "Your scenario question:",
        placeholder="What if there's a major earthquake in California and my portfolio is heavy in tech?",
        height=100
    )

    if st.button("🧠 Analyze with Cortex AI", type="primary") and user_question:
        with st.spinner("Cortex AI is analyzing your scenario..."):
            result = session.sql(f"""
                CALL rebal_app.analytics.freeform_what_if(
                    '{selected_client}',
                    $${user_question}$$
                )
            """).to_pandas()
            st.markdown(result.iloc[0, 0])


# ── Tab 4: Rebalancing History ─────────────────────────────
elif mode == "🔄 Rebalancing History":
    st.subheader("Past Rebalancing Suggestions")
    history = session.sql(f"""
        SELECT
            suggestion_id, scenario_id, run_timestamp,
            concentration_score_before, fa_action,
            LEFT(rationale_text, 200) as summary
        FROM rebal_app.results.rebalancing_suggestions
        WHERE client_id = '{selected_client}'
        ORDER BY run_timestamp DESC
        LIMIT 20
    """).to_pandas()

    if not history.empty:
        st.dataframe(history, use_container_width=True)
        selected_suggestion = st.selectbox(
            "View full recommendation:",
            history["SUGGESTION_ID"].tolist()
        )
        if selected_suggestion:
            full = session.sql(f"""
                SELECT rationale_text
                FROM rebal_app.results.rebalancing_suggestions
                WHERE suggestion_id = '{selected_suggestion}'
            """).to_pandas()
            st.markdown(full.iloc[0, 0])
    else:
        st.info("No rebalancing history found for this client.")
```

---

## Data Flow Diagram

```
┌──────────────┐     READ ONLY      ┌────────────────────────────────┐
│  Portfolio   │ ──────────────────► │  PAE Bridge Views              │
│  Analysis    │   (Views/Secure     │  • v_client_holdings           │
│  Engine      │    Data Sharing)    │  • v_portfolio_performance     │
│  (EXISTING)  │                     │  • v_risk_metrics              │
└──────────────┘                     └───────────────┬────────────────┘
                                                     │
    ┌────────────────────────────────────────────────┐│
    │           SCENARIO TRIGGER                     ││
    │                                                ││
    │  ┌─────────────┐  ┌────────────┐  ┌─────────┐ ││
    │  │ Pre-built   │  │ Free-form  │  │ Alert   │ ││
    │  │ Scenario    │  │ NL Query   │  │ (Auto)  │ ││
    │  │ (FA picks)  │  │ (FA types) │  │ Trigger │ ││
    │  └──────┬──────┘  └─────┬──────┘  └────┬────┘ ││
    └─────────┼───────────────┼──────────────┼───────┘│
              │               │              │        │
              ▼               ▼              ▼        ▼
    ┌─────────────────────────────────────────────────────┐
    │              ORCHESTRATION                          │
    │                                                     │
    │  1. detect_concentration() ── Flag risky sectors    │
    │  2. apply_scenario_stress() ── Model impact         │
    │  3. Cortex LLM ── Generate recommendations          │
    │  4. Store suggestion ── Audit trail                 │
    └──────────────────────┬──────────────────────────────┘
                           │
                           ▼
    ┌─────────────────────────────────────────────────────┐
    │           OUTPUT TO FA / CLIENT                     │
    │                                                     │
    │  • Risk Summary with severity flags                 │
    │  • Recommended trades (Sell X, Buy Y)               │
    │  • Before/After portfolio metrics                   │
    │  • Client-friendly talking points                   │
    │  • FA Accept / Reject / Modify workflow             │
    └─────────────────────────────────────────────────────┘
```

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| **PAE consumed via Views only** | Zero modification to existing engine; clean separation of concerns |
| **Scenario Library as a table** | FAs can reuse, customize, and share scenarios; new crisis templates added without code changes |
| **Cortex LLM for narratives** | Converts raw numbers into client-ready talking points; handles infinite free-form what-if questions |
| **Cortex ML for forecasting** | Can be extended to use `SNOWFLAKE.ML.FORECAST` for return predictions |
| **Cortex Search for RAG** | Ingest Fed minutes, disaster reports, market research for context-aware answers |
| **Streamlit in Snowflake** | Zero infrastructure; runs inside Snowflake; secure data access; hackathon-fast |
| **VARIANT columns for JSON** | Flexible schema for sector impacts; each scenario can have different sector mappings |

---

## Example What-If Scenarios Covered

| Scenario | How It Works |
|---|---|
| **High tech concentration** | `detect_concentration()` flags >35% tech → LLM suggests rotating into Healthcare, Industrials, Consumer Staples while preserving growth profile |
| **Fed rate cut 50bps** | Pre-built scenario applies sector impact JSON → rate-sensitive sectors (REITs, Utilities) get a boost, Financials dip → suggest overweight rotation |
| **California earthquake** | Scenario stresses Tech, Real Estate, Insurance sectors → suggests hedging with geographic diversification + defensive sectors |
| **Free-form: "Semiconductor tariffs"** | LLM interprets the event, estimates sector-level impact, applies to actual portfolio weights, suggests specific trades |
| **Pandemic-like event** | Crisis history table provides RAG context on COVID impact → LLM uses actual historical recovery data |

---

## Hackathon Execution Plan (Priority Order)

| Step | Task | Time Estimate |
|---|---|---|
| 1 | Set up Snowflake DB, schemas, and PAE bridge views | 1 hour |
| 2 | Create reference tables + seed scenario library | 1 hour |
| 3 | Build `detect_concentration()` and `apply_scenario_stress()` UDFs | 2 hours |
| 4 | Build `generate_rebalancing_advice()` with Cortex LLM | 2 hours |
| 5 | Build `freeform_what_if()` procedure | 1 hour |
| 6 | Build Streamlit app (all 4 tabs) | 3 hours |
| 7 | Demo data + end-to-end testing | 1 hour |
| 8 | Polish UI + prepare demo narrative | 1 hour |
| | **Total** | **~12 hours** |