params ["_group", "_at", "_rounds"];

_mortar = leader _group;

enableEngineArtillery true;

[_mortar, _at, _rounds] spawn {
	params ["_mortar", "_at", "_rounds"];

	_error = 3; // should be calculated somehow

	for "_i" from 1 to _rounds do {
		_pos = _at getPos [_error, random 360];
		_mortar commandArtilleryFire [_pos, currentMagazine (vehicle _mortar), 1];
		_mortar setVehicleAmmo 1;
		sleep 2;
	};
}