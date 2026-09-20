extends AudioStreamPlayer
## Background music player that loops audio continuously.

func _ready() -> void:
	# Ensure the audio stream loops on repeat
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true

	if not finished.is_connected(_on_finished):
		finished.connect(_on_finished)

	if not playing:
		play()


func _on_finished() -> void:
	play()
