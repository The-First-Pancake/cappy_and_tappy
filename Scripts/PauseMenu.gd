extends MarginContainer



func unpause() -> void:
	GameManager.toggle_pause(false)

func main_menu() -> void:
	GameManager.load_level_from_packed(GameManager.level_select_scene)
	GameManager.toggle_pause(false)

func restart_level() -> void:
	GameManager.restart_level()
	GameManager.toggle_pause(false)
