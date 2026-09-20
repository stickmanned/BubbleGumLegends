extends AnimatableBody2D
## A cloud the player can land on. It is solid on every side: the player cannot
## pass through it from below or from the sides.


## Horizontal travel in pixels, either side of where the cloud is placed.
## Zero leaves the cloud still.
@export var drift_distance: float = 0.0
## Seconds for one full out-and-back drift.
@export var drift_time: float = 4.0
## Shifts where in the drift the cloud starts, so neighbours do not move in
## lockstep.
@export_range(0.0, 1.0) var drift_phase: float = 0.0
## Background clouds turn this off and stop catching the player.
@export var solid: bool = true:
	set(value):
		solid = value
		if is_node_ready():
			_apply_solid()

@onready var _collision: CollisionShape2D = $CollisionShape2D

var _origin: Vector2
var _elapsed: float = 0.0


func _ready() -> void:
	_origin = position
	_elapsed = drift_phase * drift_time
	_apply_solid()


func setup(pos: Vector2, dist: float = 0.0, time: float = 4.0, phase: float = 0.0) -> void:
	position = pos
	_origin = pos
	drift_distance = dist
	drift_time = time
	drift_phase = phase
	_elapsed = phase * time


func _physics_process(delta: float) -> void:
	if is_zero_approx(drift_distance) or drift_time <= 0.0:
		return
	_elapsed += delta
	position = _origin + Vector2(sin(TAU * _elapsed / drift_time) * drift_distance, 0.0)


func _apply_solid() -> void:
	_collision.disabled = not solid
