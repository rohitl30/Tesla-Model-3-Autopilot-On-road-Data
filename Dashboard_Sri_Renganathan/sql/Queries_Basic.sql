USE tesla_autopilot;


/* B1. Overall dataset summary
This gives a quick overview of the complete drive table. It shows the number
of drives, total distance, total driving time in hours, and the average of
the recorded average speeds for all drives. */
SELECT 
    COUNT(*) AS total_drives,
    ROUND(SUM(distance_miles), 1) AS total_miles,
    ROUND(SUM(duration_minutes) / 60.0, 1) AS total_hours,
    ROUND(AVG(avg_speed_mph), 1) AS avg_speed_mph
FROM drive;


/* B2. Number of telemetry samples for each drive
This joins each drive with its telemetry records and counts how many samples
were collected. Since samples were recorded many times per second, drives
with more samples usually have a longer recording. Only the top 10 are shown. */
SELECT 
    d.drive_id,
    d.route,
    COUNT(ts.sample_id) AS sample_count
FROM drive d
JOIN telemetry_sample ts 
    ON ts.drive_id = d.drive_id
GROUP BY d.drive_id, d.route
ORDER BY sample_count DESC
LIMIT 10;


/* B3. Distribution of Autopilot states
This shows the different Autopilot state labels and codes found in the dataset.
It also counts the samples for each state and calculates what percentage of
the Autopilot telemetry belongs to that state. */
SELECT 
    das_autopilot_state_label AS state,
    das_autopilot_state_code AS state_code,
    COUNT(*) AS sample_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM autopilot_telemetry),
        2
    ) AS percent_of_samples
FROM autopilot_telemetry
GROUP BY das_autopilot_state_label, das_autopilot_state_code
ORDER BY sample_count DESC;


/* B4. Follow-distance setting and average control distance
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


/* B5. Road class distribution
Road type is one of the conditions we are looking at in this project.
This query lists the road classes in the data and counts how many samples
belong to each class. Rows without a road class are left out here. */
SELECT 
    ui_road_class_label AS road_type,
    ui_road_class_code AS road_code,
    COUNT(*) AS sample_count
FROM road_context
WHERE ui_road_class_label IS NOT NULL
GROUP BY ui_road_class_label, ui_road_class_code
ORDER BY sample_count DESC;


/* B6. Weather flag distribution
This groups the samples by the rain and snow flags. It helps show how much
data was recorded in clear, rainy, or snowy conditions. NULL values will
also appear as their own group if the weather flag was missing. */
SELECT 
    app_environment_rainy AS rainy,
    app_environment_snowy AS snowy,
    COUNT(*) AS sample_count
FROM environment_telemetry
GROUP BY app_environment_rainy, app_environment_snowy
ORDER BY sample_count DESC;


/* B7. Vehicle speed summary
The original speed values are stored in kilometers per hour, so this query
converts them to miles per hour. Comparing total rows with rows_with_speed
also shows whether some telemetry rows have a missing speed value. */
SELECT 
    COUNT(*) AS total_rows,
    COUNT(veh_speed_kph) AS rows_with_speed,
    ROUND(MIN(veh_speed_kph) * 0.621371, 1) AS min_mph,
    ROUND(AVG(veh_speed_kph) * 0.621371, 1) AS avg_mph,
    ROUND(MAX(veh_speed_kph) * 0.621371, 1) AS max_mph
FROM vehicle_telemetry;


/* B8. Missing values in important Autopilot signals
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


/* B9. Ten highest vehicle-speed readings
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


/* B10. Automatic Emergency Braking status
This lists every AEB label and code in the Autopilot data and counts the
number of samples for each one. The results show how often each AEB status
appears, but the sample count does not mean the number of separate events. */
SELECT 
    das_aeb_event_label AS event_name,
    das_aeb_event_code AS event_code,
    COUNT(*) AS sample_count
FROM autopilot_telemetry
GROUP BY das_aeb_event_label, das_aeb_event_code
ORDER BY sample_count DESC;