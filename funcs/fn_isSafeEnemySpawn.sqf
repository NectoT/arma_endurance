params ["_pos"];

_visible_by_players = false;
{
	_visible_by_players = ([objNull, "VIEW"] checkVisibility [eyePos _x, _pos]) > 0.1;
	if (_visible_by_players) exitWith {};
} forEach playableUnits;
_near_blu = count (_pos nearEntities ["Man", 250] select { side _x == west }) != 0;

!_visible_by_players && !_near_blu;