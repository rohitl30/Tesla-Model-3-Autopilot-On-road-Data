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



/* B5. Road class distribution
Road type is one of the conditions we are looking at in this project.
This query lists the road classes in the data and counts how many samples
belong to each class. Rows without a road class are left out here. */
SELECT  ui_road_class_label AS road_type, ui_road_class_code AS road_code,
    COUNT(*) AS sample_count
FROM road_context
WHERE ui_road_class_label IS NOT NULL
GROUP BY ui_road_class_label, ui_road_class_code
ORDER BY sample_count DESC;





/* B6. Weather flag distribution
This groups the samples by the rain and snow flags. It helps show how much
data was recorded in clear, rainy, or snowy conditions. NULL values will
also appear as their own group if the weather flag was missing. */
SELECT  app_environment_rainy AS rainy, app_environment_snowy AS snowy,
    COUNT(*) AS sample_count
FROM environment_telemetry
GROUP BY app_environment_rainy, app_environment_snowy
ORDER BY sample_count DESC;




/* A4. Set speed compared with actual speed
This looks only at samples where Autopilot was active and both speed values
were available. It compares the driver's set speed with the actual vehicle
speed for each map speed limit. Groups with less than 1,000 samples are left
out so very small groups dont affect the comparison too much. */
SELECT rc.ui_map_speed_limit_label AS speed_limit,
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


/* A8. Lane-change activity for each road class
This checks where automated lane-change states appeared in the dataset.
It counts each state by road class, but only keeps combinations with at least
50 samples so the result is not filled with very small groups. */
SELECT  rc.ui_road_class_label AS road_class, ap.das_auto_lane_change_state_label AS lane_change_state,
    COUNT(*) AS sample_count
FROM autopilot_telemetry ap
JOIN road_context rc USING (sample_id)
WHERE ap.das_auto_lane_change_state_label IS NOT NULL
GROUP BY rc.ui_road_class_label, ap.das_auto_lane_change_state_label
HAVING COUNT(*) >= 50
ORDER BY road_class, sample_count DESC;
