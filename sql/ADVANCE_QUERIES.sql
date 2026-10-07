USE tesla_autopilot;


/* A1. Autopilot use by road class
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


/* A2. Autopilot use and average speed by weather
Rain and snow are stored as flags in the environment table. This query groups
the data by those flags and compares Autopilot use and average vehicle speed
for each weather combination. Speed is converted from kph to mph. */
SELECT 
    env.app_environment_rainy AS rainy,
    env.app_environment_snowy AS snowy,
    COUNT(*) AS sample_count,
    ROUND(
        100.0 * SUM(ap.das_autopilot_state_label LIKE 'ACTIVE%')
        / COUNT(ap.das_autopilot_state_label),
        2
    ) AS active_percent,
    ROUND(AVG(v.veh_speed_kph) * 0.621371, 1) AS avg_speed_mph
FROM environment_telemetry env
JOIN autopilot_telemetry ap USING (sample_id)
JOIN vehicle_telemetry v USING (sample_id)
GROUP BY env.app_environment_rainy, env.app_environment_snowy
ORDER BY sample_count DESC;


/* A3. Autopilot use and speed for each wiper setting
Wiper speed can be used as a rough sign of rain intensity. This query checks
whether Autopilot use or average driving speed changes when the wipers are
running at different settings. Rows with no wiper setting are not included. */
SELECT 
    env.vcfront_wiper_speed_label AS wiper_speed,
    COUNT(*) AS sample_count,
    ROUND(
        100.0 * SUM(ap.das_autopilot_state_label LIKE 'ACTIVE%')
        / COUNT(ap.das_autopilot_state_label),
        2
    ) AS active_percent,
    ROUND(AVG(v.veh_speed_kph) * 0.621371, 1) AS avg_speed_mph
FROM environment_telemetry env
JOIN autopilot_telemetry ap USING (sample_id)
JOIN vehicle_telemetry v USING (sample_id)
WHERE env.vcfront_wiper_speed_label IS NOT NULL
GROUP BY env.vcfront_wiper_speed_label
ORDER BY sample_count DESC;


/* A4. Set speed compared with actual speed
This looks only at samples where Autopilot was active and both speed values
were available. It compares the driver's set speed with the actual vehicle
speed for each map speed limit. Groups with less than 1,000 samples are left
out so very small groups dont affect the comparison too much. */
SELECT 
    rc.ui_map_speed_limit_label AS speed_limit,
    COUNT(*) AS active_samples,
    ROUND(AVG(ap.das_set_speed_kph) * 0.621371, 1) AS avg_set_speed_mph,
    ROUND(AVG(v.veh_speed_kph) * 0.621371, 1) AS avg_actual_speed_mph,
    ROUND(
        AVG(ap.das_set_speed_kph - v.veh_speed_kph) * 0.621371,
        1
    ) AS avg_speed_difference_mph
FROM autopilot_telemetry ap
JOIN vehicle_telemetry v USING (sample_id)
JOIN road_context rc USING (sample_id)
WHERE ap.das_autopilot_state_label LIKE 'ACTIVE%'
  AND ap.das_set_speed_kph IS NOT NULL
  AND v.veh_speed_kph IS NOT NULL
GROUP BY rc.ui_map_speed_limit_label
HAVING COUNT(*) >= 1000
ORDER BY active_samples DESC;


/* A5. Following distance by traffic level and gap setting
Vehicle count is divided into empty, light or moderate, and heavy traffic.
For each traffic group and follow setting, the query finds the average control
distance used while Autopilot was active. */
SELECT 
    tr.ui_acc_follow_distance_setting_label AS follow_setting,
    CASE 
        WHEN tr.vehicle_count IS NULL THEN 'Unknown'
        WHEN tr.vehicle_count = 0 THEN '0 vehicles (Empty)'
        WHEN tr.vehicle_count <= 2 THEN '1-2 vehicles (Light/Mod)'
        ELSE '3+ vehicles (Heavy)'
    END AS traffic_level,
    COUNT(*) AS sample_count,
    ROUND(AVG(tr.das_control_distance_m), 1) AS avg_control_distance_m
FROM traffic_telemetry tr
JOIN autopilot_telemetry ap USING (sample_id)
WHERE ap.das_autopilot_state_label LIKE 'ACTIVE%'
  AND tr.das_control_distance_m IS NOT NULL
GROUP BY follow_setting, traffic_level
ORDER BY follow_setting, traffic_level;


/* A6. Planned gap setting and actual control distance
The drive table contains the gap setting planned for each test drive. This
query connects that information with the real-time traffic data and shows the
average control distance and Autopilot use for each planned setting. */
SELECT 
    d.gap_setting AS planned_gap_setting,
    COUNT(DISTINCT d.drive_id) AS drive_count,
    COUNT(*) AS sample_count,
    ROUND(AVG(tr.das_control_distance_m), 1) AS avg_control_distance_m,
    ROUND(
        100.0 * SUM(ap.das_autopilot_state_label LIKE 'ACTIVE%')
        / COUNT(ap.das_autopilot_state_label),
        2
    ) AS active_percent
FROM drive d
JOIN telemetry_sample ts
    ON ts.drive_id = d.drive_id
JOIN traffic_telemetry tr
    ON tr.sample_id = ts.sample_id
JOIN autopilot_telemetry ap
    ON ap.sample_id = ts.sample_id
GROUP BY d.gap_setting
ORDER BY d.gap_setting;


/* A7. Hard-braking rate by traffic level and driving mode
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


/* A8. Lane-change activity for each road class
This checks where automated lane-change states appeared in the dataset.
It counts each state by road class, but only keeps combinations with at least
50 samples so the result is not filled with very small groups. */
SELECT 
    rc.ui_road_class_label AS road_class,
    ap.das_auto_lane_change_state_label AS lane_change_state,
    COUNT(*) AS sample_count
FROM autopilot_telemetry ap
JOIN road_context rc USING (sample_id)
WHERE ap.das_auto_lane_change_state_label IS NOT NULL
GROUP BY 
    rc.ui_road_class_label,
    ap.das_auto_lane_change_state_label
HAVING COUNT(*) >= 50
ORDER BY road_class, sample_count DESC;


/* A9. Drives with hard braking while Autopilot was active
EXISTS is used to find drives that contain at least one active Autopilot sample
where longitudinal acceleration was -3.0 m/s^2 or lower. Each matching drive
is returned only once even if it has many hard-braking samples. */
SELECT 
    d.drive_id,
    d.route,
    d.gap_setting
FROM drive d
WHERE EXISTS (
    SELECT 1
    FROM telemetry_sample ts
    JOIN autopilot_telemetry ap
        ON ap.sample_id = ts.sample_id
    JOIN brake_dynamics_telemetry b
        ON b.sample_id = ts.sample_id
    WHERE ts.drive_id = d.drive_id
      AND ap.das_autopilot_state_label LIKE 'ACTIVE%'
      AND b.rcm_longitudinal_accel_m_s_2 <= -3.0
)
ORDER BY d.test_number;


/* A10. Drives with no active Autopilot samples
NOT EXISTS checks each drive and removes it if any ACTIVE Autopilot state is
found. These drives can be used as possible manual baselines, although some
samples may also have an unknown or other non-active state. */
SELECT 
    d.drive_id,
    d.route,
    d.gap_setting,
    d.distance_miles
FROM drive d
WHERE NOT EXISTS (
    SELECT 1
    FROM telemetry_sample ts
    JOIN autopilot_telemetry ap
        ON ap.sample_id = ts.sample_id
    WHERE ts.drive_id = d.drive_id
      AND ap.das_autopilot_state_label LIKE 'ACTIVE%'
)
ORDER BY d.test_number;


/* A11. Drives with above-average hard-braking rates
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