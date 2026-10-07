"""Load sample query-result CSV files for the dashboard."""

from pathlib import Path

import pandas as pd


SAMPLE_DATA_DIR = Path(__file__).resolve().parents[1] / "data" / "sample"


def _load_sample_csv(filename: str) -> pd.DataFrame:
    return pd.read_csv(SAMPLE_DATA_DIR / filename)


def load_summary_data() -> pd.DataFrame:
    return _load_sample_csv("B1_summary.csv")


def load_road_class_data() -> pd.DataFrame:
    return _load_sample_csv("A1_road_class.csv")


def load_weather_data() -> pd.DataFrame:
    return _load_sample_csv("A2_weather.csv")


def load_speed_limit_data() -> pd.DataFrame:
    return _load_sample_csv("A4_speed_limit.csv")


def load_following_distance_data() -> pd.DataFrame:
    return _load_sample_csv("A5_following_distance.csv")


def load_hard_braking_data() -> pd.DataFrame:
    return _load_sample_csv("A7_hard_braking.csv")


def load_lane_change_data() -> pd.DataFrame:
    return _load_sample_csv("A8_lane_change.csv")


def load_hard_braking_autopilot_data() -> pd.DataFrame:
    return _load_sample_csv("A9_hard_braking_autopilot.csv")


def load_no_autopilot_data() -> pd.DataFrame:
    return _load_sample_csv("A10_no_autopilot.csv")


def load_above_average_braking_data() -> pd.DataFrame:
    return _load_sample_csv("A11_above_average_braking.csv")
