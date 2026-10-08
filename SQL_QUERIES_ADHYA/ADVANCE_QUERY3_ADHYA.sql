/* A3. Drives with above-average hard-braking rates
First, the main query calculates the hard-braking sample rate for every drive.
The subquery calculates the same rate for the full dataset. HAVING keeps only
the drives whose rate is higher than the overall rate. These are sample rates,
so they do not represent the number of separate braking events. */
SELECT 
    ts.drive_id,
    d.route,
    COUNT(b.rcm_longitudinal_accel_m_s_2) AS sample_count,
    SUM(b.rcm_longitudinal_accel_m_s_2 <= -3.0) AS hard_brake_samples,
    ROUND(
        1000.0 * SUM(b.rcm_longitudinal_accel_m_s_2 <= -3.0)
        / COUNT(b.rcm_longitudinal_accel_m_s_2),
        2
    ) AS hard_brakes_per_1000
FROM telemetry_sample ts
JOIN brake_dynamics_telemetry b
    ON b.sample_id = ts.sample_id
JOIN drive d
    ON d.drive_id = ts.drive_id
GROUP BY ts.drive_id, d.route
HAVING
    SUM(b.rcm_longitudinal_accel_m_s_2 <= -3.0)
    / COUNT(b.rcm_longitudinal_accel_m_s_2) > (
        /* Overall hard-braking rate for the whole dataset */
        SELECT
            SUM(rcm_longitudinal_accel_m_s_2 <= -3.0)
            / COUNT(rcm_longitudinal_accel_m_s_2)
        FROM brake_dynamics_telemetry
    )
ORDER BY hard_brakes_per_1000 DESC;