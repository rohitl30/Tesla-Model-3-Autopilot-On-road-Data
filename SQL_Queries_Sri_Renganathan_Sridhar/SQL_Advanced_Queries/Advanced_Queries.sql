use tesla_autopilot;

/* A. Autopilot use by road class
This checks whether Autopilot was active more often on certain types of roads.
For each road class, it counts the samples that have a state recorded and then
finds the percentage where the state label starts with ACTIVE. */
SELECT 
    COALESCE(rc.ui_road_class_label, 'Unknown') AS road_class,
    COUNT(ap.das_autopilot_state_label) AS state_samples,
    SUM(ap.das_autopilot_state_label LIKE 'ACTIVE%') AS active_samples,
    ROUND(
        100.0 * SUM(ap.das_autopilot_state_label LIKE 'ACTIVE%')
        / COUNT(ap.das_autopilot_state_label),
        2
    ) AS active_percent
FROM autopilot_telemetry ap
JOIN road_context rc USING (sample_id)
GROUP BY road_class
ORDER BY active_percent DESC;


/* A. Hard-braking rate by traffic level and driving mode
A sample is treated as hard braking when longitudinal acceleration is -3.0
m/s^2 or lower. The query compares Autopilot with manual or other driving in
different traffic levels. The rate is shown per 1,000 valid acceleration samples. */
SELECT 
    CASE 
        WHEN tr.vehicle_count IS NULL THEN 'Unknown'
        WHEN tr.vehicle_count = 0 THEN '0 vehicles'
        WHEN tr.vehicle_count <= 2 THEN '1-2 vehicles'
        ELSE '3+ vehicles'
    END AS traffic_level,
    CASE 
        WHEN ap.das_autopilot_state_label LIKE 'ACTIVE%' THEN 'Autopilot'
        ELSE 'Manual / Other'
    END AS driving_mode,
    COUNT(*) AS sample_count,
    SUM(b.rcm_longitudinal_accel_m_s_2 <= -3.0) AS hard_brake_samples,
    ROUND(
        1000.0 * SUM(b.rcm_longitudinal_accel_m_s_2 <= -3.0)
        / COUNT(b.rcm_longitudinal_accel_m_s_2),
        2
    ) AS hard_brakes_per_1000,
    ROUND(AVG(b.esp_brake_torque_target_nm), 1) AS avg_brake_torque_nm
FROM traffic_telemetry tr
JOIN brake_dynamics_telemetry b USING (sample_id)
JOIN autopilot_telemetry ap USING (sample_id)
GROUP BY traffic_level, driving_mode
ORDER BY traffic_level, driving_mode;

