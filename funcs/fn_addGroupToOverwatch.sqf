params ["_group"];

_group addEventHandler ["EnemyDetected", {
	params ["_group", "_targetUnit"];
	_enemy_pos = position _targetUnit;
	_leader = leader _group;

	[_leader, _enemy_pos] spawn {
		params ["_leader", "_enemy_pos"];

		sleep 8; // fumbling around
		if (!(alive _leader)) exitWith {};

		FoundByEnemy = true;

		// check if there are no nearby reported positions
		if (count (SpottedPositions select { _x distance2D _enemy_pos < 200 }) == 0) then {
			SpottedPositions pushback _enemy_pos;
			// report about it in chat
			_grid = _enemy_pos call BIS_fnc_PosToGrid;
			_string = format ["Enemy found at %1 , %2", _grid select 0, _grid select 1];
			[_leader, [EnemyRadioId, _string]] remoteExec ["customChat", -12];
		};
	};
}];