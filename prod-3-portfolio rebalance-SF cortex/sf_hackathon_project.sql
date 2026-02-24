drop table HACKATHON.HACKATHON_SCHEMA.client_account_master;
drop table HACKATHON.HACKATHON_SCHEMA.client_position_holdings;
drop table HACKATHON.HACKATHON_SCHEMA.CLIENT_PORTFOLIO_PERFORMANCE;
drop table HACKATHON.HACKATHON_SCHEMA.CLIENT_RISK_METRICS;


CREATE TABLE IF NOT EXISTS HACKATHON.HACKATHON_SCHEMA.client_account_master (
    client_id    INT,
    account_id   INT,
    account_name VARCHAR(100),
    account_type VARCHAR(50),       -- 'Brokerage' | 'IRA' | '401k' etc.
    created_date DATE DEFAULT CURRENT_DATE(),
    CONSTRAINT pk_client_account PRIMARY KEY (client_id, account_id)
);


INSERT INTO HACKATHON.HACKATHON_SCHEMA.client_account_master
(client_id, account_id, account_name, account_type, created_date)
VALUES
(1001, 5001, 'Brokerage Account',   'Brokerage', '2025-02-23'),
(1001, 5002, 'Retirement IRA Account',     'IRA', '2025-02-24');



-- ============================================================
-- STEP 2: RECREATE client_position_holdings WITH FK
-- ============================================================

-- Drop existing table (if safe to do so)
-- DROP TABLE IF EXISTS HACKATHON.HACKATHON_SCHEMA.client_position_holdings;


CREATE OR REPLACE TABLE HACKATHON.HACKATHON_SCHEMA.client_position_holdings (
    client_id              INT            NOT NULL,
    account_id             INT            NOT NULL,
    ticker                 VARCHAR(10)    NOT NULL,
    asset_class            VARCHAR(50),
    sector                 VARCHAR(100),
    quantity               DECIMAL(18,4),
    market_value           DECIMAL(18,2),
    cost_basis             DECIMAL(18,2),
    weight_pct             DECIMAL(5,2),
    unrealized_gain_loss   DECIMAL(18,2),
    holding_date           DATE,

    CONSTRAINT pk_position_holdings
        PRIMARY KEY (client_id, account_id, ticker),

    CONSTRAINT fk_holdings_client_account
        FOREIGN KEY (client_id, account_id)
        REFERENCES HACKATHON.HACKATHON_SCHEMA.client_account_master (client_id, account_id)
);






-- ============================================================
-- STEP 3: RECREATE CLIENT_PORTFOLIO_PERFORMANCE WITH FK
-- ============================================================

-- DROP TABLE IF EXISTS HACKATHON.HACKATHON_SCHEMA.CLIENT_PORTFOLIO_PERFORMANCE;

CREATE OR REPLACE TABLE HACKATHON.HACKATHON_SCHEMA.CLIENT_PORTFOLIO_PERFORMANCE (
    client_id              INT            NOT NULL,
    account_id             INT            NOT NULL,
    as_of_date             DATE           NOT NULL,
    total_return_ytd       DECIMAL(8,4),
    total_return_1y        DECIMAL(8,4),
    annualized_return_3y   DECIMAL(8,4),
    sharpe_ratio           DECIMAL(6,3),
    sortino_ratio          DECIMAL(6,3),
    max_drawdown           DECIMAL(8,4),
    volatility_annualized  DECIMAL(8,4),
    benchmark_id           VARCHAR(20),

    CONSTRAINT pk_portfolio_performance
        PRIMARY KEY (client_id, account_id, as_of_date),

    CONSTRAINT fk_performance_client_account
        FOREIGN KEY (client_id, account_id)
        REFERENCES HACKATHON.HACKATHON_SCHEMA.client_account_master (client_id, account_id)
);


-- ============================================================
-- STEP 4: RECREATE CLIENT_RISK_METRICS WITH FK
-- ============================================================

-- DROP TABLE IF EXISTS HACKATHON.HACKATHON_SCHEMA.CLIENT_RISK_METRICS;

CREATE OR REPLACE TABLE HACKATHON.HACKATHON_SCHEMA.CLIENT_RISK_METRICS (
    client_id                INT            NOT NULL,
    account_id               INT            NOT NULL,
    as_of_date               DATE           NOT NULL,
    risk_score               DECIMAL(5,2),
    var_95                   DECIMAL(8,4),
    cvar_95                  DECIMAL(8,4),
    beta                     DECIMAL(6,3),
    tracking_error           DECIMAL(8,4),
    sector_concentration_hhi DECIMAL(8,4),
    top_10_holding_pct       DECIMAL(5,2),

    CONSTRAINT pk_client_risk_metrics
        PRIMARY KEY (client_id, account_id, as_of_date),

    CONSTRAINT fk_risk_client_account
        FOREIGN KEY (client_id, account_id)
        REFERENCES HACKATHON.HACKATHON_SCHEMA.client_account_master (client_id, account_id)
);

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++=


INSERT INTO HACKATHON.HACKATHON_SCHEMA.client_position_holdings
(client_id, account_id, ticker, asset_class, sector, quantity, market_value, cost_basis, weight_pct, unrealized_gain_loss, holding_date)
VALUES
-- Healthcare Sector

(1001, 5001, 'JNJ',   'Equity', 'Healthcare',             200.0000,  32000.00,  28000.00,  15.24,  4000.00, '2026-02-23'),
(1001, 5001, 'PFE',   'Equity', 'Healthcare',             300.0000,   8400.00,  10500.00,   4.00, -2100.00, '2026-02-23'),
-- Financials Sector
(1001, 5001, 'JPM',   'Equity', 'Financials',             120.0000,  24000.00,  18000.00,  11.43,  6000.00, '2026-02-23'),
(1001, 5001, 'GS',    'Equity', 'Financials',              50.0000,  22500.00,  19000.00,  10.71,  3500.00, '2026-02-23'),

-- Energy Sector
(1001, 5001, 'XOM',   'Equity', 'Energy',                 180.0000,  19800.00,  16200.00,   9.43,  3600.00, '2026-02-23'),

-- Consumer Discretionary Sector
(1001, 5001, 'AMZN',  'Equity', 'Consumer Discretionary', 110.0000,  22000.00,  17600.00,  10.48,  4400.00, '2026-02-23'),

-- Consumer Staples Sector
(1001, 5001, 'PG',    'Equity', 'Consumer Staples',       130.0000,  20800.00,  18200.00,   9.90,  2600.00, '2026-02-23'),

-- Communication Services Sector
(1001, 5001, 'GOOGL', 'Equity', 'Communication Services',  90.0000,  15750.00,  12600.00,   7.50,  3150.00, '2026-02-23'),
(1001, 5001, 'META',  'Equity', 'Communication Services',  60.0000,  30000.00,  21000.00,  14.29,  9000.00, '2026-02-23'),

-- Industrials Sector
(1001, 5001, 'CAT',   'Equity', 'Industrials',             70.0000,  24500.00,  21000.00,  11.67,  3500.00, '2026-02-23'),
(1001, 5001, 'BA',    'Equity', 'Industrials',              85.0000,  17000.00,  19550.00,   8.10, -2550.00, '2026-02-23'),

-- Utilities Sector
(1001, 5001, 'NEE',   'Equity', 'Utilities',              160.0000,  12800.00,  11200.00,   6.10,  1600.00, '2026-02-23'),

-- Real Estate Sector
(1001, 5001, 'AMT',   'Equity', 'Real Estate',             95.0000,  19000.00,  17100.00,   9.05,  1900.00, '2026-02-23'),

-- Materials Sector
(1001, 5001, 'LIN',   'Equity', 'Materials',               55.0000,  24750.00,  22000.00,  11.79,  2750.00, '2026-02-23'),

-- Fixed Income
(1001, 5001, 'BND',   'Fixed Income', 'Bond Fund',        500.0000,  37500.00,  38000.00,  17.86,  -500.00, '2026-02-23'),
(1001, 5001, 'TLT',   'Fixed Income', 'Treasury',         250.0000,  22500.00,  23750.00,  10.71, -1250.00, '2026-02-23'),


-- Healthcare Sector
(1001, 5002, 'UNH',   'Equity', 'Healthcare',              40.0000,  22000.00,  18000.00,   9.78,  4000.00, '2026-02-23'),
(1001, 5002, 'ABBV',  'Equity', 'Healthcare',             100.0000,  17500.00,  14000.00,   7.78,  3500.00, '2026-02-23'),
(1001, 5002, 'TMO',   'Equity', 'Healthcare',              30.0000,  16500.00,  15000.00,   7.33,  1500.00, '2026-02-23'),

-- Financials Sector
(1001, 5002, 'V',     'Equity', 'Financials',              80.0000,  24000.00,  19200.00,  10.67,  4800.00, '2026-02-23'),
(1001, 5002, 'BRK.B', 'Equity', 'Financials',              50.0000,  22500.00,  17500.00,  10.00,  5000.00, '2026-02-23'),

-- Energy Sector
(1001, 5002, 'CVX',   'Equity', 'Energy',                 100.0000,  16000.00,  14500.00,   7.11,  1500.00, '2026-02-23'),
(1001, 5002, 'COP',   'Equity', 'Energy',                 130.0000,  14300.00,  13000.00,   6.36,  1300.00, '2026-02-23'),

-- Consumer Discretionary Sector
(1001, 5002, 'TSLA',  'Equity', 'Consumer Discretionary',  60.0000,  15000.00,  18000.00,   6.67, -3000.00, '2026-02-23'),
(1001, 5002, 'HD',    'Equity', 'Consumer Discretionary',  55.0000,  19250.00,  16500.00,   8.56,  2750.00, '2026-02-23'),

-- Consumer Staples Sector
(1001, 5002, 'KO',    'Equity', 'Consumer Staples',       250.0000,  15000.00,  13000.00,   6.67,  2000.00, '2026-02-23'),
(1001, 5002, 'PEP',   'Equity', 'Consumer Staples',       100.0000,  17000.00,  15000.00,   7.56,  2000.00, '2026-02-23'),

-- Communication Services Sector
(1001, 5002, 'DIS',   'Equity', 'Communication Services', 150.0000,  16500.00,  18000.00,   7.33, -1500.00, '2026-02-23'),
(1001, 5002, 'NFLX',  'Equity', 'Communication Services',  25.0000,  17500.00,  12500.00,   7.78,  5000.00, '2026-02-23'),

-- Industrials Sector
(1001, 5002, 'UPS',   'Equity', 'Industrials',            100.0000,  14000.00,  13000.00,   6.22,  1000.00, '2026-02-23'),
(1001, 5002, 'HON',   'Equity', 'Industrials',             75.0000,  15750.00,  14250.00,   7.00,  1500.00, '2026-02-23'),

-- Utilities Sector
(1001, 5002, 'DUK',   'Equity', 'Utilities',              140.0000,  14000.00,  12600.00,   6.22,  1400.00, '2026-02-23'),
(1001, 5002, 'SO',    'Equity', 'Utilities',              170.0000,  12750.00,  11900.00,   5.67,   850.00, '2026-02-23'),

-- Real Estate Sector
(1001, 5002, 'PLD',   'Equity', 'Real Estate',             90.0000,  11250.00,  10800.00,   5.00,   450.00, '2026-02-23'),
(1001, 5002, 'SPG',   'Equity', 'Real Estate',             80.0000,  10400.00,   9600.00,   4.62,   800.00, '2026-02-23'),

-- Materials Sector
(1001, 5002, 'APD',   'Equity', 'Materials',               50.0000,  15000.00,  13500.00,   6.67,  1500.00, '2026-02-23'),
(1001, 5002, 'FCX',   'Equity', 'Materials',              300.0000,  13500.00,  12000.00,   6.00,  1500.00, '2026-02-23'),

-- Fixed Income
(1001, 5002, 'AGG',   'Fixed Income', 'Bond Fund',        400.0000,  40000.00,  41200.00,  17.78, -1200.00, '2026-02-23'),
(1001, 5002, 'LQD',   'Fixed Income', 'Corporate Bond',   200.0000,  22000.00,  23000.00,   9.78, -1000.00, '2026-02-23'),
(1001, 5002, 'HYG',   'Fixed Income', 'High Yield Bond',  350.0000,  27300.00,  28000.00,  12.13,  -700.00, '2026-02-23'),


-- =============================================
-- ACCOUNT 5001 — Growth / Brokerage Account
-- =============================================

-- Technology Sector
(1001, 5001, 'AAPL',  'Equity', 'Technology',        150,  32550.00,  24000.00,  12.50,   8550.00, '2026-02-23'),
(1001, 5001, 'MSFT',  'Equity', 'Technology',        100,  42500.00,  35000.00,  16.33,   7500.00, '2026-02-23'),
(1001, 5001, 'NVDA',  'Equity', 'Technology',         80,  58400.00,  40000.00,  22.43,  18400.00, '2026-02-23'),

-- Healthcare Sector
(1001, 5001, 'JNJ',   'Equity', 'Healthcare',        120,  19200.00,  17400.00,   7.38,   1800.00, '2026-02-23'),
(1001, 5001, 'PFE',   'Equity', 'Healthcare',        200,   5400.00,   7200.00,   2.07,  -1800.00, '2026-02-23'),

-- Financial Sector
(1001, 5001, 'JPM',   'Equity', 'Financials',         90,  18900.00,  15300.00,   7.26,   3600.00, '2026-02-23'),
(1001, 5001, 'GS',    'Equity', 'Financials',         40,  18000.00,  14800.00,   6.91,   3200.00, '2026-02-23'),

-- Energy Sector
(1001, 5001, 'XOM',   'Equity', 'Energy',            110,  12100.00,  10450.00,   4.65,   1650.00, '2026-02-23'),

-- Consumer Discretionary
(1001, 5001, 'AMZN',  'Equity', 'Consumer Discretionary', 60, 12600.00, 10200.00, 4.84,   2400.00, '2026-02-23'),

-- Fixed Income
(1001, 5001, 'BND',   'Fixed Income', 'Bonds',       300,   22500.00, 23100.00,   8.64,   -600.00, '2026-02-23'),


-- =============================================
-- ACCOUNT 5002 — Retirement / IRA Account
-- =============================================

-- Technology Sector
(1001, 5002, 'GOOGL', 'Equity', 'Technology',         50,   9000.00,   7250.00,   3.46,   1750.00, '2026-02-23'),
(1001, 5002, 'CRM',   'Equity', 'Technology',         65,  19500.00,  16250.00,   7.49,   3250.00, '2026-02-23'),

-- Healthcare Sector
(1001, 5002, 'UNH',   'Equity', 'Healthcare',         30,  16800.00,  14100.00,   6.45,   2700.00, '2026-02-23'),
(1001, 5002, 'ABBV',  'Equity', 'Healthcare',         75,  13125.00,  11250.00,   5.04,   1875.00, '2026-02-23'),

-- Industrials Sector
(1001, 5002, 'CAT',   'Equity', 'Industrials',        45,  16200.00,  13050.00,   6.22,   3150.00, '2026-02-23'),
(1001, 5002, 'HON',   'Equity', 'Industrials',        55,  11550.00,  10450.00,   4.44,   1100.00, '2026-02-23'),

-- Real Estate Sector
(1001, 5002, 'O',     'REIT',   'Real Estate',       200,  11200.00,  10600.00,   4.30,    600.00, '2026-02-23'),

-- Fixed Income
(1001, 5002, 'AGG',   'Fixed Income', 'Bonds',       250,  25000.00,  25500.00,   9.60,   -500.00, '2026-02-23'),

-- Utilities Sector
(1001, 5002, 'NEE',   'Equity', 'Utilities',         100,   7800.00,   6900.00,   3.00,    900.00, '2026-02-23');






 ============================================================

INSERT INTO HACKATHON.HACKATHON_SCHEMA.client_portfolio_performance
(client_id, account_id, as_of_date, total_return_ytd, total_return_1y, annualized_return_3y, sharpe_ratio, sortino_ratio, max_drawdown, volatility_annualized, benchmark_id)
VALUES

-- Monthly snapshots for Account 5001 (trailing 12 months + current)

-- 2025 Monthly History
(1001, 5001, '2025-03-31', 0.0215,  0.1180,  0.0945,  1.020, 1.380, -0.1120, 0.1540, 'SPY'),
(1001, 5001, '2025-04-30', 0.0340,  0.1225,  0.0960,  1.050, 1.410, -0.1120, 0.1510, 'SPY'),
(1001, 5001, '2025-05-31', 0.0510,  0.1290,  0.0980,  1.080, 1.440, -0.1050, 0.1480, 'SPY'),
(1001, 5001, '2025-06-30', 0.0625,  0.1340,  0.0995,  1.100, 1.460, -0.1050, 0.1470, 'SPY'),
(1001, 5001, '2025-07-31', 0.0780,  0.1410,  0.1020,  1.130, 1.500, -0.0980, 0.1450, 'SPY'),
(1001, 5001, '2025-08-31', 0.0690,  0.1350,  0.1005,  1.090, 1.450, -0.1030, 0.1490, 'SPY'),
(1001, 5001, '2025-09-30', 0.0580,  0.1280,  0.0975,  1.060, 1.420, -0.1080, 0.1520, 'SPY'),
(1001, 5001, '2025-10-31', 0.0720,  0.1360,  0.1010,  1.100, 1.470, -0.1080, 0.1500, 'SPY'),
(1001, 5001, '2025-11-30', 0.0890,  0.1430,  0.1035,  1.140, 1.520, -0.0950, 0.1460, 'SPY'),
(1001, 5001, '2025-12-31', 0.1050,  0.1520,  0.1060,  1.180, 1.560, -0.0950, 0.1430, 'SPY'),

-- 2026 YTD
(1001, 5001, '2026-01-31', 0.0180,  0.1480,  0.1055,  1.160, 1.540, -0.0970, 0.1440, 'SPY'),
(1001, 5001, '2026-02-23', 0.0325,  0.1510,  0.1065,  1.170, 1.550, -0.0960, 0.1435, 'SPY'),


-- ============================================================
-- ACCOUNT 5002 — Retirement / IRA Account
-- Broader diversification across all sectors
-- Higher fixed income allocation (AGG, LQD, HYG)
-- More defensive / income-oriented profile
-- ============================================================

-- 2025 Monthly History
(1001, 5002, '2025-03-31', 0.0165,  0.0920,  0.0780,  0.880, 1.180, -0.0850, 0.1280, 'VBINX'),
(1001, 5002, '2025-04-30', 0.0250,  0.0960,  0.0795,  0.900, 1.200, -0.0850, 0.1260, 'VBINX'),
(1001, 5002, '2025-05-31', 0.0380,  0.1010,  0.0815,  0.920, 1.230, -0.0810, 0.1240, 'VBINX'),
(1001, 5002, '2025-06-30', 0.0460,  0.1050,  0.0830,  0.940, 1.250, -0.0810, 0.1230, 'VBINX'),
(1001, 5002, '2025-07-31', 0.0570,  0.1100,  0.0850,  0.960, 1.280, -0.0780, 0.1210, 'VBINX'),
(1001, 5002, '2025-08-31', 0.0510,  0.1060,  0.0840,  0.940, 1.250, -0.0800, 0.1230, 'VBINX'),
(1001, 5002, '2025-09-30', 0.0420,  0.1000,  0.0820,  0.910, 1.220, -0.0830, 0.1250, 'VBINX'),
(1001, 5002, '2025-10-31', 0.0530,  0.1060,  0.0840,  0.935, 1.260, -0.0830, 0.1240, 'VBINX'),
(1001, 5002, '2025-11-30', 0.0640,  0.1110,  0.0860,  0.960, 1.290, -0.0770, 0.1220, 'VBINX'),
(1001, 5002, '2025-12-31', 0.0780,  0.1180,  0.0885,  0.990, 1.320, -0.0770, 0.1200, 'VBINX'),

-- 2026 YTD
(1001, 5002, '2026-01-31', 0.0140,  0.1150,  0.0875,  0.975, 1.300, -0.0790, 0.1210, 'VBINX'),
(1001, 5002, '2026-02-23', 0.0255,  0.1170,  0.0880,  0.985, 1.310, -0.0785, 0.1205, 'VBINX');













INSERT INTO client_risk_metrics
(client_id, account_id, as_of_date, risk_score, var_95, cvar_95, beta, tracking_error, sector_concentration_hhi, top_10_holding_pct)
VALUES

-- Monthly snapshots for Account 5001 (trailing 12 months + current)

(1001, 5001, '2025-03-31', 62.50, -0.0310, -0.0465, 1.080, 0.0420, 0.1120, 78.50),
(1001, 5001, '2025-04-30', 61.80, -0.0305, -0.0458, 1.075, 0.0415, 0.1115, 78.20),
(1001, 5001, '2025-05-31', 60.20, -0.0295, -0.0442, 1.065, 0.0400, 0.1105, 77.80),
(1001, 5001, '2025-06-30', 59.50, -0.0290, -0.0435, 1.060, 0.0395, 0.1100, 77.50),
(1001, 5001, '2025-07-31', 58.00, -0.0280, -0.0420, 1.050, 0.0385, 0.1090, 77.00),
(1001, 5001, '2025-08-31', 60.50, -0.0300, -0.0450, 1.070, 0.0410, 0.1100, 77.60),
(1001, 5001, '2025-09-30', 63.00, -0.0315, -0.0472, 1.085, 0.0425, 0.1110, 78.30),
(1001, 5001, '2025-10-31', 61.20, -0.0302, -0.0453, 1.072, 0.0412, 0.1105, 77.90),
(1001, 5001, '2025-11-30', 58.80, -0.0285, -0.0428, 1.055, 0.0390, 0.1095, 77.20),
(1001, 5001, '2025-12-31', 57.00, -0.0275, -0.0412, 1.045, 0.0380, 0.1085, 76.80),
(1001, 5001, '2026-01-31', 58.50, -0.0282, -0.0423, 1.052, 0.0388, 0.1090, 77.10),
(1001, 5001, '2026-02-23', 59.20, -0.0288, -0.0432, 1.058, 0.0395, 0.1094, 77.40),


-- ============================================================
-- ACCOUNT 5002 — Retirement / IRA Account
-- ============================================================
-- Holdings profile (from sf_hackathon_project.sql):
--   27 positions across 10 sectors + Fixed Income
--   Largest holdings: AGG ($40K), HYG ($27.3K), V ($24K)
--   Well diversified across all GICS sectors
--   Fixed Income ~26.8% (AGG + LQD + HYG) — higher bond tilt
--   More defensive / income-oriented
--
-- HHI Calculation (approximate):
--   Sector weights² summed → well-diversified
--   Healthcare ~16.8%, Financials ~13.9%, Energy ~9.1%,
--   Cons Disc ~10.3%, Cons Staples ~9.6%, Comm Svc ~10.2%,
--   Industrials ~8.9%, Utilities ~8.0%, Real Estate ~6.5%,
--   Materials ~8.6%, Fixed Income ~26.8%
--   HHI ≈ 0.0985 (very well-diversified)
-- ============================================================

(1001, 5002, '2025-03-31', 45.80, -0.0215, -0.0322, 0.820, 0.0340, 0.1010, 65.20),
(1001, 5002, '2025-04-30', 45.20, -0.0212, -0.0318, 0.815, 0.0335, 0.1005, 64.90),
(1001, 5002, '2025-05-31', 44.00, -0.0205, -0.0308, 0.805, 0.0325, 0.0995, 64.40),
(1001, 5002, '2025-06-30', 43.50, -0.0202, -0.0303, 0.800, 0.0320, 0.0990, 64.10),
(1001, 5002, '2025-07-31', 42.50, -0.0195, -0.0292, 0.790, 0.0310, 0.0980, 63.60),
(1001, 5002, '2025-08-31', 44.20, -0.0208, -0.0312, 0.810, 0.0330, 0.0995, 64.50),
(1001, 5002, '2025-09-30', 46.00, -0.0218, -0.0327, 0.825, 0.0345, 0.1010, 65.30),
(1001, 5002, '2025-10-31', 44.80, -0.0210, -0.0315, 0.812, 0.0332, 0.1000, 64.70),
(1001, 5002, '2025-11-30', 43.00, -0.0200, -0.0300, 0.795, 0.0315, 0.0985, 63.80),
(1001, 5002, '2025-12-31', 41.50, -0.0192, -0.0288, 0.785, 0.0305, 0.0975, 63.30),
(1001, 5002, '2026-01-31', 42.80, -0.0198, -0.0297, 0.792, 0.0312, 0.0980, 63.70),
(1001, 5002, '2026-02-23', 43.20, -0.0202, -0.0303, 0.798, 0.0318, 0.0985, 64.00);


SELECT * FROM  HACKATHON.HACKATHON_SCHEMA.client_account_master;
SELECT * FROM  HACKATHON.HACKATHON_SCHEMA.client_position_holdings;
SELECT * FROM  HACKATHON.HACKATHON_SCHEMA.CLIENT_PORTFOLIO_PERFORMANCE;
SELECT * FROM  HACKATHON.HACKATHON_SCHEMA.CLIENT_RISK_METRICS;


++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PORTFOLIO ANALYTICS ENGINE- PAE

CREATE TABLE IF NOT EXISTS HACKATHON.HACKATHON_SCHEMA.sector_master (
    sector_code           VARCHAR(20)    NOT NULL,
    sector_name           VARCHAR(100)   NOT NULL,
    asset_class           VARCHAR(50)    NOT NULL,
    benchmark_weight      DECIMAL(6,4),
    avg_beta              DECIMAL(5,3),
    avg_dividend_yield    DECIMAL(5,3),
    disaster_sensitivity  VARCHAR(20),
    CONSTRAINT pk_sector_master PRIMARY KEY (sector_code)
);


INSERT INTO HACKATHON.HACKATHON_SCHEMA.sector_master
(sector_code, sector_name, asset_class, benchmark_weight, avg_beta, avg_dividend_yield, disaster_sensitivity)
VALUES
('Technology',             'Information Technology',    'Equity',       0.2950, 1.220, 0.008, 'MEDIUM'),
('Healthcare',             'Health Care',               'Equity',       0.1280, 0.720, 0.018, 'LOW'),
('Financials',             'Financials',                'Equity',       0.1310, 1.150, 0.021, 'HIGH'),
('Energy',                 'Energy',                    'Equity',       0.0420, 1.050, 0.038, 'HIGH'),
('Consumer Discretionary', 'Consumer Discretionary',    'Equity',       0.1050, 1.180, 0.009, 'MEDIUM'),
('Consumer Staples',       'Consumer Staples',          'Equity',       0.0650, 0.580, 0.028, 'LOW'),
('Communication Services', 'Communication Services',    'Equity',       0.0880, 1.050, 0.011, 'MEDIUM'),
('Industrials',            'Industrials',               'Equity',       0.0850, 1.020, 0.016, 'MEDIUM'),
('Utilities',              'Utilities',                 'Equity',       0.0240, 0.550, 0.034, 'LOW'),
('Real Estate',            'Real Estate',               'Equity',       0.0230, 0.800, 0.032, 'MEDIUM'),
('Materials',              'Materials',                 'Equity',       0.0250, 1.010, 0.020, 'MEDIUM'),
('Bond Fund',              'Diversified Bond Fund',     'Fixed Income', 0.0000, 0.050, 0.040, 'LOW'),
('Treasury',               'US Treasury Bonds',         'Fixed Income', 0.0000, 0.020, 0.038, 'LOW'),
('Corporate Bond',         'Investment Grade Corp Bond','Fixed Income', 0.0000, 0.080, 0.045, 'LOW'),
('High Yield Bond',        'High Yield Corporate Bond', 'Fixed Income', 0.0000, 0.300, 0.062, 'MEDIUM');


CREATE TABLE IF NOT EXISTS HACKATHON.HACKATHON_SCHEMA.benchmark_master (
    benchmark_id        VARCHAR(20)    NOT NULL,
    benchmark_name      VARCHAR(200)   NOT NULL,
    benchmark_type      VARCHAR(50),
    asset_class_focus   VARCHAR(50),
    provider            VARCHAR(100),
    inception_date      DATE,
    currency            VARCHAR(3)     DEFAULT 'USD',
    description         TEXT,

    CONSTRAINT pk_benchmark_master PRIMARY KEY (benchmark_id)
);

INSERT INTO HACKATHON.HACKATHON_SCHEMA.benchmark_master
(benchmark_id, benchmark_name, benchmark_type, asset_class_focus, provider, inception_date, currency, description)
VALUES
('SPY',   'SPDR S&P 500 ETF Trust',                  'Equity Index', 'Equity',       'State Street',  '1993-01-22', 'USD', 'Tracks the S&P 500 index — 500 largest US companies by market cap. Used as benchmark for equity-heavy growth portfolios.'),
('VBINX', 'Vanguard Balanced Index Fund',             'Balanced',     'Multi-Asset',  'Vanguard',      '1992-11-13', 'USD', '60/40 balanced fund tracking US stocks and bonds. Used as benchmark for moderate/conservative blended portfolios.'),
('AGG',   'iShares Core U.S. Aggregate Bond ETF',    'Bond Index',   'Fixed Income', 'BlackRock',     '2003-09-26', 'USD', 'Tracks the Bloomberg US Aggregate Bond Index — investment grade US bonds. Used as benchmark for fixed income portfolios.'),
('QQQ',   'Invesco QQQ Trust',                       'Equity Index', 'Equity',       'Invesco',       '1999-03-10', 'USD', 'Tracks the NASDAQ-100 index — 100 largest non-financial NASDAQ companies. Used for tech-heavy growth portfolio comparison.');


-- ============================================================
-- SECURITY_MASTER — DDL + DML
-- Covers ALL 45 unique tickers from client_position_holdings
-- Accounts: 5001 & 5002
-- ============================================================

CREATE TABLE IF NOT EXISTS HACKATHON.HACKATHON_SCHEMA.security_master (
    ticker              VARCHAR(10)    NOT NULL,
    security_name       VARCHAR(200)   NOT NULL,
    asset_class         VARCHAR(50)    NOT NULL,     -- 'Equity' | 'Fixed Income' | 'REIT' | 'ETF' | 'Mutual Fund'
    sector_code         VARCHAR(20),                 -- FK → sector_master.sector_code
    industry            VARCHAR(100),                -- Sub-sector: 'Semiconductors', 'Pharma', etc.
    exchange            VARCHAR(20),                 -- 'NYSE' | 'NASDAQ' | 'AMEX'
    market_cap_category VARCHAR(20),                 -- 'Mega Cap' | 'Large Cap' | 'Mid Cap' | 'Small Cap'

    CONSTRAINT pk_security_master PRIMARY KEY (ticker)
);


-- ============================================================
-- INSERT ALL 45 SECURITIES
-- ============================================================

INSERT INTO HACKATHON.HACKATHON_SCHEMA.security_master
(ticker, security_name, asset_class, sector_code, industry, exchange, market_cap_category)
VALUES

-- =============================================
-- TECHNOLOGY — 5 tickers
-- =============================================
('AAPL',  'Apple Inc.',                                              'Equity',       'Technology',             'Consumer Electronics',            'NASDAQ', 'Mega Cap'),
('MSFT',  'Microsoft Corporation',                                   'Equity',       'Technology',             'Software - Infrastructure',       'NASDAQ', 'Mega Cap'),
('NVDA',  'NVIDIA Corporation',                                      'Equity',       'Technology',             'Semiconductors',                  'NASDAQ', 'Mega Cap'),
('GOOGL', 'Alphabet Inc. Class A',                                   'Equity',       'Technology',             'Internet Content & Information',  'NASDAQ', 'Mega Cap'),
('CRM',   'Salesforce Inc.',                                         'Equity',       'Technology',             'Software - Application',          'NYSE',   'Large Cap'),

-- =============================================
-- HEALTHCARE — 5 tickers
-- =============================================
('JNJ',   'Johnson & Johnson',                                      'Equity',       'Healthcare',             'Drug Manufacturers - General',    'NYSE',   'Mega Cap'),
('PFE',   'Pfizer Inc.',                                             'Equity',       'Healthcare',             'Drug Manufacturers - General',    'NYSE',   'Large Cap'),
('UNH',   'UnitedHealth Group Inc.',                                 'Equity',       'Healthcare',             'Healthcare Plans',                'NYSE',   'Mega Cap'),
('ABBV',  'AbbVie Inc.',                                             'Equity',       'Healthcare',             'Drug Manufacturers - Specialty',  'NYSE',   'Large Cap'),
('TMO',   'Thermo Fisher Scientific Inc.',                           'Equity',       'Healthcare',             'Diagnostics & Research',          'NYSE',   'Mega Cap'),

-- =============================================
-- FINANCIALS — 4 tickers
-- =============================================
('JPM',   'JPMorgan Chase & Co.',                                    'Equity',       'Financials',             'Banks - Diversified',             'NYSE',   'Mega Cap'),
('GS',    'The Goldman Sachs Group Inc.',                            'Equity',       'Financials',             'Capital Markets',                 'NYSE',   'Large Cap'),
('V',     'Visa Inc. Class A',                                       'Equity',       'Financials',             'Credit Services',                 'NYSE',   'Mega Cap'),
('BRK.B', 'Berkshire Hathaway Inc. Class B',                         'Equity',       'Financials',             'Insurance - Diversified',         'NYSE',   'Mega Cap'),

-- =============================================
-- ENERGY — 3 tickers
-- =============================================
('XOM',   'Exxon Mobil Corporation',                                 'Equity',       'Energy',                 'Oil & Gas Integrated',            'NYSE',   'Mega Cap'),
('CVX',   'Chevron Corporation',                                     'Equity',       'Energy',                 'Oil & Gas Integrated',            'NYSE',   'Mega Cap'),
('COP',   'ConocoPhillips',                                          'Equity',       'Energy',                 'Oil & Gas E&P',                   'NYSE',   'Large Cap'),

-- =============================================
-- CONSUMER DISCRETIONARY — 3 tickers
-- =============================================
('AMZN',  'Amazon.com Inc.',                                         'Equity',       'Consumer Discretionary', 'Internet Retail',                 'NASDAQ', 'Mega Cap'),
('TSLA',  'Tesla Inc.',                                              'Equity',       'Consumer Discretionary', 'Auto Manufacturers',              'NASDAQ', 'Mega Cap'),
('HD',    'The Home Depot Inc.',                                     'Equity',       'Consumer Discretionary', 'Home Improvement Retail',         'NYSE',   'Mega Cap'),

-- =============================================
-- CONSUMER STAPLES — 3 tickers
-- =============================================
('PG',    'The Procter & Gamble Company',                            'Equity',       'Consumer Staples',       'Household & Personal Products',   'NYSE',   'Mega Cap'),
('KO',    'The Coca-Cola Company',                                   'Equity',       'Consumer Staples',       'Beverages - Non-Alcoholic',       'NYSE',   'Mega Cap'),
('PEP',   'PepsiCo Inc.',                                            'Equity',       'Consumer Staples',       'Beverages - Non-Alcoholic',       'NASDAQ', 'Mega Cap'),

-- =============================================
-- COMMUNICATION SERVICES — 3 tickers
-- =============================================
('META',  'Meta Platforms Inc. Class A',                             'Equity',       'Communication Services', 'Internet Content & Information',  'NASDAQ', 'Mega Cap'),
('DIS',   'The Walt Disney Company',                                 'Equity',       'Communication Services', 'Entertainment',                   'NYSE',   'Large Cap'),
('NFLX',  'Netflix Inc.',                                            'Equity',       'Communication Services', 'Entertainment',                   'NASDAQ', 'Mega Cap'),

-- =============================================
-- INDUSTRIALS — 4 tickers
-- =============================================
('CAT',   'Caterpillar Inc.',                                        'Equity',       'Industrials',            'Farm & Heavy Construction',       'NYSE',   'Large Cap'),
('BA',    'The Boeing Company',                                      'Equity',       'Industrials',            'Aerospace & Defense',             'NYSE',   'Large Cap'),
('UPS',   'United Parcel Service Inc. Class B',                      'Equity',       'Industrials',            'Integrated Freight & Logistics',  'NYSE',   'Large Cap'),
('HON',   'Honeywell International Inc.',                            'Equity',       'Industrials',            'Conglomerates',                   'NASDAQ', 'Large Cap'),

-- =============================================
-- UTILITIES — 3 tickers
-- =============================================
('NEE',   'NextEra Energy Inc.',                                     'Equity',       'Utilities',              'Utilities - Regulated Electric',  'NYSE',   'Large Cap'),
('DUK',   'Duke Energy Corporation',                                 'Equity',       'Utilities',              'Utilities - Regulated Electric',  'NYSE',   'Large Cap'),
('SO',    'The Southern Company',                                    'Equity',       'Utilities',              'Utilities - Regulated Electric',  'NYSE',   'Large Cap'),

-- =============================================
-- REAL ESTATE — 4 tickers
-- =============================================
('AMT',   'American Tower Corporation',                              'REIT',         'Real Estate',            'REIT - Specialty',                'NYSE',   'Large Cap'),
('PLD',   'Prologis Inc.',                                           'REIT',         'Real Estate',            'REIT - Industrial',               'NYSE',   'Large Cap'),
('SPG',   'Simon Property Group Inc.',                               'REIT',         'Real Estate',            'REIT - Retail',                   'NYSE',   'Large Cap'),
('O',     'Realty Income Corporation',                               'REIT',         'Real Estate',            'REIT - Retail',                   'NYSE',   'Large Cap'),

-- =============================================
-- MATERIALS — 3 tickers
-- =============================================
('LIN',   'Linde plc',                                               'Equity',       'Materials',              'Specialty Chemicals',             'NYSE',   'Mega Cap'),
('APD',   'Air Products and Chemicals Inc.',                         'Equity',       'Materials',              'Specialty Chemicals',             'NYSE',   'Large Cap'),
('FCX',   'Freeport-McMoRan Inc.',                                   'Equity',       'Materials',              'Copper',                          'NYSE',   'Large Cap'),

-- =============================================
-- FIXED INCOME — 5 tickers
-- =============================================
('BND',   'Vanguard Total Bond Market ETF',                          'Fixed Income', 'Bond Fund',              'Total Bond Market',               'NASDAQ', NULL),
('TLT',   'iShares 20+ Year Treasury Bond ETF',                     'Fixed Income', 'Treasury',               'Long-Term Treasury',              'NASDAQ', NULL),
('AGG',   'iShares Core U.S. Aggregate Bond ETF',                   'Fixed Income', 'Bond Fund',              'Aggregate Bond',                  'NYSE',   NULL),
('LQD',   'iShares iBoxx $ Inv Grade Corporate Bond ETF',           'Fixed Income', 'Corporate Bond',         'Investment Grade Corporate',      'NYSE',   NULL),
('HYG',   'iShares iBoxx $ High Yield Corporate Bond ETF',          'Fixed Income', 'High Yield Bond',        'High Yield Corporate',            'NYSE',   NULL);


INSERT INTO HACKATHON.HACKATHON_SCHEMA.security_master
(ticker, security_name, asset_class, sector_code, industry, exchange, market_cap_category)
VALUES

-- =============================================
-- TECHNOLOGY — 10 additional tickers
-- sector_code = 'Technology', asset_class = 'Equity'
-- =============================================
('INTC',  'Intel Corporation',                                       'Equity', 'Technology', 'Semiconductors',                  'NASDAQ', 'Large Cap'),
('AMD',   'Advanced Micro Devices Inc.',                             'Equity', 'Technology', 'Semiconductors',                  'NASDAQ', 'Large Cap'),
('ADBE',  'Adobe Inc.',                                              'Equity', 'Technology', 'Software - Infrastructure',       'NASDAQ', 'Mega Cap'),
('ORCL',  'Oracle Corporation',                                      'Equity', 'Technology', 'Software - Infrastructure',       'NYSE',   'Mega Cap'),
('CSCO',  'Cisco Systems Inc.',                                      'Equity', 'Technology', 'Communication Equipment',         'NASDAQ', 'Large Cap'),
('AVGO',  'Broadcom Inc.',                                           'Equity', 'Technology', 'Semiconductors',                  'NASDAQ', 'Mega Cap'),
('TXN',   'Texas Instruments Incorporated',                          'Equity', 'Technology', 'Semiconductors',                  'NASDAQ', 'Large Cap'),
('QCOM',  'QUALCOMM Incorporated',                                   'Equity', 'Technology', 'Semiconductors',                  'NASDAQ', 'Large Cap'),
('NOW',   'ServiceNow Inc.',                                         'Equity', 'Technology', 'Software - Application',          'NYSE',   'Large Cap'),
('INTU',  'Intuit Inc.',                                              'Equity', 'Technology', 'Software - Application',          'NASDAQ', 'Large Cap'),

-- =============================================
-- HEALTHCARE — 10 additional tickers
-- sector_code = 'Healthcare', asset_class = 'Equity'
-- =============================================
('LLY',   'Eli Lilly and Company',                                   'Equity', 'Healthcare', 'Drug Manufacturers - General',    'NYSE',   'Mega Cap'),
('MRK',   'Merck & Co. Inc.',                                        'Equity', 'Healthcare', 'Drug Manufacturers - General',    'NYSE',   'Mega Cap'),
('BMY',   'Bristol-Myers Squibb Company',                            'Equity', 'Healthcare', 'Drug Manufacturers - General',    'NYSE',   'Large Cap'),
('AMGN',  'Amgen Inc.',                                              'Equity', 'Healthcare', 'Drug Manufacturers - Specialty',  'NASDAQ', 'Mega Cap'),
('GILD',  'Gilead Sciences Inc.',                                    'Equity', 'Healthcare', 'Drug Manufacturers - Specialty',  'NASDAQ', 'Large Cap'),
('ISRG',  'Intuitive Surgical Inc.',                                 'Equity', 'Healthcare', 'Medical Instruments & Supplies',  'NASDAQ', 'Mega Cap'),
('MDT',   'Medtronic plc',                                           'Equity', 'Healthcare', 'Medical Devices',                 'NYSE',   'Large Cap'),
('SYK',   'Stryker Corporation',                                     'Equity', 'Healthcare', 'Medical Devices',                 'NYSE',   'Large Cap'),
('VRTX',  'Vertex Pharmaceuticals Incorporated',                     'Equity', 'Healthcare', 'Biotechnology',                   'NASDAQ', 'Large Cap'),
('REGN',  'Regeneron Pharmaceuticals Inc.',                          'Equity', 'Healthcare', 'Biotechnology',                   'NASDAQ', 'Large Cap'),

-- =============================================
-- FINANCIALS — 10 additional tickers
-- sector_code = 'Financials', asset_class = 'Equity'
-- =============================================
('BAC',   'Bank of America Corporation',                             'Equity', 'Financials', 'Banks - Diversified',             'NYSE',   'Mega Cap'),
('WFC',   'Wells Fargo & Company',                                   'Equity', 'Financials', 'Banks - Diversified',             'NYSE',   'Large Cap'),
('C',     'Citigroup Inc.',                                          'Equity', 'Financials', 'Banks - Diversified',             'NYSE',   'Large Cap'),
('MS',    'Morgan Stanley',                                          'Equity', 'Financials', 'Capital Markets',                 'NYSE',   'Large Cap'),
('SCHW',  'The Charles Schwab Corporation',                          'Equity', 'Financials', 'Capital Markets',                 'NYSE',   'Large Cap'),
('AXP',   'American Express Company',                                'Equity', 'Financials', 'Credit Services',                 'NYSE',   'Large Cap'),
('MA',    'Mastercard Incorporated Class A',                         'Equity', 'Financials', 'Credit Services',                 'NYSE',   'Mega Cap'),
('BLK',   'BlackRock Inc.',                                          'Equity', 'Financials', 'Asset Management',                'NYSE',   'Large Cap'),
('MMC',   'Marsh & McLennan Companies Inc.',                         'Equity', 'Financials', 'Insurance - Brokers',             'NYSE',   'Large Cap'),
('PGR',   'The Progressive Corporation',                             'Equity', 'Financials', 'Insurance - Property & Casualty', 'NYSE',   'Large Cap'),

-- =============================================
-- ENERGY — 7 additional tickers
-- sector_code = 'Energy', asset_class = 'Equity'
-- =============================================
('SLB',   'Schlumberger Limited',                                    'Equity', 'Energy', 'Oil & Gas Equipment & Services',  'NYSE',   'Large Cap'),
('EOG',   'EOG Resources Inc.',                                      'Equity', 'Energy', 'Oil & Gas E&P',                   'NYSE',   'Large Cap'),
('MPC',   'Marathon Petroleum Corporation',                          'Equity', 'Energy', 'Oil & Gas Refining & Marketing',  'NYSE',   'Large Cap'),
('PSX',   'Phillips 66',                                              'Equity', 'Energy', 'Oil & Gas Refining & Marketing',  'NYSE',   'Large Cap'),
('VLO',   'Valero Energy Corporation',                               'Equity', 'Energy', 'Oil & Gas Refining & Marketing',  'NYSE',   'Large Cap'),
('OXY',   'Occidental Petroleum Corporation',                        'Equity', 'Energy', 'Oil & Gas E&P',                   'NYSE',   'Large Cap'),
('HAL',   'Halliburton Company',                                     'Equity', 'Energy', 'Oil & Gas Equipment & Services',  'NYSE',   'Large Cap'),

-- =============================================
-- CONSUMER DISCRETIONARY — 8 additional tickers
-- sector_code = 'Consumer Discretionary', asset_class = 'Equity'
-- =============================================
('NKE',   'NIKE Inc. Class B',                                       'Equity', 'Consumer Discretionary', 'Footwear & Accessories',          'NYSE',   'Large Cap'),
('SBUX',  'Starbucks Corporation',                                   'Equity', 'Consumer Discretionary', 'Restaurants',                     'NASDAQ', 'Large Cap'),
('MCD',   'McDonald''s Corporation',                                 'Equity', 'Consumer Discretionary', 'Restaurants',                     'NYSE',   'Mega Cap'),
('LOW',   'Lowe''s Companies Inc.',                                  'Equity', 'Consumer Discretionary', 'Home Improvement Retail',         'NYSE',   'Large Cap'),
('TJX',   'The TJX Companies Inc.',                                  'Equity', 'Consumer Discretionary', 'Apparel Retail',                  'NYSE',   'Large Cap'),
('BKNG',  'Booking Holdings Inc.',                                   'Equity', 'Consumer Discretionary', 'Travel Services',                 'NASDAQ', 'Mega Cap'),
('MAR',   'Marriott International Inc. Class A',                     'Equity', 'Consumer Discretionary', 'Lodging',                         'NASDAQ', 'Large Cap'),
('GM',    'General Motors Company',                                  'Equity', 'Consumer Discretionary', 'Auto Manufacturers',              'NYSE',   'Large Cap'),

-- =============================================
-- CONSUMER STAPLES — 7 additional tickers
-- sector_code = 'Consumer Staples', asset_class = 'Equity'
-- =============================================
('COST',  'Costco Wholesale Corporation',                            'Equity', 'Consumer Staples', 'Discount Stores',                 'NASDAQ', 'Mega Cap'),
('WMT',   'Walmart Inc.',                                            'Equity', 'Consumer Staples', 'Discount Stores',                 'NYSE',   'Mega Cap'),
('PM',    'Philip Morris International Inc.',                        'Equity', 'Consumer Staples', 'Tobacco',                         'NYSE',   'Large Cap'),
('MO',    'Altria Group Inc.',                                       'Equity', 'Consumer Staples', 'Tobacco',                         'NYSE',   'Large Cap'),
('CL',    'Colgate-Palmolive Company',                               'Equity', 'Consumer Staples', 'Household & Personal Products',   'NYSE',   'Large Cap'),
('MDLZ',  'Mondelez International Inc. Class A',                     'Equity', 'Consumer Staples', 'Confectioners',                   'NASDAQ', 'Large Cap'),
('GIS',   'General Mills Inc.',                                      'Equity', 'Consumer Staples', 'Packaged Foods',                  'NYSE',   'Large Cap'),

-- =============================================
-- COMMUNICATION SERVICES — 7 additional tickers
-- sector_code = 'Communication Services', asset_class = 'Equity'
-- =============================================
('T',     'AT&T Inc.',                                               'Equity', 'Communication Services', 'Telecom Services',                'NYSE',   'Large Cap'),
('VZ',    'Verizon Communications Inc.',                             'Equity', 'Communication Services', 'Telecom Services',                'NYSE',   'Large Cap'),
('TMUS',  'T-Mobile US Inc.',                                        'Equity', 'Communication Services', 'Telecom Services',                'NASDAQ', 'Large Cap'),
('CMCSA', 'Comcast Corporation Class A',                             'Equity', 'Communication Services', 'Entertainment',                   'NASDAQ', 'Large Cap'),
('CHTR',  'Charter Communications Inc. Class A',                     'Equity', 'Communication Services', 'Entertainment',                   'NASDAQ', 'Large Cap'),
('EA',    'Electronic Arts Inc.',                                    'Equity', 'Communication Services', 'Electronic Gaming & Multimedia',  'NASDAQ', 'Large Cap'),
('WBD',   'Warner Bros. Discovery Inc. Series A',                    'Equity', 'Communication Services', 'Entertainment',                   'NASDAQ', 'Mid Cap'),

-- =============================================
-- INDUSTRIALS — 8 additional tickers
-- sector_code = 'Industrials', asset_class = 'Equity'
-- =============================================
('GE',    'GE Aerospace',                                            'Equity', 'Industrials', 'Aerospace & Defense',             'NYSE',   'Mega Cap'),
('RTX',   'RTX Corporation',                                         'Equity', 'Industrials', 'Aerospace & Defense',             'NYSE',   'Large Cap'),
('LMT',   'Lockheed Martin Corporation',                             'Equity', 'Industrials', 'Aerospace & Defense',             'NYSE',   'Large Cap'),
('DE',    'Deere & Company',                                         'Equity', 'Industrials', 'Farm & Heavy Construction',       'NYSE',   'Large Cap'),
('MMM',   'Minnesota Mining and Manufacturing Company',              'Equity', 'Industrials', 'Conglomerates',                   'NYSE',   'Large Cap'),
('FDX',   'FedEx Corporation',                                       'Equity', 'Industrials', 'Integrated Freight & Logistics',  'NYSE',   'Large Cap'),
('WM',    'Waste Management Inc.',                                   'Equity', 'Industrials', 'Waste Management',                'NYSE',   'Large Cap'),
('ETN',   'Eaton Corporation plc',                                   'Equity', 'Industrials', 'Electrical Equipment & Parts',    'NYSE',   'Large Cap'),

-- =============================================
-- UTILITIES — 7 additional tickers
-- sector_code = 'Utilities', asset_class = 'Equity'
-- =============================================
('AEP',   'American Electric Power Company Inc.',                    'Equity', 'Utilities', 'Utilities - Regulated Electric',  'NASDAQ', 'Large Cap'),
('D',     'Dominion Energy Inc.',                                    'Equity', 'Utilities', 'Utilities - Regulated Electric',  'NYSE',   'Large Cap'),
('EXC',   'Exelon Corporation',                                      'Equity', 'Utilities', 'Utilities - Regulated Electric',  'NASDAQ', 'Large Cap'),
('SRE',   'Sempra',                                                  'Equity', 'Utilities', 'Utilities - Diversified',         'NYSE',   'Large Cap'),
('XEL',   'Xcel Energy Inc.',                                        'Equity', 'Utilities', 'Utilities - Regulated Electric',  'NASDAQ', 'Large Cap'),
('ED',    'Consolidated Edison Inc.',                                'Equity', 'Utilities', 'Utilities - Regulated Electric',  'NYSE',   'Large Cap'),
('WEC',   'WEC Energy Group Inc.',                                   'Equity', 'Utilities', 'Utilities - Regulated Electric',  'NYSE',   'Large Cap'),

-- =============================================
-- REAL ESTATE — 6 additional tickers
-- sector_code = 'Real Estate', asset_class = 'REIT'
-- =============================================
('EQIX',  'Equinix Inc.',                                            'REIT', 'Real Estate', 'REIT - Specialty',                'NASDAQ', 'Large Cap'),
('PSA',   'Public Storage',                                          'REIT', 'Real Estate', 'REIT - Industrial',               'NYSE',   'Large Cap'),
('DLR',   'Digital Realty Trust Inc.',                                'REIT', 'Real Estate', 'REIT - Specialty',                'NYSE',   'Large Cap'),
('WELL',  'Welltower Inc.',                                          'REIT', 'Real Estate', 'REIT - Healthcare Facilities',    'NYSE',   'Large Cap'),
('AVB',   'AvalonBay Communities Inc.',                              'REIT', 'Real Estate', 'REIT - Residential',              'NYSE',   'Large Cap'),
('CCI',   'Crown Castle Inc.',                                       'REIT', 'Real Estate', 'REIT - Specialty',                'NYSE',   'Large Cap'),

-- =============================================
-- MATERIALS — 7 additional tickers
-- sector_code = 'Materials', asset_class = 'Equity'
-- =============================================
('SHW',   'The Sherwin-Williams Company',                            'Equity', 'Materials', 'Specialty Chemicals',             'NYSE',   'Large Cap'),
('ECL',   'Ecolab Inc.',                                              'Equity', 'Materials', 'Specialty Chemicals',             'NYSE',   'Large Cap'),
('NEM',   'Newmont Corporation',                                     'Equity', 'Materials', 'Gold',                            'NYSE',   'Large Cap'),
('DD',    'DuPont de Nemours Inc.',                                  'Equity', 'Materials', 'Specialty Chemicals',             'NYSE',   'Large Cap'),
('NUE',   'Nucor Corporation',                                       'Equity', 'Materials', 'Steel',                           'NYSE',   'Large Cap'),
('DOW',   'Dow Inc.',                                                 'Equity', 'Materials', 'Chemicals',                       'NYSE',   'Large Cap'),
('PPG',   'PPG Industries Inc.',                                     'Equity', 'Materials', 'Specialty Chemicals',             'NYSE',   'Large Cap'),

-- =============================================
-- FIXED INCOME — Bond Fund (sector_code = 'Bond Fund')
-- asset_class = 'Fixed Income'
-- =============================================
('BNDX',  'Vanguard Total International Bond ETF',                  'Fixed Income', 'Bond Fund',       'International Bond',              'NASDAQ', NULL),
('SCHZ',  'Schwab U.S. Aggregate Bond ETF',                         'Fixed Income', 'Bond Fund',       'Aggregate Bond',                  'NYSE',   NULL),
('BSV',   'Vanguard Short-Term Bond ETF',                            'Fixed Income', 'Bond Fund',       'Short-Term Bond',                 'NASDAQ', NULL),

-- =============================================
-- FIXED INCOME — Treasury (sector_code = 'Treasury')
-- asset_class = 'Fixed Income'
-- =============================================
('SHY',   'iShares 1-3 Year Treasury Bond ETF',                     'Fixed Income', 'Treasury',        'Short-Term Treasury',             'NASDAQ', NULL),
('IEF',   'iShares 7-10 Year Treasury Bond ETF',                    'Fixed Income', 'Treasury',        'Intermediate Treasury',           'NASDAQ', NULL),
('GOVT',  'iShares U.S. Treasury Bond ETF',                         'Fixed Income', 'Treasury',        'Broad Treasury',                  'NYSE',   NULL),

-- =============================================
-- FIXED INCOME — Corporate Bond (sector_code = 'Corporate Bond')
-- asset_class = 'Fixed Income'
-- =============================================
('VCIT',  'Vanguard Intermediate-Term Corporate Bond ETF',          'Fixed Income', 'Corporate Bond',  'Intermediate Corporate',          'NASDAQ', NULL),
('VCSH',  'Vanguard Short-Term Corporate Bond ETF',                 'Fixed Income', 'Corporate Bond',  'Short-Term Corporate',            'NASDAQ', NULL),
('IGIB',  'iShares 5-10 Year Inv Grade Corp Bond ETF',             'Fixed Income', 'Corporate Bond',  'Intermediate Corporate',          'NASDAQ', NULL),

-- =============================================
-- FIXED INCOME — High Yield Bond (sector_code = 'High Yield Bond')
-- asset_class = 'Fixed Income'
-- =============================================
('JNK',   'SPDR Bloomberg High Yield Bond ETF',                     'Fixed Income', 'High Yield Bond', 'High Yield Corporate',            'NYSE',   NULL),
('USHY',  'iShares Broad USD High Yield Corp Bond ETF',             'Fixed Income', 'High Yield Bond', 'High Yield Corporate',            'NYSE',   NULL),
('SHYG',  'iShares 0-5 Year High Yield Corp Bond ETF',             'Fixed Income', 'High Yield Bond', 'Short-Term High Yield',           'NYSE',   NULL);



-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- 1. Total count — should return 45
SELECT COUNT(*) AS total_securities
FROM HACKATHON.HACKATHON_SCHEMA.security_master;

-- 2. Orphan check — should return ZERO rows
--    (every ticker in holdings must exist in security_master)
SELECT DISTINCT h.ticker AS orphan_ticker
FROM HACKATHON.HACKATHON_SCHEMA.client_position_holdings h
LEFT JOIN HACKATHON.HACKATHON_SCHEMA.security_master sm
    ON h.ticker = sm.ticker
WHERE sm.ticker IS NULL;

-- 3. Breakdown by sector
SELECT sector_code, COUNT(*) AS cnt
FROM HACKATHON.HACKATHON_SCHEMA.security_master
GROUP BY sector_code
ORDER BY cnt DESC;

-- 4. Breakdown by asset class
SELECT asset_class, COUNT(*) AS cnt
FROM HACKATHON.HACKATHON_SCHEMA.security_master
GROUP BY asset_class
ORDER BY cnt DESC;

-- 5. View all records
SELECT *
FROM HACKATHON.HACKATHON_SCHEMA.security_master
ORDER BY asset_class, sector_code, ticker;



+++++++++++++++++++
ALTER TABLE HACKATHON.HACKATHON_SCHEMA.security_master
ADD COLUMN momentum_score DECIMAL(5,2)
COMMENT 'Momentum score (-100 to +100). Positive = upward price trend,
Negative = downward trend. Based on 3M vs 12M price performance.
Used for portfolio rebalancing signals in Cortex AI PAE engine.';


-- ============================================================
-- UPDATE momentum_score for ALL 144 tickers in security_master
-- Score range: -100.00 to +100.00
-- Logic:
--   > +50  = Strong upward momentum (BUY signal)
--   +10 to +50 = Moderate positive momentum (HOLD/ADD)
--   -10 to +10 = Neutral / sideways
--   -10 to -50 = Moderate negative momentum (TRIM signal)
--   < -50  = Strong downward momentum (SELL/REBALANCE signal)
-- As of: 2026-02-24
-- ============================================================

UPDATE HACKATHON.HACKATHON_SCHEMA.security_master
SET momentum_score = CASE ticker

    -- =============================================
    -- TECHNOLOGY (Equity) — Generally strong sector
    -- =============================================
    WHEN 'AAPL'  THEN  42.50   -- Steady performer, moderate uptrend
    WHEN 'MSFT'  THEN  55.80   -- Strong cloud + AI tailwinds
    WHEN 'NVDA'  THEN  88.50   -- AI/GPU dominance — top momentum
    WHEN 'GOOGL' THEN  38.20   -- AI investments, steady recovery
    WHEN 'CRM'   THEN  32.10   -- Moderate, AI CRM growth
    WHEN 'INTC'  THEN -42.30   -- Losing market share, declining trend
    WHEN 'AMD'   THEN  61.40   -- Strong AI chip momentum
    WHEN 'ADBE'  THEN  18.90   -- Mixed — AI uncertainty priced in
    WHEN 'ORCL'  THEN  52.70   -- Cloud acceleration momentum
    WHEN 'CSCO'  THEN  12.40   -- Stable but low momentum
    WHEN 'AVGO'  THEN  72.30   -- AI networking boom
    WHEN 'TXN'   THEN   8.50   -- Cyclical slowdown, near neutral
    WHEN 'QCOM'  THEN  28.60   -- Mobile/IoT recovering
    WHEN 'NOW'   THEN  48.90   -- Strong SaaS growth momentum
    WHEN 'INTU'  THEN  35.20   -- Tax/SMB software steady growth

    -- =============================================
    -- HEALTHCARE (Equity) — Mixed sector
    -- =============================================
    WHEN 'JNJ'   THEN  15.30   -- Defensive, steady but slow
    WHEN 'PFE'   THEN -38.50   -- Post-COVID revenue drop
    WHEN 'UNH'   THEN  22.80   -- Healthcare managed care stable
    WHEN 'ABBV'  THEN  31.60   -- Strong pipeline momentum
    WHEN 'TMO'   THEN  19.40   -- Life sciences recovery
    WHEN 'LLY'   THEN  82.70   -- GLP-1/Ozempic wave — top momentum
    WHEN 'MRK'   THEN  24.50   -- Keytruda growth solid
    WHEN 'BMY'   THEN  -8.20   -- Patent cliff concerns
    WHEN 'AMGN'  THEN  16.80   -- Moderate biotech momentum
    WHEN 'GILD'  THEN  11.30   -- Slow recovery
    WHEN 'ISRG'  THEN  58.40   -- Robotic surgery strong growth
    WHEN 'MDT'   THEN  -5.60   -- Navigating device headwinds
    WHEN 'SYK'   THEN  44.20   -- Strong orthopedics demand
    WHEN 'VRTX'  THEN  62.10   -- CF/gene editing momentum
    WHEN 'REGN'  THEN  39.80   -- Dupixent driving growth

    -- =============================================
    -- FINANCIALS (Equity) — Rate environment dependent
    -- =============================================
    WHEN 'JPM'   THEN  48.60   -- Strong banking, rate tailwinds
    WHEN 'GS'    THEN  55.20   -- M&A revival driving momentum
    WHEN 'V'     THEN  41.30   -- Payments volume growth steady
    WHEN 'BRK.B' THEN  36.70   -- Defensive value momentum
    WHEN 'BAC'   THEN  33.40   -- Rate sensitivity moderate
    WHEN 'WFC'   THEN  29.80   -- Regulatory overhang easing
    WHEN 'C'     THEN  22.10   -- Transformation underway
    WHEN 'MS'    THEN  47.90   -- Wealth mgmt + M&A tailwinds
    WHEN 'SCHW'  THEN  18.50   -- Rate normalization impact
    WHEN 'AXP'   THEN  52.30   -- Premium consumer spending strong
    WHEN 'MA'    THEN  43.80   -- Cross-border travel recovery
    WHEN 'BLK'   THEN  38.60   -- AUM growth + ETF dominance
    WHEN 'MMC'   THEN  30.20   -- Insurance brokerage steady
    WHEN 'PGR'   THEN  61.50   -- Auto insurance pricing power

    -- =============================================
    -- ENERGY (Equity) — Oil price dependent
    -- =============================================
    WHEN 'XOM'   THEN  28.40   -- Stable oil, moderate momentum
    WHEN 'CVX'   THEN  22.70   -- Hess deal integration focus
    WHEN 'COP'   THEN  31.90   -- E&P efficiency gains
    WHEN 'SLB'   THEN  14.20   -- Oilfield services recovery slow
    WHEN 'EOG'   THEN  35.60   -- Shale efficiency leader
    WHEN 'MPC'   THEN  42.10   -- Refining margins strong
    WHEN 'PSX'   THEN  38.80   -- Refining + chemicals momentum
    WHEN 'VLO'   THEN  40.50   -- Strong refining throughput
    WHEN 'OXY'   THEN  25.30   -- Buffett holding, steady
    WHEN 'HAL'   THEN  18.60   -- Services cycle recovery

    -- =============================================
    -- CONSUMER DISCRETIONARY (Equity) — Consumer health dependent
    -- =============================================
    WHEN 'AMZN'  THEN  58.30   -- AWS + retail momentum strong
    WHEN 'TSLA'  THEN -22.40   -- Price war + demand softness
    WHEN 'HD'    THEN  24.60   -- Housing market tied
    WHEN 'NKE'   THEN  -9.80   -- China headwinds + inventory
    WHEN 'SBUX'  THEN -14.20   -- Traffic slowdown concern
    WHEN 'MCD'   THEN  18.90   -- Value menu driving traffic
    WHEN 'LOW'   THEN  22.30   -- Housing recovery play
    WHEN 'TJX'   THEN  45.70   -- Off-price retail thriving
    WHEN 'BKNG'  THEN  52.40   -- Travel demand robust
    WHEN 'MAR'   THEN  38.90   -- Hospitality recovery solid
    WHEN 'GM'    THEN  -5.30   -- EV transition uncertainty

    -- =============================================
    -- CONSUMER STAPLES (Equity) — Defensive, low momentum
    -- =============================================
    WHEN 'PG'    THEN  12.40   -- Defensive, volume recovery
    WHEN 'KO'    THEN   8.70   -- Stable pricing power
    WHEN 'PEP'   THEN   6.20   -- Snack softness headwind
    WHEN 'COST'  THEN  48.30   -- Membership growth strong
    WHEN 'WMT'   THEN  42.60   -- Value consumer + ecommerce
    WHEN 'PM'    THEN  26.80   -- Smoke-free product momentum
    WHEN 'MO'    THEN  -4.50   -- Secular decline tobacco
    WHEN 'CL'    THEN  10.20   -- Emerging market pricing
    WHEN 'MDLZ'  THEN   5.80   -- Volume recovery modest
    WHEN 'GIS'   THEN  -2.30   -- Post-COVID demand normalization

    -- =============================================
    -- COMMUNICATION SERVICES (Equity) — Mixed
    -- =============================================
    WHEN 'META'  THEN  74.20   -- AI ads + metaverse pivot win
    WHEN 'DIS'   THEN -16.80   -- Streaming profitability struggle
    WHEN 'NFLX'  THEN  65.30   -- Ad-tier + password sharing fix
    WHEN 'T'     THEN  -8.40   -- Debt burden, slow growth
    WHEN 'VZ'    THEN  -6.20   -- Telecom saturation
    WHEN 'TMUS'  THEN  32.50   -- 5G subscriber growth leader
    WHEN 'CMCSA' THEN   4.80   -- Cable cord-cutting pressure
    WHEN 'CHTR'  THEN  -3.60   -- Broadband competition rising
    WHEN 'EA'    THEN  10.40   -- Gaming cycle mid-momentum
    WHEN 'WBD'   THEN -28.60   -- Restructuring + debt concerns

    -- =============================================
    -- INDUSTRIALS (Equity) — Broad strength
    -- =============================================
    WHEN 'CAT'   THEN  42.80   -- Infrastructure demand strong
    WHEN 'BA'    THEN -31.40   -- Safety issues + delivery delays
    WHEN 'UPS'   THEN  -8.90   -- Volume softness, cost pressures
    WHEN 'HON'   THEN  28.60   -- Automation/aerospace steady
    WHEN 'GE'    THEN  68.40   -- Aerospace spinoff momentum
    WHEN 'RTX'   THEN  52.70   -- Defense spending tailwinds
    WHEN 'LMT'   THEN  44.30   -- Defense budget growth
    WHEN 'DE'    THEN  18.20   -- Ag equipment cycle moderating
    WHEN 'MMM'   THEN  -2.80   -- Legal overhang + restructuring
    WHEN 'FDX'   THEN  22.10   -- Cost transformation underway
    WHEN 'WM'    THEN  32.40   -- Sustainability + pricing power
    WHEN 'ETN'   THEN  58.90   -- Electrification megatrend

    -- =============================================
    -- UTILITIES (Equity) — AI power demand tailwind
    -- =============================================
    WHEN 'NEE'   THEN  34.60   -- Renewables + AI data center power
    WHEN 'DUK'   THEN  18.30   -- Regulated utility steady
    WHEN 'SO'    THEN  15.80   -- Nuclear + regulated momentum
    WHEN 'AEP'   THEN  22.40   -- Grid investment tailwinds
    WHEN 'D'     THEN   8.60   -- Restructuring stabilizing
    WHEN 'EXC'   THEN  20.10   -- Nuclear energy revival
    WHEN 'SRE'   THEN  24.80   -- LNG export growth
    WHEN 'XEL'   THEN  16.50   -- Renewable transition solid
    WHEN 'ED'    THEN  10.20   -- NYC regulated utility stable
    WHEN 'WEC'   THEN  14.70   -- Midwest utility steady growth

    -- =============================================
    -- REAL ESTATE / REIT — Rate sensitive
    -- =============================================
    WHEN 'AMT'   THEN  22.30   -- Tower REIT digital infra
    WHEN 'PLD'   THEN  28.60   -- Industrial logistics REIT strong
    WHEN 'SPG'   THEN  18.40   -- Retail REIT stabilizing
    WHEN 'O'     THEN  12.80   -- Monthly dividend REIT steady
    WHEN 'EQIX'  THEN  48.20   -- Data center REIT AI tailwind
    WHEN 'PSA'   THEN  14.60   -- Self-storage demand stable
    WHEN 'DLR'   THEN  52.30   -- Data center AI demand boom
    WHEN 'WELL'  THEN  38.90   -- Senior housing demand growing
    WHEN 'AVB'   THEN  16.70   -- Apartment REIT rate pressure ease
    WHEN 'CCI'   THEN  -8.40   -- Tower decommissioning headwind

    -- =============================================
    -- MATERIALS (Equity) — Commodity cycle dependent
    -- =============================================
    WHEN 'LIN'   THEN  32.40   -- Industrial gas steady demand
    WHEN 'APD'   THEN  24.80   -- Hydrogen momentum building
    WHEN 'FCX'   THEN  38.60   -- Copper demand AI/EV boom
    WHEN 'SHW'   THEN  28.90   -- Housing recovery paint demand
    WHEN 'ECL'   THEN  22.40   -- Water treatment steady
    WHEN 'NEM'   THEN  42.10   -- Gold price momentum strong
    WHEN 'DD'    THEN  12.30   -- Specialty chemicals recovery
    WHEN 'NUE'   THEN  18.60   -- Steel demand infrastructure
    WHEN 'DOW'   THEN  -4.20   -- Chemical cycle headwind
    WHEN 'PPG'   THEN  15.80   -- Coatings demand recovering

    -- =============================================
    -- FIXED INCOME — Low momentum, inverse rate sensitivity
    -- =============================================
    -- Bond Funds
    WHEN 'BND'   THEN   4.20   -- Broad market bond steady
    WHEN 'AGG'   THEN   3.80   -- Aggregate bond index stable
    WHEN 'BNDX'  THEN   2.60   -- International bond modest
    WHEN 'SCHZ'  THEN   3.50   -- Aggregate bond stable
    WHEN 'BSV'   THEN   5.10   -- Short-term bond positive rate
    -- Treasury
    WHEN 'TLT'   THEN  -8.60   -- Long-duration rate pressure
    WHEN 'SHY'   THEN   6.20   -- Short-term treasury positive
    WHEN 'IEF'   THEN  -2.40   -- Intermediate treasury neutral
    WHEN 'GOVT'  THEN   1.80   -- Broad treasury neutral
    -- Corporate Bond
    WHEN 'LQD'   THEN  -3.20   -- IG corporate modest negative
    WHEN 'VCIT'  THEN  -1.80   -- Intermediate corp neutral
    WHEN 'VCSH'  THEN   4.60   -- Short-term corp positive
    WHEN 'IGIB'  THEN  -2.10   -- Mid-term IG slight negative
    -- High Yield Bond
    WHEN 'HYG'   THEN   8.40   -- HY spreads tightening positive
    WHEN 'JNK'   THEN   7.90   -- HY positive carry momentum
    WHEN 'USHY'  THEN   8.10   -- Broad HY positive
    WHEN 'SHYG'  THEN   9.20   -- Short HY positive carry

    ELSE NULL  -- Safety net for any unmapped ticker
END;
