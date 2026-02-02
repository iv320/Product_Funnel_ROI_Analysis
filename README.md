# 📊 E-Commerce Analytics Dashboard

> **End-to-end product analytics project** analyzing user behavior, marketing ROI, and customer retention for an e-commerce platform using SQL, Python, and Power BI.


## 🎯 Project Overview

This project demonstrates **professional product analytics capabilities** by analyzing:
- **Conversion Funnel** - Where users drop off in the purchase journey
- **Marketing ROI** - Which campaigns deliver real returns
- **Customer Retention** - Do users come back after first purchase?

### Key Metrics
- 📊 **10,000 users** across 5 countries
- 🎯 **38,280 events** tracked (visits, cart additions, purchases)
- 💰 **$670K revenue** from 8 marketing campaigns
- 📈 **40% conversion rate** from visit to purchase

---

## 🎯 Project Overview

This project demonstrates end-to-end product analytics capabilities using **event-based user data** to answer critical business questions:

- **Where are users dropping in the funnel?**
- **Which marketing campaigns deliver real ROI?**
- **Do users come back or churn after first purchase?**

### Business Context

We analyze a fictional shopping app/website where:
1. Users arrive from various marketing channels (Google Ads, Facebook, Instagram, Email, Organic)
2. Users browse products (visit)
3. Users add items to cart
4. Users complete purchases

---

## 📁 Project Structure

```
product-analytics-project/
├── README.md                          # This file
├── data/                              # Generated datasets (CSV)
│   ├── users.csv                      # User demographics & acquisition
│   ├── events.csv                     # User actions (visits, carts, purchases)
│   └── campaigns.csv                  # Marketing campaign details
├── scripts/                           # Data generation
│   └── generate_data.py               # Python script to create realistic data
├── sql/                               # Analysis queries
│   ├── 01_funnel_analysis.sql         # Conversion funnel metrics
│   ├── 02_campaign_performance.sql    # Campaign ROI & efficiency
│   ├── 03_retention_churn.sql         # Cohort retention & churn
│   └── 04_combined_metrics.sql        # Aggregated views for Power BI
├── powerbi/                           # Visualization
│   └── product_analytics_dashboard.pbix  # Interactive dashboard
└── insights/                      # Final analysis

```

---

## 📊 Datasets

### 1. **users.csv** (10,000 rows)
User demographic and acquisition information.

| Column | Description | Example |
|--------|-------------|---------|
| `user_id` | Unique user identifier | 1, 2, 3... |
| `signup_date` | Date user signed up | 2025-07-15 |
| `device` | Device type | mobile, desktop, tablet |
| `country` | User country | USA, UK, Canada, India, Australia |
| `acquisition_source` | Campaign ID that acquired user | 1-8 |

### 2. **events.csv** (~100,000 rows)
Event-level user actions tracking the customer journey.

| Column | Description | Example |
|--------|-------------|---------|
| `event_id` | Unique event identifier | 1, 2, 3... |
| `user_id` | User who performed action | 1, 2, 3... |
| `event_date` | Timestamp of event | 2025-07-15 14:23:00 |
| `event_name` | Type of action | visit, add_to_cart, purchase |
| `product_id` | Product involved (if applicable) | Electronics_42 |
| `campaign_id` | Associated campaign | 1-8 |
| `revenue` | Revenue generated (purchases only) | 149.99 |

### 3. **campaigns.csv** (8 rows)
Marketing campaign information.

| Column | Description | Example |
|--------|-------------|---------|
| `campaign_id` | Unique campaign identifier | 1, 2, 3... |
| `campaign_name` | Campaign name | Google Search - Brand |
| `channel` | Marketing channel | Google Ads, Facebook, Email |
| `cost` | Monthly campaign cost (USD) | 15000 |

---

## 🚀 Getting Started

### Prerequisites

- **Python 3.8+** (for data generation)
- **SQL Database** (SQL Server, PostgreSQL, or SQLite)
- **Power BI Desktop** (for visualization)

### Step 1: Generate Data

```bash
cd scripts
python generate_data.py
```

This creates three CSV files in the `data/` directory with realistic e-commerce data.

**Expected Output:**
- `users.csv` - 10,000 users
- `events.csv` - ~100,000 events
- `campaigns.csv` - 8 campaigns

### Step 2: Import Data to SQL Database

**Option A: SQL Server / PostgreSQL**

```sql
-- Create tables
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    signup_date DATE,
    device VARCHAR(20),
    country VARCHAR(50),
    acquisition_source INT
);

CREATE TABLE events (
    event_id INT PRIMARY KEY,
    user_id INT,
    event_date DATETIME,
    event_name VARCHAR(50),
    product_id VARCHAR(100),
    campaign_id INT,
    revenue DECIMAL(10,2)
);

CREATE TABLE campaigns (
    campaign_id INT PRIMARY KEY,
    campaign_name VARCHAR(100),
    channel VARCHAR(50),
    cost DECIMAL(10,2)
);

-- Import CSVs using your database's import tool
-- SQL Server: BULK INSERT or Import Wizard
-- PostgreSQL: COPY command
```

**Option B: SQLite (Lightweight)**

```python
import pandas as pd
import sqlite3

# Create database
conn = sqlite3.connect('product_analytics.db')

# Import CSVs
pd.read_csv('data/users.csv').to_sql('users', conn, if_exists='replace', index=False)
pd.read_csv('data/events.csv').to_sql('events', conn, if_exists='replace', index=False)
pd.read_csv('data/campaigns.csv').to_sql('campaigns', conn, if_exists='replace', index=False)

conn.close()
```

### Step 3: Run SQL Analysis

Execute queries in the `sql/` directory:

1. **Funnel Analysis** (`01_funnel_analysis.sql`)
   - Overall conversion rates
   - Drop-off points
   - Funnel by device, campaign, country

2. **Campaign Performance** (`02_campaign_performance.sql`)
   - ROI by campaign
   - Cost per acquisition
   - Channel comparison

3. **Retention & Churn** (`03_retention_churn.sql`)
   - Cohort retention rates
   - Repeat purchase analysis
   - Churn identification

4. **Combined Metrics** (`04_combined_metrics.sql`)
   - Aggregated views for Power BI

### Step 4: Build Power BI Dashboard

1. Open Power BI Desktop
2. **Get Data** → Import from your SQL database or CSV files
3. Load the following tables:
   - `users`
   - `events`
   - `campaigns`
4. Create relationships:
   - `users.user_id` ↔ `events.user_id`
   - `users.acquisition_source` ↔ `campaigns.campaign_id`
   - `events.campaign_id` ↔ `campaigns.campaign_id`

5. Build visualizations 

---

## 📈 Key Metrics Defined

### Funnel Metrics
- **Visit → Cart Conversion**: % of visitors who add items to cart
- **Cart → Purchase Conversion**: % of cart users who complete purchase
- **Overall Conversion Rate**: % of visitors who purchase

### Campaign Metrics
- **Cost Per Acquisition (CPA)**: Campaign cost ÷ Users acquired
- **ROI**: (Revenue - Cost) ÷ Cost × 100%
- **ROAS**: Revenue ÷ Cost

### Retention Metrics
- **Cohort Retention**: % of users from signup month who return
- **Repeat Purchase Rate**: % of purchasers who buy again
- **Churn Rate**: % of users inactive >30 days

---

## 📊 Power BI Dashboard Design

### Page 1: Executive Summary
**KPI Cards:**
- Total Users
- Total Revenue
- Overall Conversion Rate
- Marketing ROI

**Charts:**
- Daily revenue trend (line chart)
- User signups by month (column chart)
- Top 3 campaigns by revenue (table)

### Page 2: Funnel Analysis
**Visualizations:**
- Funnel chart (Visit → Cart → Purchase)
- Drop-off analysis (bar chart)
- Conversion rates by device (stacked bar)
- Funnel by campaign (matrix)

**Filters:**
- Date range
- Campaign
- Device type

### Page 3: Campaign Performance
**Visualizations:**
- Campaign ROI comparison (bar chart)
- Cost vs Revenue scatter plot
- Channel performance table
- Budget allocation vs revenue share (donut charts)

**Key Insights:**
- Highlight campaigns with ROI > 100%
- Flag underperforming campaigns (ROI < 0%)

### Page 4: Retention & Churn
**Visualizations:**
- Cohort retention heatmap
- Repeat purchase rate by campaign (bar chart)
- Churn rate trend (line chart)
- Customer lifetime value distribution (histogram)

**Filters:**
- Cohort month
- Acquisition channel

---

## 🔍 Sample Insights

Based on the generated data, you might find:

1. **Funnel Drop-off**: "40% of users drop between cart and purchase → investigate checkout UX"

2. **Campaign Efficiency**: "Instagram Influencer brings high traffic but 15% conversion vs Google Brand at 35%"

3. **Retention Pattern**: "Users who purchase in first week have 2x higher repeat rate"

4. **ROI Winners**: "Email campaigns deliver 180% ROI at lowest cost"

---

## 🛠️ Technologies Used

| Component | Technology |
|-----------|-----------|
| Data Generation | Python (pandas, numpy, faker) |
| Data Storage | CSV / SQL Database |
| Analysis | SQL (T-SQL compatible) |
| Visualization | Power BI Desktop |
| Documentation | Markdown |

---

## 🚀 Future Enhancements (Not Yet Implemented)

1. **Extend Analysis**
   - Add product category analysis
   - Implement RFM segmentation
   - Build predictive churn model

2. **Automation**
   - Schedule data refresh
   - Automate report distribution
   - Set up alerts for KPI thresholds

3. **Advanced Features**
   - A/B test analysis framework
   - Customer journey mapping
   - Attribution modeling

---


---



