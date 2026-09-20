extends CharacterBody2D

signal size_changed(new_size: int)
signal screen_clicked(click_pos: Vector2)

const SPEED = 300.0
const BASE_JUMP_VELOCITY = -400.0

@export var bubble_size: int = 1
@export var size_growth_percent: float = 0.005 # +0.5% per click
@export var jump_bonus_per_size: float = 3 # marginal jump velocity increase per size point

@onready var sprite: Sprite2D = $Sprite2D
@onready var jump_sound: AudioStreamPlayer = $JumpSound
var _base_sprite_scale: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()
	if not jump_sound:
		jump_sound = get_node_or_null("JumpSound")
	if sprite and _base_sprite_scale == Vector2.ZERO:
		_base_sprite_scale = sprite.scale
	_update_visual_size()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		grow(1)
		screen_clicked.emit(event.position)


func grow(amount: int = 1) -> void:
	bubble_size += amount
	_update_visual_size()
	size_changed.emit(bubble_size)


func _update_visual_size() -> void:
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if sprite:
		if _base_sprite_scale == Vector2.ZERO:
			_base_sprite_scale = sprite.scale
		var scale_multiplier := 1.0 + (bubble_size - 1) * size_growth_percent
		sprite.scale = _base_sprite_scale * scale_multiplier


func get_current_jump_velocity() -> float:
	# Marginal jump velocity increase
	return BASE_JUMP_VELOCITY - (bubble_size - 1) * jump_bonus_per_size


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump (W, Space, Up Arrow, or gamepad jump).
	var jump_pressed := Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept")
	if jump_pressed and is_on_floor():
		velocity.y = get_current_jump_velocity()
		if jump_sound:
			jump_sound.play()

	# Get the input direction and handle the movement/deceleration (A/D or Left/Right arrows).
	var direction := Input.get_axis("move_left", "move_right")
	if direction == 0.0:
		direction = Input.get_axis("ui_left", "ui_right")

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _ensure_input_actions() -> void:
	_ensure_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_action("jump", [KEY_W, KEY_SPACE, KEY_UP])
	_ensure_action("move_down", [KEY_S, KEY_DOWN])


func _ensure_action(action_name: StringName, keys: Array[Key]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var exists := false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and (event.physical_keycode == key or event.keycode == key):
				exists = true
				break
		if not exists:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action_name, event)
