params ["_group", "_text"];

EnemyRadioId radioChannelAdd (units _group);
[leader _group, [EnemyRadioId, _text]] remoteExec ["customChat", -12];