# Tesla Model 3 Autopilot Performance Analysis

Contributor: Sri Renganathan

## Problem Statement

"Tesla Model 3 Autopilot behavior may vary according to traffic, road type, speed limits, and weather conditions. However, the raw data is distributed across multiple telemetry tables, making it difficult to organize and analyze. This project will structure the data and investigate how these conditions are associated with Autopilot engagement, speed control, following distance, lane changes, and braking events."

## Project Goal

"To develop a reliable data and analytics solution that organizes real-world Tesla Model 3 driving records and assesses how traffic, road, and weather conditions relate to Autopilot performance, supporting evidence-based decision-making."

## Technology Stack

- Python
- Streamlit
- Plotly
- Pandas
- MySQL

## Current Development Stage

- The midterm-ready Streamlit dashboard uses sample/demo query-result CSV files.
- It provides four KPI cards, the core Autopilot/speed/following/braking charts, additional lane-change and drive-level analyses, scoped interactive filters, and sample-based key observations.
- MySQL is not currently connected.
- The dashboard will later be integrated with the actual MySQL database.
- The existing SQL files contain the team's analytical queries.

The sample values are not real Tesla measurements.

## Current Dashboard

The dashboard currently provides KPI cards, Autopilot usage analysis, weather analysis, speed analysis, following-distance analysis, hard-braking analysis, lane-change analysis, additional Autopilot/braking activity analysis, and interactive filters.

## Current Data Source

The current dashboard uses sample/demo query-result CSV files. These values are not real Tesla measurements.

## Architecture

```text
Sample CSV → Pandas → Plotly → Streamlit
```

## Future MySQL Integration

The planned final architecture is:

```text
MySQL Database → Existing SQL Queries → Pandas/Data Layer → Plotly → Streamlit Dashboard
```

MySQL integration is a future phase and is not part of the current dashboard.

## Future Integration

The final architecture will be:

MySQL Database  
→ SQL Queries  
→ Pandas/Data Layer  
→ Plotly  
→ Streamlit Dashboard

Sample/demo values are not real Tesla measurements.
