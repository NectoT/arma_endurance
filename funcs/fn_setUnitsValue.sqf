params ["_units", "_value"];

{
	_x setVariable ["_value", _value];
	_x addEventHandler ["Killed", {
		params ["_unit", "_killer", "_instigator", "_useEffects"];
		Threat = Threat + (_unit getVariable "_value");

		// I know it's strange to add item drop to a function dedicated to setting unit value
		if (!RadioFound) then {
			[position _unit] call END_fnc_createRadioItem;
		};
		if ((count UnknownAAPositions > 0 || !MortarFound) && random 1 < 0.2) then {
			[position _unit] call END_fnc_createIntel;
		}

	}];
} forEach _units;