params ["_pos", "_composition", "_side"];
_group = createGroup _side;
{
	_unit = _group createUnit [_x, _pos, [], 10, "NONE"];
	if (daytime >= 18 || daytime < 6) then {
		_unit addPrimaryWeaponItem "acc_flashlight";
	};
} forEach _composition;
_group;