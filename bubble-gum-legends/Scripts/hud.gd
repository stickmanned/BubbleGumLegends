extends CanvasLayer

@export var bubble: CharacterBody2D

@export_group("Altitude Meter")
@export var ground_y: float = 165.0
@export var pixels_per_meter: float = 50.0
@export var max_altitude_display: float = 1000

var floating_text_scene: PackedScene = preload("res://floating_text.tscn")

@onready var size_label: Label = %SizeLabel
@onready var altitude_label: Label = %AltitudeLabel
@onready var altitude_bar: ProgressBar = %AltitudeBar

var _bar_fill_style: StyleBoxFlat


func _ready() -> void:
	_init_bar_style()
	_locate_and_connect_bubble()


func _init_bar_style() -> void:
	if altitude_bar:
		var existing_style := altitude_bar.get_theme_stylebox("fill")
		if existing_style is StyleBoxFlat:
			_bar_fill_style = existing_style.duplicate() as StyleBoxFlat
		else:
			_bar_fill_style = StyleBoxFlat.new()
			_bar_fill_style.corner_radius_top_left = 4
			_bar_fill_style.corner_radius_top_right = 4
			_bar_fill_style.corner_radius_bottom_right = 4
			_bar_fill_style.corner_radius_bottom_left = 4
		altitude_bar.add_theme_stylebox_override("fill", _bar_fill_style)


func _locate_and_connect_bubble() -> void:
	if not bubble:
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


func _process(_delta: float) -> void:
	if not bubble:
		_locate_and_connect_bubble()
		if not bubble:
			return

	var altitude_m := maxf(0.0, (ground_y - bubble.global_position.y) / pixels_per_meter)

	if altitude_label:
		altitude_label.text = "Altitude: %d m" % int(round(altitude_m))

	if altitude_bar:
		altitude_bar.value = altitude_m

		var ratio := clampf(altitude_m / max_altitude_display, 0.0, 1.0)
		var bar_color: Color
		if ratio < 0.5:
			# Green to Yellow
			bar_color = Color(0.2, 0.85, 0.3).lerp(Color(0.95, 0.85, 0.15), ratio * 2.0)
		else:
			# Yellow to Red
			bar_color = Color(0.95, 0.85, 0.15).lerp(Color(0.95, 0.25, 0.25), (ratio - 0.5) * 2.0)

		if _bar_fill_style:
			_bar_fill_style.bg_color = bar_color


func _update_display(size_val: int) -> void:
	if size_label:
		size_label.text = "Bubble Size: %d" % size_val


func _on_bubble_size_changed(new_size: int) -> void:
	_update_display(new_size)


func _on_screen_clicked(click_pos: Vector2) -> void:
	spawn_floating_counter(click_pos)


func spawn_floating_counter(screen_pos: Vector2) -> void:
	if floating_text_scene:
		var float_instance := floating_text_scene.instantiate()
		add_child(float_instance)
		if float_instance.has_method("setup"):
			float_instance.setup(screen_pos)
		else:
			float_instance.position = screen_pos
