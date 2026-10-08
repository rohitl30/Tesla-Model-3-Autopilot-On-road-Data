Use tesla_autopilot;

/* B. Follow-distance setting and average control distance
This checks how often each ACC follow setting was used. It also calculates
the average commanded control distance for every setting, which helps us see
if a higher follow setting usually gives more distance from the car ahead. */
SELECT 
    ui_acc_follow_distance_setting_label AS gap_setting,
    ui_acc_follow_distance_setting_code AS gap_code,
    COUNT(*) AS sample_count,
    ROUND(AVG(das_control_distance_m), 1) AS avg_distance_m
FROM traffic_telemetry
WHERE ui_acc_follow_distance_setting_label IS NOT NULL
GROUP BY 
    ui_acc_follow_distance_setting_label,
    ui_acc_follow_distance_setting_code
ORDER BY gap_code;


/* B. Missing values in important Autopilot signals
This checks how many rows contain the Autopilot state, set speed, and minimum
acceleration limit. It also calculates the percentage of rows where the set
speed is missing, since that is an important signal for ACC analysis. */
SELECT 
    COUNT(*) AS total_rows,
    COUNT(das_autopilot_state_label) AS rows_with_state,
    COUNT(das_set_speed_kph) AS rows_with_set_speed,
    COUNT(das_accel_min_m_s_2) AS rows_with_accel_limit,
    ROUND(
        100.0 * (COUNT(*) - COUNT(das_set_speed_kph)) / COUNT(*),
        1
    ) AS set_speed_missing_percent
FROM autopilot_telemetry;


/* B. Ten highest vehicle-speed readings
This shows the drive and sample IDs for the fastest readings in the dataset.
Looking at the highest values can help us notice speeds that seem unrealistic
and may have come from a sensor or data problem. */
SELECT 
    ts.drive_id,
    ts.sample_id,
    ROUND(v.veh_speed_kph * 0.621371, 1) AS speed_mph
FROM vehicle_telemetry v
JOIN telemetry_sample ts
    ON ts.sample_id = v.sample_id
WHERE v.veh_speed_kph IS NOT NULL
ORDER BY v.veh_speed_kph DESC
LIMIT 10;