extends Node

@onready var trailer_timer : Timer = $"Trailer Timer"
@onready var gameplay_trailer : VideoStreamPlayer = $"Demo Reel Canvas/VideoStreamPlayer"
@onready var title_music : AudioStreamPlayer = %Music
@onready var blackout: CanvasModulate = $"Fade To Black Canvas/CanvasModulate"
@onready var animation_player:AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.is_in_menu = true
	AudioManager.PlayMusic(title_music)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_trailer_timer_timeout() -> void:
	animation_player.play("fade_to_black")
	await animation_player.animation_finished
	AudioManager.current_music.stop()
	gameplay_trailer.play()

func _input(event: InputEvent) -> void:
	if !event.is_pressed(): return #only care about button presses
	blackout.color = Color(0,0,0,0)
	animation_player.stop()
	
	if gameplay_trailer.is_playing():
		gameplay_trailer.stop()
	
	if AudioManager.current_music.playing == false:
		AudioManager.current_music.play()
	
	trailer_timer.start()
	
