## Relational Schema (Inital)


DRIVE(
TestNo PK,
Route,
GapSetting
)
TELEMETRY_SAMPLE(
TestNo PK, FK,
TimeAbs PK,
RoadClass,
Speed,
AutopilotState,
RainyFlag
)
DETECTION(
TrackID PK,
TestNo FK,
TimeAbs FK,
DistanceX,
DistanceY
)
RADAR_DETECTION(
TrackID PK, FK,
LongVelocity,
LatVelocity,
Acceleration
)
LIDAR_DETECTION(
TrackID PK, FK,
LaneSide,
Placement
)