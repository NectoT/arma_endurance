params ['_pos'];

_intel = createVehicle ["Land_Map_unfolded_Tanoa_F", _pos, [], 0.05, "NONE"];
_icon = "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_search_ca.paa";
[_intel, "Pick up intel", _icon, _icon, "true", "true", {}, {}, {
	params ["_target", "_caller", "_actionId", "_arguments"];

	if (!MortarFound && random 1 > 0.5) exitWith {
		MortarFound = true;

		_marker = createMarker ["mortar_pos", position (leader MortarGroup)];
		_marker setMarkerType "o_mortar";
		_marker setMarkerText "Mortar";
	};

	if (count UnknownAAPositions == 0) exitWith {};

	FirstAAIntelFound = true;

	_new_pos = UnknownAAPositions deleteAt 0;
	_marker = createMarker ["aa_" + str (random 10000), _new_pos];
	_marker setMarkerType "o_antiair";

	deleteVehicle _target;
	if (count UnknownAAPositions == 0) then {
		["aa_intel", "SUCCEEDED"] remoteExec ["BIS_fnc_taskSetState", -12];
	}
}, {}, [], 1] call BIS_fnc_holdActionAdd;