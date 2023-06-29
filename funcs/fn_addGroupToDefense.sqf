// Adds them to the list of squads to save, also makes the group use chat when in contact with enemy
params ["_group"];
_group addEventHandler ["KnowsAboutChanged", {
	params ["_group", "_targetUnit", "_newKnowsAbout", "_oldKnowsAbout"];

	if (_group getVariable "enemy_contact") exitWith {};

	if (side _targetUnit != east || (vehicle _targetUnit != _targetUnit)) exitWith {};

	[_group] spawn {
		params ["_group"];
		_leader = leader _group;
		sleep 3; // fumbling around
		if (!(alive _leader)) exitWith {};

		_grid = (position _leader) call BIS_fnc_PosToGrid;
		_string = format ["Enemy contact at %1, %2", _grid select 0, _grid select 1];
		["radio_in"] remoteExec ["playSound", -12];
		[_leader, _string] remoteExec ["sideChat", -12];

		_group setVariable ["enemy_contact", true];

		// Doesn't work for some reason
		// (_group) removeAllEventHandlers "KnowsAboutChanged";
	}
}];

{
	_x addEventHandler ["Killed", {
		params ["_unit", "_killer", "_instigator", "_useEffects"];

		if (random 1 > 0.3) exitWith {};

		_string = selectRandom [
			"We're taking losses!",
			"The situation is FUBAR, I repeat, FUBAR!",
			"We're getting pushed",
			"They're pushing us!",
			"We're taking casualties!"
		];
		["radio_in"] remoteExec ["playSound", -12];
		[_unit, _string] remoteExec ["sideChat", -12];
	}];
} forEach (units _group);

FriendlySquadsNum = FriendlySquadsNum + 1;
FriendlySquads pushBack _group;
_group setVariable ["_with_players", false];

// when group is deleted decrement the friendly groups amount
_group addEventHandler ["Empty", {
	params ["_group"];
	FriendlySquadsNum = FriendlySquadsNum - 1;
	FriendlySquads = FriendlySquads select { _x != _group };

	if (!(_group getVariable "_with_players")) then {
		_taskname = 'task_help_' + (groupId _group);
		[_taskname, "FAILED"] remoteExec ["BIS_fnc_taskSetState", -12];
	}
}];