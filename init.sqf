// markers and placements are set before mission start in 'placements.sqf'

call END_fnc_setBriefing;
call END_fnc_setPlacements;
call END_fnc_setTimeWeather;
sleep 2;

if (!isServer) exitWith {};

SetPath = "";
switch (["set", 1] call BIS_fnc_getParamValue) do
{
	case 1:
	{
		SetPath = "loadoutSets\vanilla.sqf";
	};
	case 2:
	{
		SetPath = "loadoutSets\cup.sqf";
	};
};

_handle = execVM SetPath;
waitUntil { sleep 0.1; scriptDone _handle };

call END_fnc_setGlobalVars;

enableDynamicSimulationSystem true;


// Spawning heli
EscapeHeli = createVehicle [
	EscapeHeliClass,
	EscapeHeliPos,
	[],
	0,
	"NONE"
];
EscapeHeli setHit ["motor", 1];


// spawning players
_player_pos = [[StartingLocation]] call BIS_fnc_randomPos;
{
	_x setVehiclePosition [_player_pos, [], 15, "NONE"];
	_x setUnitTrait ["engineer", true]; // everyone can repair the heli
} forEach (units west);


// dressing up players
if (DifficultyParam > 1) then {
	{
		_magazine_classes = primaryWeaponMagazine _x;
		_unit = _x;
		{
			_unit removeMagazines  _x;
			_unit addMagazineGlobal _x;
		} forEach _magazine_classes;
	} forEach (units west);
};
{
	if (daytime >= 18 || daytime < 6) then {
		_x addPrimaryWeaponItem "acc_flashlight";
	};
} forEach (units west);


// spawn some empty cars
_cars_to_spawn = 3;
if ((["near_car", 1] call BIS_fnc_getParamValue) == 1) then {
	_pos = [[[_player_pos, 20]]] call BIS_fnc_randomPos;
	_pos resize 2;
	if (_pos isEqualTo [0,0]) exitWith {};
	_veh = createVehicle [selectRandom CivCars, _pos, [], 0];
	_veh setDir (random 360);
};
for "VARNAME" from 1 to _cars_to_spawn do {
	_pos = [[[SpawnLocation, 300]], [], {isOnRoad _this }] call BIS_fnc_randomPos;
	_pos resize 2;
	_veh = createVehicle [selectRandom CivCars, _pos, [], 0];
	_veh setDir (random 360);
};


// spawning friendly squads
_squad_names = ["Bravo 1-1", "Bravo 1-2", "Charlie 1-1", "Charlie 1-2"];
{
	// spawning players take a long time, so I decided to make it async so that the loading
	// would be quicker
	_squad_name = _squad_names select _forEachIndex;
	[_x, _squad_name] spawn {
		_composition = selectRandom FriendlyGroupClasses;
		_pos = _this select 0;
		_group = [_pos, _composition, west] call END_fnc_spawnSquad;
		_squad_name = _this select 1;
		_group setGroupIdGlobal [_squad_name];

		[_group] call END_fnc_addGroupToDefense;
	};

} forEach FriendlyLocations;


// spawn friendlies at evac
[] spawn {
	sleep 10;
	for "_i" from 1 to 3 do {
		_pos = [EvacPos, 0, 200, 0, 0, 1, 0] call BIS_fnc_findSafePos;
		_composition = selectRandom FriendlyGroupClasses;
		_group = [_pos, _composition, west] call END_fnc_spawnSquad;
		{
			_x enableDynamicSimulation true;
		} forEach (units _group);
		_wp = _group addWaypoint [_pos, 20];
		_wp setWaypointType "DISMISS";

		sleep 2;
	};
};


// spawning enemy AA
{
	_pos = _x;
	_vehicle = createVehicle [EnemyAAClass, _pos, [], 0, "NONE"];
	createVehicleCrew _vehicle;

	if (count (_pos nearRoads 50) > 0) then {
		_group = [_pos, selectRandom EnemyATGroups, east] call END_fnc_spawnSquad;
		{
			_x enableDynamicSimulation true;
		} forEach (units _group);
		_wp = _group addWaypoint [_pos, 20];
		_wp setWaypointType "DISMISS";
	}
} forEach AAPositions;


[] spawn {
	// introductory radio
	sleep 5;
	["radio_in"] remoteExec ["playSound", -12];
	[[west, "BLU"], "This is HQ to Alpha 1-1, we're retreating to the evacuation point."] remoteExec ["sideChat"];
	sleep 4;
	[
		[west,
		"BLU"],
		"There is a downed heli near your position. We'll send a drone with repairing equipment as soon as we can"
	] remoteExec ["sideChat", -12] ;
	sleep 6;
	[[west, "BLU"], "Try to holdout until that and support nearby squads. Over."] remoteExec ["sideChat", -12];
	["radio_out"] remoteExec ["playSound", -12];

	[west, "task_wait", ["Wait until the drone arrives", "Wait", ""], objNull, "ASSIGNED", 1, true, "wait"] remoteExec ["BIS_fnc_taskCreate", -12];
	["task_wait","wait"] remoteExec ["BIS_fnc_taskSetType", -12];


	// send drone after some time
	sleep ((["waiting_time", 1] call BIS_fnc_getParamValue) * 60);

	["radio_in"] remoteExec ["playSound", -12];
	[[west, "BLU"], "This is HQ to Alpha 1-1, we're sending a drone to heli location, Over."] remoteExec ["sideChat", -12];

	_spawn_pos = [[EvacPos]] call END_fnc_findEnemyHeliSpawnPos;
	_drone = createVehicle [HelperDroneClass, _spawn_pos, [], 20, "FLY"];
	_drone addItemCargoGlobal ["ToolKit", 1];
	_drone setAutonomous true;
	_drone enableUAVWaypoints true;
	_drone allowDamage false;
	_group = createVehicleCrew _drone;

	_destination = [position EscapeHeli, 0, 80, 5, 0, 0.2, 0] call BIS_fnc_findSafePos;
	_helipad = createVehicle ["Land_HelipadEmpty_F", _destination, [], 0, "NONE"];
	[_group, getPosATL _helipad, _helipad] spawn BIS_fnc_wpLand;
	sleep 1;
	_wp = currentWaypoint _group;


	// wait until players get the toolkit and then get the drone out
	waitUntil { sleep 1; _drone distance _helipad < 5 };

	["task_wait", "SUCCEEDED"] remoteExec ["BIS_fnc_taskSetState", -12];
	[
		west,
		"task_get_toolkit",
		["Get to the drone and take the toolkit", "Get the toolkit", ""],
		position _helipad,
		"ASSIGNED",
		1,
		true,
		"container"
	] remoteExec ["BIS_fnc_taskCreate", -12];

	_drone setVariable ["_group", _group];
	{
		_x addEventHandler ["Take", {
			params ["_unit", "_container", "_item"];

			if (_item isEqualTo "ToolKit") then {
				["task_get_toolkit", "SUCCEEDED"] remoteExec ["BIS_fnc_taskSetState", -12];
				_group = _container getVariable "_group";
				deleteVehicleCrew _container;

				_wp = _group addWaypoint [EvacPos, 20];
				_wp setWaypointStatements ["true", "
					_vehicle = vehicle this;
					deleteVehicleCrew _vehicle;
					deleteVehicle _vehicle;
				"];

				{
					_x removeAllEventHandlers "take";
				} forEach (units west);
			};
		}];
	} forEach (units west); // WAS playableUnits BEFORE


	waitUntil { sleep 10; "task_get_toolkit" call BIS_fnc_taskCompleted };


	// draw circle around evac where players can drop off squads
	_evac_radius = 250;
	_m = createMarker ["evac_area", EvacPos];
	_m setMarkerShape "ELLIPSE";
	_m setMarkerSize [_evac_radius, _evac_radius];
	_m setMarkerColor "colorBLUFOR";
	_m setMarkerAlpha 0.3;


	// Tell the players to get other squads
	if (FriendlySquadsNum > 0) then {
		["radio_in"] remoteExec ["playSound", -12];
		[[west, "BLU"], "Alpha 1-1, we need you to evacuate all squads close to you first."] remoteExec ["sideChat", -12];
		sleep 3;
		[[west, "BLU"],  format [
			"We've contacted %1 groups and ordered them to wait for your transport.",
			str FriendlySquadsNum
		]] remoteExec ["sideChat", -12];
		sleep 4;
		[[west, "BLU"], "After that get to evac asap, we don't have much time. Over."] remoteExec ["sideChat", -12];
		["radio_out"] remoteExec ["playSound", -12];

		{
			// create a task for every friendly group still alive
			[
				west,
				"task_help_" + (groupId _x),
				["Transport this squad to safety", "Extract " + (groupId _x), ""],
				position (leader _x),
				"ASSIGNED",
				1,
				true,
				"takeoff"
			] remoteExec ["BIS_fnc_taskCreate", -12];

			// tell them to stay where they are
			_wp = _x addWaypoint [position (leader _x), 10];
			_wp setWaypointType "HOLD";
			_x setCurrentWaypoint _wp;

			// add them to players group when they need to be picked up and leave the group when
			// they arrive
			[_x, _evac_radius] spawn {
				params ["_group", "_evac_radius"];
				waitUntil {
					sleep 1;
					(leader _group) distance EscapeHeli < 100 && (isTouchingGround EscapeHeli) && count (crew EscapeHeli) > 0;
				};
				_taskname = "task_help_" + (groupId _group);
				_heli_group = group (crew EscapeHeli select 0);

				// tell that the group is empty cause it joined players
				_group setVariable ["_with_players", true];
				_units = units _group;
				_units join (group EscapeHeli);

				sleep 0.1;
				deleteGroup _group;
				[_taskname,EvacPos] remoteExec ["BIS_fnc_taskSetDestination", -12];


				waitUntil {
					sleep 1;
					_units_far = false;
					_in_vehicle = false;
					{
						_units_far = (_x distance EvacPos) > _evac_radius;
						_in_vehicle = vehicle _x != _x;
						if (_units_far || _in_vehicle) exitWith {};
					} forEach _units;
					if (!_units_far) then {
						["Units can be dropped off here"] remoteExec ["hint", -12];
					};
					!_units_far && !_in_vehicle && (isTouchingGround EscapeHeli);
				};
				_units join grpNull;
				[_taskname, "SUCCEEDED"] remoteExec ["BIS_fnc_taskSetState", -12];
			}
		} forEach FriendlySquads;

		waitUntil { FriendlySquadsNum == 0 };
	};


	// tell the players to get out themselves
	["radio_in"] remoteExec ["playSound", -12];
	[[west, "BLU"], "HQ To Alpha 1-1, there's no known squads left in your area."] remoteExec ["sideChat", -12];
	sleep 2;
	[[west, "BLU"], "We're waiting for you at the evac position, over."] remoteExec ["sideChat", -12];
	["radio_out"] remoteExec ["playSound", -12];

	[
		west,
		"task_getout",
		["BLUFOR is preparing to leave the island. Get your squad to extraction position", "Get to Evac", ""],
		EvacPos,
		"ASSIGNED",
		1,
		true,
		"move"
	] remoteExec ["BIS_fnc_taskCreate", -12];
	waitUntil {
		sleep 1;
		_units_far = false;
		{
			_units_far = _x distance EvacPos > _evac_radius;
			if (_units_far) exitWith {};
		} forEach playableUnits;
		!_units_far && (isTouchingGround EscapeHeli);
	};
	["task_getout", "SUCCEEDED"] remoteExec ["BIS_fnc_taskSetState", -12];
	["END1", true] remoteExec ["BIS_fnc_endMission", -12];

};


// finding enemy spawn direction
EnemySpawn = nearestLocations [
	SpawnLocation,
	["Name", "NameCity", "Strategic", "NameVillage", "Airport"],
	1500
] apply { getPos _x } select { SpawnLocation distance2D _x > 300 };
// we'll get directions by drawing lines from spawn location to these points
if (count EnemySpawn > 4) then {
	EnemySpawn = EnemySpawn call BIS_fnc_arrayShuffle;
	EnemySpawn resize 4;
};
if (count EnemySpawn == 0 || random 1 > 0.7) then {
	_pos = [SpawnLocation, 500, 1500, 0, 0, 1, 0] call BIS_fnc_findSafePos;
	EnemySpawn pushBack _pos;
};

if (Debug) then {
	{
		_m = createMarker ["debug_enemy_spawn_" + str _forEachIndex, _x];
		_m setMarkerType "o_unknown";
		_m setMarkerText "Enemy Spawn";
	} forEach EnemySpawn;
};


// spawn enemy mortars
_pos = [selectRandom EnemySpawn, 0, 50, 4, 0, 1, 0] call BIS_fnc_findSafePos;
_mortar = createVehicle [EnemyMortarClass, _pos, [], 0, "NONE"];
MortarGroup = createVehicleCrew _mortar;
MortarGroup addEventHandler ["Empty", {
	params ["_group"];
	MortarAvailable = false;
}];
// spawn some backup for it
for "_i" from 1 to 2 do {
	_group = [_pos, selectRandom LightSquads, east] call END_fnc_spawnSquad;
	_group enableDynamicSimulation true;
	_wp = _group addWaypoint [_pos, 20];
	_wp setWaypointType "DISMISS";
};


// in case there will be Zeus playing as a unit I guess
EnemyRadioId radioChannelAdd (units east);


// enemy starting move
[] spawn {
	_starting_move = selectRandomWeighted [
		"planes_bombing", 1,
		"infantry_occupation", 0.3,
		"heli_scouting", 1,
		"paradrop", 0.3
	];

	switch (_starting_move) do {
		case "planes_bombing": {
			sleep 4;
			_spawn_pos = vectorLinearConversion [0, 1, -2, SpawnLocation, EvacPos, false];
			for "VARNAME" from 0 to 1 do {
				_plane = createVehicle [EnemyPlaneClass, _spawn_pos, [], 100, "FLY"];
				_group = createVehicleCrew _plane;
				[_group] call END_fnc_addGroupToOverwatch;
				_fire_pos = vectorLinearConversion [0, 1, 0.7, SpawnLocation, EvacPos];
				_plane setVectorDir (_spawn_pos vectorFromTo _fire_pos);
				_plane setVelocity (_spawn_pos vectorFromTo _fire_pos vectorMultiply 200);
				_wp = _group addWaypoint [_fire_pos, 150];
				_wp setWaypointType "MOVE";
				_wp setWaypointStatements ["true", "
					_plane = vehicle this;
					(driver _plane) forceWeaponFire [EnemyPlaneWeapon, EnemyPlaneMode];
				"];
				_wp = _group addWaypoint [vectorLinearConversion [0, 1, 2, SpawnLocation, EvacPos], 100];
				_wp setWaypointType "MOVE";
				_wp setWaypointStatements ["true", "
					_plane = vehicle this;
					deleteVehicle _plane;
				"];
			};
		};
		case "heli_scouting": {
			sleep 4;
			_starting_point = selectRandom EnemySpawn;
			_spawn_pos = vectorLinearConversion [0, 1, 2, SpawnLocation, _starting_point, false];
			_heli = createVehicle [EnemyReconHeliClass, _spawn_pos, [], 100, "FLY"];
			_group = createVehicleCrew _heli;
			_wp = _group addWaypoint [SpawnLocation, 50];
			_wp setWaypointType "SAD";
			_wp setWaypointTimeout [120, 160, 210];
			_wp2 = _group addWaypoint [_spawn_pos, 100];
			_wp2 setWaypointStatements ["true", "
				_vehicle = (vehicle this);
				deleteVehicleCrew _vehicle;
				deleteVehicle _vehicle;
			"];

			[_group] call END_fnc_addGroupToOverwatch;
		};
		case "paradrop": {
			sleep 4;
			_group = [
				EnemyChuteHeliClass,
				EnemyParatroopers,
				[EnemySpawn] call END_fnc_findEnemyHeliSpawnPos,
				position EscapeHeli
			] call END_fnc_spawnEnemyParatroopers;
			[_group] call END_fnc_addGroupToOverwatch;
			[_group, "light"] call END_fnc_setEnemyGroupType;
			[units _group, 1] call END_fnc_setUnitsValue;
		};
	};
};


// spawn enemy squad near heli if no friendlies are around
if ([position EscapeHeli] call END_fnc_isSafeEnemySpawn) then {
	if (Debug) then {
		hint "Enemies near heli";
	};
	_group = [position EscapeHeli, selectRandom LightSquads, east] call END_fnc_spawnSquad;
	_wp = _group addWaypoint [position EscapeHeli, 20];
	_wp setWaypointType "DISMISS";
	[_group] call END_fnc_addGroupToOverwatch;
	[_group, "light"] call END_fnc_setEnemyGroupType;
	[units _group, 1] call END_fnc_setUnitsValue;
};

// enemy commander ai
[] spawn {
	_baseIdleTime = 2;

	// How much time passed since last iteration. Usually equals to _baseIdleTime. Needs to be
	// set manually
	_deltaTime = 30; 

	while {true} do {
		EnemyPoints = EnemyPoints + (ln Threat) / (ln 2) / 60 * _deltaTime;
		_deltaTime = 0;

		if (!FoundByEnemy) then {
			if (ActiveLightSquads < 4) then {
				if (Debug) then {
					hint('Spawned initial enemy squad');
				};

				_pos = [EnemySpawn] call END_fnc_findEnemySpawnPos;
				_group = [_pos, selectRandom LightSquads, east] call END_fnc_spawnSquad;
				[_group] call END_fnc_addGroupToOverwatch;
				[_group, "light"] call END_fnc_setEnemyGroupType;
				if (ActiveLightSquads == 0) then {
					[_group, position (EscapeHeli)] call END_fnc_attack;
				} else { 
					[_group, selectRandom ([position EscapeHeli] + FriendlyLocations)] call END_fnc_attack;
				};
				
				[units _group, 1] call END_fnc_setUnitsValue;
			};

			_delta_time = 90;
			sleep _delta_time;
			continue;
		};

		// I dunno how that can happen, if enemy found players they also add a spotted position,
		// and after clearing it they add Escape Heli as spotted position in END_fnc_attack,
		// but it happened to me once
		if (count SpottedPositions == 0) then {
			SpottedPositions pushBack (position EscapeHeli);
		};


		// mortar fire
		if ((random 70) < (50 min (Threat - 1)) && EnemyPoints > 3 && MortarAvailable) then {
			_targets = [];
			{
				_targets append (_x targets [true, 200]);
			} forEach (units east);
			_targets = _targets select { _x distance2D (position (leader MortarGroup)) < 1000 };
			if (count _targets > 0) then {
				_fire_pos = position (selectRandom _targets);
				[MortarGroup, _fire_pos, 5] call END_fnc_artilleryFire;

				_grid = _fire_pos call BIS_fnc_PosToGrid;
				_text = format [
					"Incoming shells at %1, %2", _grid select 0, _grid select 1
				];
				[leader MortarGroup, _text] call END_fnc_enemyChat;
			};

			EnemyPoints = EnemyPoints - 3;

			_deltaTime = _baseIdleTime;
			sleep _baseIdleTime;
			continue;
		};

		// paratroopers
		if (random 1 > 0.8 && TransportHeliAvailable && EnemyPoints > 5 && count SpottedPositions > 0) then {
			_destination = selectRandom SpottedPositions;
			_start = [EnemySpawn] call END_fnc_findEnemyHeliSpawnPos;
			_group = [
				EnemyChuteHeliClass,
				EnemyParatroopers,
				_start,
				_destination
			] call END_fnc_spawnEnemyParatroopers;
			[units _group, 1] call END_fnc_setUnitsValue;

			[leader _group, "Heads up, paratroopers are being sent to your location"] call END_fnc_enemyChat;

			EnemyPoints = EnemyPoints - 5;
			
			_deltaTime = _baseIdleTime;
			sleep _baseIdleTime;
			continue;
		};


		// spawn a heli when possible
		if (EnemyPoints > 10 && ActiveHelis < HelisLimit) then {
			_pos = [EnemySpawn] call END_fnc_findEnemyHeliSpawnPos;
			_veh = createVehicle [selectRandom EnemyBattleHelis, _pos, [], 10, "FLY"];
			_group = createVehicleCrew _veh;
			[_group] call END_fnc_addGroupToOverwatch;
			[_group, "heli"] call END_fnc_setEnemyGroupType;
			[units _group, 4] call END_fnc_setUnitsValue;
			[_group, selectRandom SpottedPositions] call END_fnc_attack;

			[leader _group, "To all squads, we're flying over to your location, over."] call END_fnc_enemyChat;

			EnemyPoints = EnemyPoints - 10;
			
			_deltaTime = _baseIdleTime;
			sleep _baseIdleTime;
			continue;
		};


		// spawn a vehicle when possible
		if (EnemyPoints > 8 && ActiveVehicles < VehiclesLimit) then {
			_possible_destinations = SpottedPositions select { count (_x nearRoads 100) > 0 };
			if (Debug) then {
				hint ("vehicle possible destinations " + str _possible_destinations);
			};
			if (count _possible_destinations > 0) then {
				_destination = selectRandom _possible_destinations;
				_pos = [EnemySpawn, position player] call END_fnc_findEnemyVehicleSpawnPos;
				_veh = createVehicle [selectRandom EnemyVehicles, _pos, [], 1, "NONE"];
				_group = createVehicleCrew _veh;

				[_group] call END_fnc_addGroupToOverwatch;
				[_group, "vehicle"] call END_fnc_setEnemyGroupType;
				[units _group, 3] call END_fnc_setUnitsValue;
				[_group, _destination] call END_fnc_attack;

				Threat = 2 max (Threat - 4 / DifficultyParam);
				EnemyPoints = EnemyPoints - 8;
				
				_deltaTime = _baseIdleTime;
				sleep _baseIdleTime;
				continue;
			};
		};


		if (random 1 > 0.2 && EnemyPoints > 5 && ActiveHeavySquads < HeavySquadLimit) then {
			_start = [EnemySpawn] call END_fnc_findEnemySpawnPos;
			_destination = selectRandom SpottedPositions;
			_group = [_start, selectRandom HeavySquads, east] call END_fnc_spawnSquad;

			[_group] call END_fnc_addGroupToOverwatch;
			[_group, "heavy"] call END_fnc_setEnemyGroupType;
			[units _group, 2] call END_fnc_setUnitsValue;
			[_group, _destination] call END_fnc_attack;

			_grid = _destination call BIS_fnc_PosToGrid;
			_text = format [
				"We're moving out to %1, %2, over.", _grid select 0, _grid select 1
			];
			[leader _group, _text] call END_fnc_enemyChat;

			Threat = 2 max (Threat - 8 / DifficultyParam);
			EnemyPoints = EnemyPoints - 5;

			_deltaTime = _baseIdleTime;
			sleep _baseIdleTime;
			continue;
		};
		if (random 1 > 0.3 && EnemyPoints > 3 && ActiveLightSquads < LightSquadLimit) then {
			_start = [EnemySpawn] call END_fnc_findEnemySpawnPos;
			_destination = selectRandom SpottedPositions;
			_group = [_start, selectRandom LightSquads, east] call END_fnc_spawnSquad;

			[_group] call END_fnc_addGroupToOverwatch;
			[_group, "light"] call END_fnc_setEnemyGroupType;
			[units _group, 2] call END_fnc_setUnitsValue;
			[_group, _destination] call END_fnc_attack;

			_grid = _destination call BIS_fnc_PosToGrid;
			_text = format [
				"We're moving out to %1, %2, over.", _grid select 0, _grid select 1
			];
			[leader _group, _text] call END_fnc_enemyChat;

			Threat = 2 max (Threat - 4 / DifficultyParam);
			EnemyPoints = EnemyPoints - 3;

			_deltaTime = _baseIdleTime;
			sleep _baseIdleTime;
			continue;
		};

		_deltaTime = _baseIdleTime;
		sleep _baseIdleTime;
	};
};

// BUGS:
// drone not getting away after he served its purpose
// way too foggy every time - fixed by having an option to turn random fog on
// enemies can spawn in containers
// friendlies don't leave the squad after landing - couldn't replicate