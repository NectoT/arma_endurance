params ["_heli_class", "_squad", "_spawn_pos", "_destination"];

_heli = createVehicle [_heli_class, _spawn_pos, [], 20, "FLY"];
_heli flyInHeight 300;
_heli_grp = createVehicleCrew _heli;
_heli_grp setCombatMode "BLUE";
_heli_grp enableAttack false;
TransportHeliAvailable = false;

_group = [_spawn_pos, _squad, east] call END_fnc_spawnSquad;
{
	_x addBackpack "B_Parachute";
} forEach (units _group);
{
	_x moveInCargo _heli;
} forEach (units _group);

(leader _heli_grp) setVariable ["_cargo", units _group];

_heli_wp = _heli_grp addWaypoint [_destination, 200];
_heli_wp setWaypointStatements ["true", "
	{
		unassignVehicle _x;
		moveOut _x;
	} forEach (this getVariable '_cargo');
"];
_heli_wp setWaypointType "MOVE";

_end_pos = vectorLinearConversion [0, 1, 5, _spawn_pos, _destination, false];
_end_pos set [2, 100];

_heli_wp = _heli_grp addWaypoint [_end_pos, 100];
_heli_wp setWaypointStatements ["true", "
	TransportHeliAvailable = true;

	_vehicle = (vehicle this);
	deleteVehicleCrew _vehicle;
	deleteVehicle _vehicle;
"];
_heli_wp setWaypointType "MOVE";

_group_wp = _group addWaypoint [_destination, 10];
_group_wp setWaypointType "SAD";
_group_wp setWaypointBehaviour "COMBAT";


_group;