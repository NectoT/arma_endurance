params ["_points", "_destination"];

_possible_spawns = [];
{
	_positions = _x nearRoads 100 apply {getPos _x};
	_positions = _positions select { [_x] call END_fnc_isSafeEnemySpawn };
	_possible_spawns append _positions;
} forEach _points;

_pos = objNull;
if (count _possible_spawns == 0) then {
	_possible_spawns = (_destination nearRoads 1500) select {
		[_x] call END_fnc_isSafeEnemySpawn && _destination distance2D _x > 700;
	};
};
if (count _possible_spawns > 0) then {
	_pos = selectRandom _possible_spawns;
};

_pos;