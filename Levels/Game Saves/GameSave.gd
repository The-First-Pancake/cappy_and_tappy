class_name GameSave
extends Resource

@export var levels_complete: Array[LevelCompleteData] = []
@export var endless_high_height: int = 0
@export var endless_high_idols: int = 0
@export var setting_music_mute: bool = false
@export var setting_sounds_mute: bool = false


func is_level_complete(level: PackedScene) -> bool:
	for level_data: LevelCompleteData in levels_complete:
		if level_data.level == level:
			return true
	return false

func how_many_idols(level: PackedScene) -> int:
	for level_data: LevelCompleteData in levels_complete:
		if level_data.level == level:
			return level_data.idols
	return 0
	
func complete_level(level: PackedScene, idols: int) -> void:
	for level_data: LevelCompleteData in levels_complete:
		if level_data.level == level:
			level_data.idols = max(level_data.idols, idols)
			return
	
	var new_level_data: LevelCompleteData = LevelCompleteData.new()
	new_level_data.level = level
	new_level_data.idols = idols
	
	levels_complete.append(new_level_data)
