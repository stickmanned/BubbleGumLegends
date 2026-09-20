extends CanvasLayer

@export var bubble: CharacterBody2D

var floating_text_scene: PackedScene = preload("res://floating_text.tscn")

@onready var size_label: Label = %SizeLabel


func _ready() -> void:
	if not bubble:
		# Locate the bubble node via parent lookup or scene group
		if get_parent():
			bubble = get_parent().get_node_or_null("Bubble")
		if not bubble and is_inside_tree() and get_tree():
			bubble = get_tree().get_first_node_in_group("player")

	if bubble:
		if not bubble.size_changed.is_connected(_on_bubble_size_changed):
			bubble.size_changed.connect(_on_bubble_size_changed)
		if not bubble.screen_clicked.is_connected(_on_screen_clicked):
			bubble.screen_clicked.connect(_on_screen_clicked)
		_update_display(bubble.bubble_size)
	else:
		_update_display(1)


func _update_display(size_val: int) -> void:
	if size_label:
		size_label.text = "Bubble Size: %d" % size_val


func _on_bubble_size_changed(new_size: int) -> void:
	_update_display(new_size)


func _on_screen_clicked(click_pos: Vector2) -> void:
	spawn_floating_counter(click_pos)


func spawn_floating_counter(screen_pos: Vector2) -> void:
	if floating_text_scene:
		var float_instance = floating_text_scene.instantiate()
		add_child(float_instance)
		if float_instance.has_method("setup"):
			float_instance.setup(screen_pos)
		else:
			float_instance.position = screen_pos
