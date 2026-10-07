-- ============================================================
-- Dashboard Query 1: Categorical Distribution
-- EV Count by Make (Top 20)
-- ============================================================
SELECT
    make,
    COUNT(*) AS ev_count
FROM curated_ev_data
WHERE make IS NOT NULL
  AND make != 'Unknown'
GROUP BY make
ORDER BY ev_count DESC
LIMIT 20;

-- ============================================================
-- Dashboard Query 2: Temporal Distribution
-- EV Registrations by Model Year
-- ============================================================
SELECT
    model_year,
    COUNT(*) AS ev_count
FROM curated_ev_data
WHERE model_year IS NOT NULL
GROUP BY model_year
ORDER BY model_year ASC;

-- ============================================================
-- Additional Query: Top Counties
-- ============================================================
SELECT
    county,
    COUNT(*) AS ev_count
FROM curated_ev_data
WHERE county IS NOT NULL
GROUP BY county
ORDER BY ev_count DESC
LIMIT 15;

-- ============================================================
-- Additional Query: EV Type Breakdown
-- ============================================================
SELECT
    ev_type,
    COUNT(*) AS ev_count
FROM curated_ev_data
WHERE ev_type IS NOT NULL
GROUP BY ev_type
ORDER BY ev_count DESC;

-- ============================================================
-- Additional Query: CAFV Eligibility
-- ============================================================
SELECT
    cafv_eligibility_clean,
    COUNT(*) AS ev_count
FROM curated_ev_data
GROUP BY cafv_eligibility_clean
ORDER BY ev_count DESC;
