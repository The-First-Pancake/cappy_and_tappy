class_name LoadLevel
extends Button

func load_level() -> void:
	GameManager.load_level_from_packed(GameManager.level_select_scene)
