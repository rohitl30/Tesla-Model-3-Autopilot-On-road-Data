# Midterm Demonstration Guide

## Project

Tesla Model 3 Autopilot Performance Analysis

## Problem and Goal

The project organizes telemetry-related data to examine how traffic, road, speed-limit, and weather conditions are associated with Autopilot engagement, speed control, following distance, lane changes, and braking events. The goal is a reliable data and analytics solution that supports evidence-based decision-making.

## Technology and Architecture

The current stack is Python, Streamlit, Pandas, Plotly, and MySQL as the planned database technology.

Current architecture:

```text
Sample CSV files → Pandas → Plotly → Streamlit dashboard
```

The SQL files define the analytical queries and their output structures. MySQL integration is planned for a later phase and is not part of this midterm version.

## What to Demonstrate

- KPI cards: total drives, total miles, total hours, and average speed.
- Autopilot usage by road class and weather.
- Set speed versus actual speed by speed limit.
- Following distance by traffic level and follow setting.
- Hard-braking rate by traffic level and driving mode.
- Lane-change activity, hard braking while Autopilot was active, drives without active Autopilot samples, and above-average hard-braking rates.
- Sidebar filters and their clearly scoped effects on compatible charts.
- Key observations generated from the currently loaded sample data.

## KPI Explanation

- Total Drives: the overall drive count from B1.
- Total Miles: summed drive distance from B1.
- Total Hours: summed drive duration converted to hours in B1.
- Average Speed: average recorded drive speed from B1.

## Filter Explanation

Road class, weather, speed limit, traffic level, follow setting, and driving mode filters affect only charts whose query-result CSV contains that dimension. They do not claim to filter unrelated aggregated results.

## Important Limitation

All current values are sample/demo query-result data. They are not real Tesla measurements and must not be presented as real-world Tesla findings.

## Recommended Demo Sequence

1. Introduce the problem and project goal.
2. Explain the database and SQL role.
3. Explain the CSV → Pandas → Plotly → Streamlit architecture.
4. Open the dashboard and point out the sample-data notice.
5. Show the KPI cards.
6. Demonstrate the sidebar filters and their compatible chart scopes.
7. Walk through the major charts and additional analyses.
8. Show the cautious, sample-based key observations.
9. Explain the sample-data limitation.
10. Explain future MySQL integration.
