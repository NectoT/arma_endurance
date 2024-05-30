Debug = false;

DifficultyParam = ["difficulty", 1] call BIS_fnc_getParamValue;

FriendlySquads = [];
FriendlySquadsNum = 0;

SpottedPositions = [];
FoundByEnemy = false;

Threat = 2;
EnemyPoints = 1;

FirstAAIntelFound = false;
MortarFound = false;

LightSquadLimit = 7;
HeavySquadLimit = 2;
VehiclesLimit = 2;
HelisLimit = 1;

ActiveLightSquads = 0;
ActiveHeavySquads = 0;
ActiveVehicles = 0;
ActiveHelis = 0;

MortarAvailable = true;
TransportHeliAvailable = true;

RadioFound = false;
EnemyRadioId = radioChannelCreate [[0.8, 0, 0, 1], "OPFOR", "%UNIT_GRP_NAME", []];