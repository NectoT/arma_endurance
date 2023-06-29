params ["_group", "_type"];

switch (_type) do {
	case "light": {
		ActiveLightSquads = ActiveLightSquads + 1;
		_group addEventHandler ["Empty", {
			params ["_group"];
			ActiveLightSquads = ActiveLightSquads - 1;
		}];
	};
	case "heavy": {
		ActiveHeavySquads = ActiveHeavySquads + 1;
		_group addEventHandler ["Empty", {
			params ["_group"];
			ActiveHeavySquads = ActiveHeavySquads - 1;
		}];
	};
	case "vehicle": {
		ActiveVehicles = ActiveVehicles + 1;
		_group addEventHandler ["Empty", {
			params ["_group"];
			ActiveVehicles = ActiveVehicles - 1;
		}];
	};
	case "heli": {
		ActiveHelis = ActiveHelis + 1;
		_group addEventHandler ["Empty", {
			params ["_group"];
			ActiveHelis = ActiveHelis - 1;
		}];
	};
};