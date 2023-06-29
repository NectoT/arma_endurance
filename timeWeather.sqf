RainMaxIntensity = 1;
FogMaxIntensity = 0.4;
FogUsualIntesity = 0.2;
TimeMin = 2; // in hours
TimeMax = 23;

_time = ["time", 14] call BIS_fnc_getParamValue;
if (_time == -1) then {
	_time = floor(TimeMin + random (TimeMax - TimeMin));
};

[[2021, 9, 22, _time, floor(random 60)]] remoteExec ["setDate"];
_rain_value = random RainMaxIntensity;
[0, _rain_value] remoteExec ["setOvercast"];
if ((["fog", 1] call BIS_fnc_getParamValue) == 1) then {
	[0, random [0, FogUsualIntesity, FogMaxIntensity]] remoteExec ["setFog"];
};
forceWeatherChange;
[] remoteExec ["forceWeatherChange"];