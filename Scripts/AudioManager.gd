extends Node

func _ready() -> void:
	AudioServer.set_bus_mute(0,GameManager.current_save.setting_mute)
	GameManager.loading_new_scene.connect(clear_looping_sounds)
	GameManager.game_paused.connect(stop_controller_rumble)

func _process(delta: float) -> void:
	var haptics_mag : float = db_to_linear(AudioServer.get_bus_peak_volume_left_db(AudioServer.get_bus_index("Haptics"), 0))
	if (haptics_mag > 0.01):
		for i in Input.get_connected_joypads():
			Input.start_joy_vibration(i, haptics_mag, haptics_mag)
	else:
		for i in Input.get_connected_joypads():
			Input.stop_joy_vibration(i)

func stop_controller_rumble() -> void:
	for i in Input.get_connected_joypads():
			Input.stop_joy_vibration(i)

func toggle_mute() -> void:
	GameManager.current_save.setting_mute = !GameManager.current_save.setting_mute
	GameManager.save_game()
	AudioServer.set_bus_mute(0,GameManager.current_save.setting_mute)

func clear_all_sounds() -> void:
	for child: Node in get_children():
		if child != current_music:
			child.queue_free()
			
func clear_looping_sounds() -> void:
	for child: Node in get_children():
		if child != current_music and child is AudioStreamPlayer:
			if is_instance_valid(child):
				var stream : AudioStreamWAV = child.stream as AudioStreamWAV
				if is_instance_valid(stream) and stream.loop_mode == AudioStreamWAV.LoopMode.LOOP_FORWARD:
					child.queue_free()
				

func PlayAudio(audio: AudioStreamPlayer, is_haptics: bool = true) -> AudioStreamPlayer:
	var audio_dupe: AudioStreamPlayer = audio.duplicate()
	add_child(audio_dupe)
	if is_haptics:
		audio_dupe.bus = "Haptics"
	audio_dupe.play()
	
	audio_dupe.finished.connect(func() -> void:
		audio_dupe.queue_free()
	)

	return audio_dupe

var current_music: AudioStreamPlayer = null

func PlayMusic(audio: AudioStreamPlayer) -> void:
	if current_music:
		if current_music.stream == audio.stream: return
		current_music.stop()
	var audio_dupe: AudioStreamPlayer = audio.duplicate()
	add_child(audio_dupe)
	audio_dupe.play()
	current_music = audio_dupe
	audio_dupe.finished.connect(func() -> void:
		audio_dupe.queue_free()
	)
