/* A1. Autopilot use and average speed by weather
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


/* A2. Autopilot use and speed for each wiper setting
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
