params ["_group", "_attack_pos"];

_is_heli = vehicle (leader _group) isKindOf "Helicopter";
_radius = 15;
if (_is_heli) then { radius = 100; };

_wp = _group addWaypoint [_attack_pos, _radius];
_wp setWaypointType "SAD";
// if (FoundByEnemy) then {
// 	_wp setWaypointBehaviour "AWARE";
// } else {
// 	_wp setWaypointBehaviour "SAFE";
// };

[_wp] spawn {
	params ["_wp"];
	_wp setWaypointStatements ["true", "
		[position this] call END_fnc_deleteNearbySpottedPositions;
		if (count SpottedPositions == 0) then {
			SpottedPositions pushback (position EscapeHeli);
		};
		_next_stop = selectRandom SpottedPostions;
		[group this, _next_stop] call END_fnc_attack;
	"];
};

_wp;