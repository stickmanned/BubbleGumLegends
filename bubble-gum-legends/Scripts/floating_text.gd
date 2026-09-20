extends Label


func setup(spawn_pos: Vector2) -> void:
	position = spawn_pos - Vector2(15, 20)
	text = "+1"
	add_theme_font_size_override("font_size", 22)
	add_theme_color_override("font_color", Color(1.0, 0.4, 0.7)) # bubblegum pink
	add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	add_theme_constant_override("outline_size", 4)
	
	var tween := create_tween()
	if tween:
		tween.set_parallel(true)
		# Float upward smoothly
		tween.tween_property(self, "position:y", position.y - 50.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Fade out
		tween.tween_property(self, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# Clean up after tween completes
		tween.chain().tween_callback(queue_free)
