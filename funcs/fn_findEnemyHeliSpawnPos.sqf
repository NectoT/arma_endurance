params ["_points"];

_point = selectRandom _points;
_direction = SpawnLocation vectorFromTo _point;

_distance = 1000;
_pos = SpawnLocation vectorAdd (_direction vectorMultiply _distance);
while { true } do {

	if ([_pos] call END_fnc_isSafeEnemySpawn) exitWith {};

	_distance = _distance + 100;
	_pos = SpawnLocation vectorAdd (_direction vectorMultiply _distance);
	sleep 0.1;
};

_pos;