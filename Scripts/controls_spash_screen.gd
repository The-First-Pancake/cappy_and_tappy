extends Control

@onready var fade_out_rect: ColorRect = $"Fade Out Rect"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade_out_rect.modulate = Color.WHITE
	var tween: Tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(fade_out_rect,"modulate",Color.TRANSPARENT,1.5)
	await tween.finished
	
	await get_tree().create_timer(3.5).timeout
	
	var tween2: Tween = get_tree().create_tween()
	tween2.set_trans(Tween.TRANS_QUAD)
	tween2.tween_property(fade_out_rect,"modulate",Color.WHITE,1.5)
	await tween2.finished
	
	GameManager.load_level_from_packed(GameManager.splash_screen_scene)


func _input(event: InputEvent) -> void:
	if event.is_pressed():
		GameManager.load_level_from_packed(GameManager.splash_screen_scene)
