_desc = "OPFOR has launched a massive attack on the area. BLUFOR forces are trying to retreat and consolidating at the evac pos.";
_notes = "There are several AA's deployed between you and evac position, BE CAREFUL.";

player createDiaryRecord [
	"Diary",
	["Description", _desc]
];
player createDiaryRecord [
	"Diary",
	["Notes", _notes]
];