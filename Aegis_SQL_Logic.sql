/* PROJECT AEGIS: Synthetic Financial Dataset for Fraud Detection
PHASE 2: Risk-Based Transaction Profiling (High-Value Outliers)
ANALYST: Jen Jones

OBJECTIVE: Identify transactions exceeding the 99th percentile of monetary volume 
to prioritize for Enhanced Due Diligence (EDD).

RATIONALE: 
Flagging high-value 'TRANSFER' and 'CASH_OUT' patterns establishes a 
baseline for institutional risk appetite. This phase isolates statistical 
outliers for manual investigative review.
*/

SELECT 
 step AS transaction_hour,
 type AS transaction_method,
 amount,
 nameOrig AS sender_account,
 nameDest AS recipient_account,
 oldbalanceOrg AS initial_sender_balance,
 -- Real-time reconciliation check to verify ledger integrity
 ROUND(oldbalanceOrg - amount, 2) AS calculated_final_balance,
 newbalanceOrig AS actual_final_balance,
 isFraud AS fraud_ground_truth
FROM `micro-pilot-455304-t1.Financial_Risk_Project.paysim_data`
WHERE amount > 500000 
 AND type IN ('TRANSFER', 'CASH_OUT')
ORDER BY amount DESC
LIMIT 100;



/* PROJECT AEGIS: Phase 3 – High-Velocity Structuring Detection
ANALYST: Jen Jones

OBJECTIVE: Identify potential 'Structuring' or 'Smurfing' patterns where 
multiple high-frequency transactions originate from the same account.

RATIONALE: 
High-frequency layering of smaller amounts is a common typology for 
money laundering. This query isolates 'velocity' as a risk factor to 
detect illicit movement that single-transaction filters might miss.
*/

SELECT 
 nameOrig AS sender_account,
 step AS transaction_hour,
 COUNT(*) AS transaction_count,
 ROUND(SUM(amount), 2) AS total_volume_per_hour,
 ROUND(AVG(amount), 2) AS average_tx_amount
FROM `micro-pilot-455304-t1.Financial_Risk_Project.paysim_data`
WHERE type IN ('TRANSFER', 'CASH_OUT')
GROUP BY nameOrig, step
HAVING COUNT(*) > 1 -- Isolating accounts with multiple movements in a single window
ORDER BY transaction_count DESC, total_volume_per_hour DESC
LIMIT 100;






/* PROJECT AEGIS: Phase 4 – Weighted Risk Scoring Model
ANALYST: Jen Jones

OBJECTIVE: Generate a 'Priority Risk Score' (0-100) by weighing 
transaction volume, frequency, and system fraud indicators.

RATIONALE: 
To support scalable Quality Control (QC) operations, I am automating the 
prioritization of high-risk entities. This allows investigators to focus 
resources on accounts with the highest potential institutional impact.
*/

WITH Account_Risk_Profiles AS (
 SELECT 
   nameOrig AS sender_account,
   COUNT(*) AS total_velocity,
   SUM(amount) AS total_volume,
   MAX(isFraud) AS confirmed_fraud_flag,
   -- Weighted Logic: Volume (70%) and Velocity (30%)
   (SUM(amount) * 0.7) + (COUNT(*) * 100000 * 0.3) AS raw_risk_score
 FROM `micro-pilot-455304-t1.Financial_Risk_Project.paysim_data`
 WHERE type IN ('TRANSFER', 'CASH_OUT')
 GROUP BY nameOrig
)

SELECT 
 sender_account,
 total_velocity,
 ROUND(total_volume, 2) AS total_volume,
 confirmed_fraud_flag,
 -- Normalizing the score for executive reporting (Scale 0-100)
 ROUND(PERCENT_RANK() OVER (ORDER BY raw_risk_score) * 100, 2) AS integrity_priority_score
FROM Account_Risk_Profiles
WHERE total_volume > 0
ORDER BY integrity_priority_score DESC
LIMIT 100;




