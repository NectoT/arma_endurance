params ["_pos"];

SpottedPostitions = SpottedPositions select { _pos distance2D _x > 200 };