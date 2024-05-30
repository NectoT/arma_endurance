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