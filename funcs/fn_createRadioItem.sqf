// creates an item that can be interacted with. After the interaction players will get
// access to enemy chat messages
params ['_pos'];

_radio = createVehicle ["Item_ItemRadio", _pos, [], 0.05, "NONE"];
_icon = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa";
[_radio, "Pick up radio", _icon, _icon, "true", "true", {}, {}, {
	params ["_target", "_caller", "_actionId", "_arguments"];

	RadioFound = true;

	EnemyRadioId radioChannelAdd (units west);
	[
		west,
		"radio_found",
		["Get the radio to intercept enemy comms", "Find a two-way enemy radio", ""],
		objNull,
		"SUCCEEDED",
		1,
		true,
		"radio"
	] remoteExec ["BIS_fnc_taskCreate", -12];
	deleteVehicle _target;
}, {}, [], 1] call BIS_fnc_holdActionAdd;