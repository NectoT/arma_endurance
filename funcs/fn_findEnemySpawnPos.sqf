params ["_points"];

_point = selectRandom _points;
_direction = SpawnLocation vectorFromTo _point;

_distance = 300;
_pos = SpawnLocation vectorAdd (_direction vectorMultiply _distance);
while { _distance < 2000 } do {

	if (([_pos] call END_fnc_isSafeEnemySpawn) && !(surfaceIsWater _pos)) exitWith {};

	_distance = _distance + 100;
	_pos = SpawnLocation vectorAdd (_direction vectorMultiply _distance);
};

if ((surfaceIsWater _pos)) then {
	pos = objNull;
};

_pos;