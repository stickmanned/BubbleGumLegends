extends Node2D


@export var cloud_scene: PackedScene = preload("res://cloud.tscn")
@export var target: Node2D

@export_group("Generation Settings")
## How far ahead (above the player, in pixels) clouds should be generated.
@export var spawn_distance_ahead: float = 1300.0
## Reference Y level for 0 meters altitude (near starting clouds / ground).
@export var ground_y: float = 165.0
## Pixels per meter conversion factor for altitude.
@export var pixels_per_meter: float = 50.0
## Minimum altitude in meters before any clouds are generated.
@export var min_generation_altitude_m: float = 5
## Altitude in meters where spacing and density reach maximum difficulty.
@export var max_difficulty_altitude_m: float = 2000

@export_group("Spacing & Density")
## Minimum vertical spacing between clouds at low altitude.
@export var min_y_spacing_low: float = 65.0
## Maximum vertical spacing between clouds at low altitude.
@export var max_y_spacing_low: float = 95.0
## Minimum vertical spacing between clouds at high altitude.
@export var min_y_spacing_high: float = 145.0
## Maximum vertical spacing between clouds at high altitude.
@export var max_y_spacing_high: float = 215.0

@export_group("Arena Bounds & Border Protection")
## Left border wall X coordinate (from Game.tscn Borders/left).
@export var border_left: float = -900.0
## Right border wall X coordinate (from Game.tscn Borders/right).
@export var border_right: float = 1344.0
## Half-width of cloud collision shape (180.6 / 2 = ~90.3).
@export var cloud_half_width: float = 90.3
## Maximum vertical gap allowed along a border before a wall-blocking cloud is forced.
@export var max_wall_gap_y: float = 280.0

@export_group("Moving Clouds")
## Probability that a newly generated cloud will be a moving drifting cloud.
@export_range(0.0, 1.0) var moving_cloud_chance: float = 0.28
@export var min_drift_distance: float = 50.0
@export var max_drift_distance: float = 130.0
@export var min_drift_time: float = 3.0
@export var max_drift_time: float = 5.5

var arena_min_x: float
var arena_max_x: float

var _highest_y: float = 0.0
var _clouds_container: Node2D
var _distance_since_left_wall: float = 0.0
var _distance_since_right_wall: float = 0.0


func _ready() -> void:
	_clouds_container = self
	# Calculate exact cloud center positions so collision edges meet the borders flush
	arena_min_x = border_left + cloud_half_width
	arena_max_x = border_right - cloud_half_width

	# Initialize highest Y so generation begins strictly at or above min_generation_altitude_m (20m)
	var min_generation_y := ground_y - (min_generation_altitude_m * pixels_per_meter)
	var first_step := randf_range(min_y_spacing_low, max_y_spacing_low)
	_highest_y = min_generation_y + first_step


func _process(_delta: float) -> void:
	if not target:
		_locate_target()
		if not target:
			return

	var min_generation_y := ground_y - (min_generation_altitude_m * pixels_per_meter)
	var generation_ceiling := target.global_position.y - spawn_distance_ahead

	# Only generate if the generation horizon has reached the 20m height threshold
	if generation_ceiling < min_generation_y:
		while _highest_y > generation_ceiling:
			_generate_next_tier()


func _locate_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		target = players[0] as Node2D
		return

	if get_parent():
		var bubble_node := get_parent().get_node_or_null("Bubble")
		if bubble_node is Node2D:
			target = bubble_node


func _generate_next_tier() -> void:
	var current_altitude_m := maxf(0.0, (ground_y - _highest_y) / pixels_per_meter)
	var difficulty_t := clampf(current_altitude_m / max_difficulty_altitude_m, 0.0, 1.0)

	# Vertical step gets larger as altitude increases
	var step_low := randf_range(min_y_spacing_low, max_y_spacing_low)
	var step_high := randf_range(min_y_spacing_high, max_y_spacing_high)
	var y_step := lerpf(step_low, step_high, difficulty_t)
	_highest_y -= y_step

	var min_generation_y := ground_y - (min_generation_altitude_m * pixels_per_meter)
	# Strict threshold: Never generate any clouds below 20m height
	if _highest_y > min_generation_y:
		_highest_y = min_generation_y

	_distance_since_left_wall += y_step
	_distance_since_right_wall += y_step

	# Density: At low altitude, chance of 2 clouds per tier. At high altitude, 1 cloud per tier.
	var clouds_count := 1
	var multi_cloud_prob := lerpf(0.65, 0.0, difficulty_t)
	if randf() < multi_cloud_prob:
		clouds_count = 2

	if clouds_count == 2:
		var mid_x := (arena_min_x + arena_max_x) * 0.5
		# Spawn across left and right halves, reaching all the way to borders
		_spawn_cloud_in_range(arena_min_x, mid_x - 100.0, _highest_y)
		_spawn_cloud_in_range(mid_x + 100.0, arena_max_x, _highest_y)
	else:
		_spawn_cloud_in_range(arena_min_x, arena_max_x, _highest_y)

	# Guarantee that borders are blocked regularly so wall-riding is impossible
	if _distance_since_left_wall >= max_wall_gap_y:
		_spawn_wall_blocker_left(_highest_y)

	if _distance_since_right_wall >= max_wall_gap_y:
		_spawn_wall_blocker_right(_highest_y)


func _spawn_wall_blocker_left(y_pos: float) -> void:
	_spawn_direct_cloud(arena_min_x, y_pos, 0.0, 4.0, 0.0)
	_distance_since_left_wall = 0.0


func _spawn_wall_blocker_right(y_pos: float) -> void:
	_spawn_direct_cloud(arena_max_x, y_pos, 0.0, 4.0, 0.0)
	_distance_since_right_wall = 0.0


func _spawn_cloud_in_range(min_x: float, max_x: float, y_pos: float) -> void:
	if not cloud_scene:
		return

	var is_moving := randf() < moving_cloud_chance
	var drift_dist := 0.0
	var drift_t := 4.0
	var drift_p := 0.0

	var spawn_min_x := clampf(min_x, arena_min_x, arena_max_x)
	var spawn_max_x := clampf(max_x, arena_min_x, arena_max_x)

	if is_moving:
		drift_dist = randf_range(min_drift_distance, max_drift_distance)
		drift_t = randf_range(min_drift_time, max_drift_time)
		drift_p = randf()

		# Ensure moving oscillation [x - drift, x + drift] stays within arena borders
		var safe_min_x := arena_min_x + drift_dist
		var safe_max_x := arena_max_x - drift_dist
		if safe_min_x < safe_max_x:
			spawn_min_x = clampf(spawn_min_x, safe_min_x, safe_max_x)
			spawn_max_x = clampf(spawn_max_x, safe_min_x, safe_max_x)
		else:
			is_moving = false
			drift_dist = 0.0

	var spawn_x := randf_range(spawn_min_x, spawn_max_x)

	# Snap to borders if very close, ensuring solid border contact
	if not is_moving:
		if absf(spawn_x - arena_min_x) < 55.0:
			spawn_x = arena_min_x
			_distance_since_left_wall = 0.0
		elif absf(spawn_x - arena_max_x) < 55.0:
			spawn_x = arena_max_x
			_distance_since_right_wall = 0.0

	_spawn_direct_cloud(spawn_x, y_pos, drift_dist, drift_t, drift_p)


func _spawn_direct_cloud(x_pos: float, y_pos: float, dist: float = 0.0, time: float = 4.0, phase: float = 0.0) -> void:
	if not cloud_scene:
		return

	var cloud_instance := cloud_scene.instantiate() as Node2D
	if not cloud_instance:
		return

	_clouds_container.add_child(cloud_instance)

	if cloud_instance.has_method("setup"):
		cloud_instance.setup(Vector2(x_pos, y_pos), dist, time, phase)
	else:
		cloud_instance.position = Vector2(x_pos, y_pos)
		if "drift_distance" in cloud_instance:
			cloud_instance.drift_distance = dist
		if "drift_time" in cloud_instance:
			cloud_instance.drift_time = time
		if "drift_phase" in cloud_instance:
			cloud_instance.drift_phase = phase
