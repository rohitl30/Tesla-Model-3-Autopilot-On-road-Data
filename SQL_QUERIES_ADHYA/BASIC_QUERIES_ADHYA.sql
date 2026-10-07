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