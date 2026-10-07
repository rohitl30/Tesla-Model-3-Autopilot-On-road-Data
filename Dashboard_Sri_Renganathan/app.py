import streamlit as st

from src.charts import (
    TRAFFIC_LABELS,
    create_above_average_braking_chart,
    create_autopilot_by_road_chart,
    create_autopilot_by_weather_chart,
    create_following_distance_chart,
    create_hard_braking_autopilot_table,
    create_hard_braking_chart,
    create_lane_change_chart,
    create_no_autopilot_table,
    create_speed_limit_chart,
)
from src.data_loader import (
    load_above_average_braking_data,
    load_following_distance_data,
    load_hard_braking_autopilot_data,
    load_hard_braking_data,
    load_lane_change_data,
    load_no_autopilot_data,
    load_road_class_data,
    load_speed_limit_data,
    load_summary_data,
    load_weather_data,
)


st.set_page_config(page_title="Tesla Model 3 Autopilot Performance", layout="wide")


@st.cache_data
def load_dashboard_data():
    return {
        "summary": load_summary_data(),
        "road_class": load_road_class_data(),
        "weather": load_weather_data(),
        "speed_limit": load_speed_limit_data(),
        "following_distance": load_following_distance_data(),
        "hard_braking": load_hard_braking_data(),
        "lane_change": load_lane_change_data(),
        "hard_braking_autopilot": load_hard_braking_autopilot_data(),
        "no_autopilot": load_no_autopilot_data(),
        "above_average_braking": load_above_average_braking_data(),
    }


def weather_condition(row) -> str:
    if row["rainy"] and row["snowy"]:
        return "Rainy + Snowy"
    if row["rainy"]:
        return "Rainy"
    if row["snowy"]:
        return "Snowy"
    return "Clear"


def filter_data(data):
    filters = st.sidebar
    filters.header("Dashboard Filters")
    filters.caption("Each filter affects only compatible query-result charts.")

    road_choice = filters.selectbox("Road class", ["All", *data["road_class"]["road_class"].tolist()])
    weather_choice = filters.selectbox("Weather", ["All", "Clear", "Rainy", "Snowy", "Rainy + Snowy"])
    speed_choice = filters.selectbox("Speed limit", ["All", *data["speed_limit"]["speed_limit"].tolist()])

    traffic_values = list(data["following_distance"]["traffic_level"].drop_duplicates())
    hard_traffic_values = data["hard_braking"]["traffic_level"].map(lambda value: TRAFFIC_LABELS.get(value, value)).drop_duplicates().tolist()
    traffic_options = ["All", *dict.fromkeys([*traffic_values, *hard_traffic_values])]
    traffic_choice = filters.selectbox("Traffic level", traffic_options)

    follow_values = sorted(data["following_distance"]["follow_setting"].astype(str).unique(), key=int)
    follow_choice = filters.selectbox("Follow setting", ["All", *follow_values])
    driving_choice = filters.selectbox("Driving mode", ["All", *data["hard_braking"]["driving_mode"].drop_duplicates().tolist()])

    road = data["road_class"] if road_choice == "All" else data["road_class"].query("road_class == @road_choice")

    weather = data["weather"].copy()
    weather["_condition"] = weather.apply(weather_condition, axis=1)
    if weather_choice != "All":
        weather = weather[weather["_condition"] == weather_choice]

    speed = data["speed_limit"] if speed_choice == "All" else data["speed_limit"].query("speed_limit == @speed_choice")

    following = data["following_distance"]
    if traffic_choice != "All":
        following = following[following["traffic_level"] == traffic_choice]
    if follow_choice != "All":
        following = following[following["follow_setting"].astype(str) == follow_choice]

    hard = data["hard_braking"]
    hard_display_traffic = hard["traffic_level"].map(lambda value: TRAFFIC_LABELS.get(value, value))
    if traffic_choice != "All":
        hard = hard[hard_display_traffic == traffic_choice]
    if driving_choice != "All":
        hard = hard[hard["driving_mode"] == driving_choice]

    filters.caption("Road class applies to the road chart; weather to the weather chart; speed limit to the speed chart; traffic to following-distance and braking charts; follow setting to following distance; driving mode to braking.")
    return road, weather, speed, following, hard


st.title("Tesla Model 3 Autopilot Performance Dashboard")
st.subheader("Analysis of Autopilot behavior across road, traffic, speed, and weather conditions")
st.warning("Demo Dashboard — Sample Data")
st.caption("The current dashboard uses sample/demo query-result data for development and visualization. These values are not real Tesla measurements. The data source will be replaced with MySQL query results in the final integration.")

try:
    data = load_dashboard_data()
    road, weather, speed, following, hard = filter_data(data)
except FileNotFoundError as exc:
    st.error(f"A required sample data file could not be found: {exc.filename}")
    st.stop()
except (OSError, ValueError) as exc:
    st.error(f"A sample data file could not be loaded: {exc}")
    st.stop()

summary = data["summary"].iloc[0]
kpi_columns = st.columns(4)
kpi_columns[0].metric("Total Drives", f"{summary['total_drives']:,.0f}")
kpi_columns[1].metric("Total Miles", f"{summary['total_miles']:,.1f}")
kpi_columns[2].metric("Total Hours", f"{summary['total_hours']:,.1f}")
kpi_columns[3].metric("Average Speed", f"{summary['avg_speed_mph']:,.1f} mph")

st.divider()
st.header("Autopilot Engagement")
st.plotly_chart(create_autopilot_by_road_chart(road), use_container_width=True)
st.plotly_chart(create_autopilot_by_weather_chart(weather), use_container_width=True)

st.header("Speed & Following Behavior")
st.plotly_chart(create_speed_limit_chart(speed), use_container_width=True)
st.plotly_chart(create_following_distance_chart(following), use_container_width=True)

st.header("Braking & Safety-Related Behavior")
st.plotly_chart(create_hard_braking_chart(hard), use_container_width=True)
st.plotly_chart(create_hard_braking_autopilot_table(data["hard_braking_autopilot"]), use_container_width=True)
st.plotly_chart(create_above_average_braking_chart(data["above_average_braking"]), use_container_width=True)

st.header("Lane & Autopilot Activity")
st.plotly_chart(create_lane_change_chart(data["lane_change"]), use_container_width=True)
st.plotly_chart(create_no_autopilot_table(data["no_autopilot"]), use_container_width=True)

st.header("Key Observations")
st.caption("Illustrative observations from the current sample/demo data:")
highest_road = data["road_class"].loc[data["road_class"]["active_percent"].idxmax()]
highest_weather = data["weather"].loc[data["weather"]["active_percent"].idxmax()]
highest_braking = data["hard_braking"].loc[data["hard_braking"]["hard_brakes_per_1000"].idxmax()]
mean_by_setting = data["following_distance"].groupby("follow_setting")["avg_control_distance_m"].mean()
st.markdown(
    f"- Within the sample data, **{highest_road['road_class']}** has the highest Autopilot active percentage at **{highest_road['active_percent']:.2f}%**.\n"
    f"- The highest sample Autopilot active percentage appears under **{weather_condition(highest_weather)}** conditions at **{highest_weather['active_percent']:.2f}%**.\n"
    f"- Sample average control distance increases from **{mean_by_setting.min():.1f} m** at the lowest represented follow setting to **{mean_by_setting.max():.1f} m** at the highest.\n"
    f"- The highest sample hard-braking rate is **{highest_braking['hard_brakes_per_1000']:.2f} per 1,000** for **{TRAFFIC_LABELS.get(highest_braking['traffic_level'], highest_braking['traffic_level'])} / {highest_braking['driving_mode']}**."
)
st.caption("These are illustrative associations in sample/demo data, not causal or real-world Tesla safety conclusions.")
st.divider()
st.caption("Current data source: Sample/Demo Query Results")
