"""Reusable Plotly charts for the midterm dashboard."""

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go


CHART_HEIGHT = 420
TRAFFIC_LABELS = {
    "0 vehicles": "0 vehicles (Empty)",
    "1-2 vehicles": "1-2 vehicles (Light/Mod)",
    "3+ vehicles": "3+ vehicles (Heavy)",
}


def _apply_layout(fig: go.Figure) -> go.Figure:
    fig.update_layout(height=CHART_HEIGHT, margin={"l": 20, "r": 20, "t": 70, "b": 20}, legend_title_text="", hovermode="closest")
    return fig


def create_autopilot_by_road_chart(df: pd.DataFrame) -> go.Figure:
    fig = px.bar(df, x="road_class", y="active_percent", text="active_percent", title="Autopilot Usage by Road Class", labels={"road_class": "Road Class", "active_percent": "Active Autopilot (%)"}, hover_data={"state_samples": True, "active_samples": True, "active_percent": ":.2f"})
    fig.update_traces(texttemplate="%{text:.2f}%", textposition="outside")
    fig.update_yaxes(range=[0, 100])
    return _apply_layout(fig)


def create_autopilot_by_weather_chart(df: pd.DataFrame) -> go.Figure:
    chart_df = df.copy()
    chart_df["weather_condition"] = chart_df.apply(lambda row: "Rainy + Snowy" if row["rainy"] and row["snowy"] else "Rainy" if row["rainy"] else "Snowy" if row["snowy"] else "Clear", axis=1)
    fig = px.bar(chart_df, x="weather_condition", y="active_percent", text="active_percent", title="Autopilot Usage by Weather", labels={"weather_condition": "Weather Condition", "active_percent": "Active Autopilot (%)"}, color="weather_condition", hover_data={"sample_count": True, "avg_speed_mph": ":.1f", "active_percent": ":.2f"})
    fig.update_traces(texttemplate="%{text:.2f}%", textposition="outside")
    fig.update_yaxes(range=[0, 100])
    return _apply_layout(fig)


def create_speed_limit_chart(df: pd.DataFrame) -> go.Figure:
    chart_df = df.melt(id_vars="speed_limit", value_vars=["avg_set_speed_mph", "avg_actual_speed_mph"], var_name="speed_measure", value_name="speed_mph")
    chart_df["speed_measure"] = chart_df["speed_measure"].map({"avg_set_speed_mph": "Average Set Speed", "avg_actual_speed_mph": "Average Actual Speed"})
    fig = px.line(chart_df, x="speed_limit", y="speed_mph", color="speed_measure", markers=True, title="Set Speed vs Actual Speed by Speed Limit", labels={"speed_limit": "Speed Limit", "speed_mph": "Speed (mph)", "speed_measure": "Measure"}, hover_data={"speed_mph": ":.1f"})
    return _apply_layout(fig)


def create_following_distance_chart(df: pd.DataFrame) -> go.Figure:
    chart_df = df.copy()
    chart_df["follow_setting"] = chart_df["follow_setting"].astype(str)
    fig = px.bar(chart_df, x="traffic_level", y="avg_control_distance_m", color="follow_setting", barmode="group", category_orders={"follow_setting": ["1", "2", "3", "4"]}, title="Following Distance by Traffic Level and Follow Setting", labels={"traffic_level": "Traffic Level", "avg_control_distance_m": "Average Control Distance (m)", "follow_setting": "Follow Setting"}, hover_data={"sample_count": True, "avg_control_distance_m": ":.1f"})
    fig.update_layout(barmode="group")
    return _apply_layout(fig)


def create_hard_braking_chart(df: pd.DataFrame) -> go.Figure:
    chart_df = df.copy()
    chart_df["traffic_level"] = chart_df["traffic_level"].replace(TRAFFIC_LABELS)
    fig = px.bar(chart_df, x="traffic_level", y="hard_brakes_per_1000", color="driving_mode", barmode="group", title="Hard Braking Rate by Traffic Level and Driving Mode", labels={"traffic_level": "Traffic Level", "hard_brakes_per_1000": "Hard Brakes per 1,000 Samples", "driving_mode": "Driving Mode"}, hover_data={"sample_count": True, "hard_brake_samples": True, "hard_brakes_per_1000": ":.2f"})
    return _apply_layout(fig)


def create_lane_change_chart(df: pd.DataFrame) -> go.Figure:
    fig = px.bar(df, x="road_class", y="sample_count", color="lane_change_state", barmode="group", title="Lane-Change Activity by Road Class", labels={"road_class": "Road Class", "sample_count": "Sample Count", "lane_change_state": "Lane-Change State"}, hover_data={"sample_count": True})
    return _apply_layout(fig)


def _create_drive_table(df: pd.DataFrame, title: str) -> go.Figure:
    headers = list(df.columns)
    fig = go.Figure(data=[go.Table(header={"values": headers}, cells={"values": [df[column].tolist() for column in headers]})])
    fig.update_layout(title=title, height=max(260, min(520, 100 + len(df) * 45)), margin={"l": 10, "r": 10, "t": 60, "b": 10})
    return fig


def create_hard_braking_autopilot_table(df: pd.DataFrame) -> go.Figure:
    return _create_drive_table(df, "Hard Braking While Autopilot Is Active")


def create_no_autopilot_table(df: pd.DataFrame) -> go.Figure:
    return _create_drive_table(df, "Drives With No Active Autopilot Samples")


def create_above_average_braking_chart(df: pd.DataFrame) -> go.Figure:
    fig = px.bar(df, x="drive_id", y="hard_brakes_per_1000", color="route", title="Drives With Above-Average Hard-Braking Rates", labels={"drive_id": "Drive ID", "hard_brakes_per_1000": "Hard Brakes per 1,000 Samples", "route": "Route"}, hover_data={"route": True, "sample_count": True, "hard_brake_samples": True, "hard_brakes_per_1000": ":.2f"})
    return _apply_layout(fig)
