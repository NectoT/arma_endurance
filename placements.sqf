if (!isServer) exitWith {};


// finding player and heli spawn locations
_possible_locations = nearestLocations [
	[8870.47,10208.2],
	["NameCity", "NameVillage", "HistoricalSite", "Airport"],
	1000000
];
StartingLocation = selectRandom _possible_locations;
SpawnLocation = getPos StartingLocation;


// spawning heli
EscapeHeliPos = [SpawnLocation, 10, 500, 6, 0, 0.25] call BIS_fnc_findSafePos;

_marker = createMarker ["heli_marker", EscapeHeliPos];
_marker setMarkerText "Heli";
_marker setMarkerType "hd_end_noShadow";
_marker setMarkerColor "ColorBlue";


// finding evac point
_possible_locations = nearestLocations [
	SpawnLocation,
	["NameCity", "NameCityCapital"],
	1000000
];
EvacPos = getPos ((_possible_locations select { (getPos _x) distance2D SpawnLocation > 2000 }) select 0);
_marker = createMarker ["evac_marker", EvacPos];
_marker setMarkerText "HQ";
_marker setMarkerType "hd_pickup";
_marker setMarkerColor "ColorBlue";


// finding friendly squads locations
FriendlyLocations = nearestLocations [
	SpawnLocation,
	["NameCity", "NameCityCapital", "NameLocal", "NameVillage", "Name", "Area", "Airport"],
	500
] apply { getPos _x } select { _x distance2D SpawnLocation > 200 };

_backup_locations = [0, 0, 0, 0] apply {
	[SpawnLocation, 200, 500, 0, 0, 1, 0] call BIS_fnc_findSafePos
};

FriendlyLocations append _backup_locations;
FriendlyLocations resize (["friendly_squads_amount", 4] call BIS_fnc_getParamValue);

{
	_marker = createMarker ["friendly_marker_" + str _forEachIndex, _x];
	_marker setMarkerType "b_inf";
} forEach FriendlyLocations;


// finding enemy AA positions
_aa_amount = 7;
AAPositions = [];
for "_i" from 1 to _aa_amount do {
	_blacklist = (AAPositions apply { [_x, 400] });
	_blacklist append [[SpawnLocation, 1000], [EvacPos, 500]];

	_pos = [[[EvacPos, 2500]], _blacklist, { (_this distance2D SpawnLocation < 2000) && !(surfaceIsWater _this) }] call BIS_fnc_randomPos;
	if (_pos isEqualTo [0, 0]) then {
		continue;
	};
	_pos = [_pos, 0, 100, 4, 0, 0.4, 0, [], [_pos, _pos]] call BIS_fnc_findSafePos;
	_pos resize 2;

	AAPositions pushBack _pos;
};

// showing only some of them on the map
UnknownAAPositions = AAPositions call BIS_fnc_arrayShuffle;
UnknownAAPositions resize (count AAPositions / 2);
{
	if (_x in UnknownAAPositions) then {
		continue;
	};
	_marker = createMarker ["aa_" + str (random 10000), _x];
	_marker setMarkerType "o_antiair";

} forEach AAPositions;