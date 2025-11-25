# Automotive Marketplace – Seller Retention Analysis (SQL + Tableau)
*Technical case study based on a synthetic dataset*

## 📌 Overview
This project analyzes seller retention dynamics in an automotive B2B marketplace.  
The goal is to classify seller accounts by activity patterns (new, recurring, reactivated, churned), generate monthly retention KPIs, explore long-term trends, and provide actionable recommendations.

All data used here comes from a **synthetic sample dataset** provided as part of a technical assessment.  
It does **not** reflect real company performance.

---

## 🎯 Objectives
1. **Classify sellers monthly** into the following clusters:  
   - New Sellers  
   - Recurring Sellers  
   - Reactivated Sellers  
   - Churned Sellers  

2. **Produce a monthly overview** of the number of sellers in each cluster using SQL.

3. **Build interactive Tableau dashboards**:
   - cluster-level view + individual cluster filter  
   - segmentation filter (T, A, B, C)  
   - time-series analysis  

4. **Interpret long-term trends** in retention, churn, and reactivation.

5. **Recommend actions** to improve seller retention and operational monitoring.

---

## 🛠️ Data & Tools
- **SQL (Snowflake-style syntax)**
- **Tableau** – dashboards created based on the aggregated monthly results
- The project is based on a **sample dataset provided for a technical assessment**.  
  It included:
  - seller account information (unique IDs, segment categories)
  - auction-level activity (dates and success outcomes)
  This structure was sufficient to build monthly activity profiles and classify sellers into retention clusters.

---

## 🏗️ SQL Approach

### 1. Monthly aggregation
The SQL logic:
- groups all auctions by `seller_account_uuid` and month (using `auction_reference_date`)
- keeps only successful auctions (`is_successful = TRUE`)
- computes seller activity per month

### 2. Classification rules (clusters)
Based on consecutive activity patterns:

| Cluster | Definition |
|--------|------------|
| **New Seller** | First-time seller in that month |
| **Recurring Seller** | Successful auctions in ≥2 consecutive months |
| **Reactivated Seller** | Returns after ≥1 inactive month (but has sold before) |
| **Churned Seller** | No sales for ≥3 months after previously selling |

### 3. SQL structure
- CTE-driven pipeline  
- window functions to inspect previous activity  
- date truncation for clean monthly grouping  
- join with segmentation table (T/A/B/C) for dashboard filtering  

A complete version of the SQL query is available in:  
`/sql/seller_clustering.sql`

---

## 📊 Tableau Dashboards (Screenshots)

### Global Overview
Seller lifecycle, monthly clustering, segment distribution, and high-level KPIs.

![Dashboard Overview](screenshots/dashboard_overview.png)

---

### Retention Metrics & Churn Dynamics
Net growth, churn trends, and segment-level churn behavior.

![Dashboard Retention](screenshots/dashboard_retention.png)


---

## 🔍 Key Insights (Summary)

### 1. Strong recurring base
Recurring sellers form the **largest and most stable cluster**, growing significantly over the last 24 months.

### 2. Reactivation > Acquisition
Reactivated sellers (~104/month) consistently outpace new sellers (~34/month), reflecting:
- a mature marketplace  
- inventory-driven activity cycles  
- healthy seller loyalty  

### 3. Positive net growth
Net growth remains **positive every month**, averaging +80 sellers/month.

### 4. Controlled churn
Churn stabilizes between **10–18%**, down from the more volatile early years.

### 5. Clear seasonality
Churn spikes consistently in:
- **December (Q4 slowdown)**  
- **Summer (July–August)**  

These represent market cycles, not structural problems.

### 6. Segment dynamics
- Segment **T** dominates volumes with moderate churn.  
- Segment **C** improved dramatically: churn reduced from ~40% to ~20–25%.  
- Segment **A** shows the lowest churn but a smaller share.

---

## 💡 Recommendations (Summary)

### 1. Optimize reactivation cycles
- Track short-cycle (1–2 months) vs long-cycle reactivations  
- Monitor the size and health of the reactivation pool  
- Tailor engagement based on reactivation behavior

### 2. Manage seasonal churn proactively
- Pre-season communication campaigns  
- Mid-season outreach to inactive sellers  
- Q1 reactivation push to accelerate return

### 3. Monitor new seller acquisition closely
- Rolling averages + thresholds to detect early declines  
- Root-cause analysis if acquisition drops  
- Combine with segmentation impact → targeted interventions

### 4. Strengthen retention governance
- Build a dedicated retention dashboard  
- Set alert thresholds  
- Link signals to predefined actions (AM outreach, automated flows)  

---

## 📁 Repository Structure
/sql
seller_clustering.sql
/screenshots
dashboard_overview.png
dashboard_clusters.png
/docs
case_study.pdf (optional cleaned portfolio version)
README.md

---

## 📚 What I Learned
- Designing temporal logic for retention/churn modelling  
- Building cluster definitions from raw activity data  
- Analyzing multi-year trends and seasonality  
- Creating actionable dashboards in Tableau  
- Writing business-oriented insights & recommendations  
- Presenting analytical work in a clear storytelling format  

---

## 📄 Attachments
- Technical Test Description (PDF)  
- Insights Report (PDF)  
- Recommendations Report (PDF)

