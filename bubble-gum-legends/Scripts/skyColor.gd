extends CanvasLayer
## Dynamically darkens the sky as the player climbs higher.

@export var player: Node2D
@export var ground_y: float = 165.0
@export var pixels_per_meter: float = 50.0

## Altitude in meters where the sky becomes completely dark (space).
@export var max_dark_altitude_m: float = 1000

## Sky color palette
@export var day_color: Color = Color(0.53, 0.81, 0.98)  
@export var dusk_color: Color = Color(0.18, 0.22, 0.45)   
@export var space_color: Color = Color(0.04, 0.04, 0.08)  

@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	if not player:
		_locate_player()


func _process(_delta: float) -> void:
	if not player:
		_locate_player()
		if not player:
			return

	# 1. Calculate current altitude in meters
	var altitude_m := maxf(0.0, (ground_y - player.global_position.y) / pixels_per_meter)

	# 2. Normalize altitude into a 0.0 to 1.0 progress factor
	var progress := clampf(altitude_m / max_dark_altitude_m, 0.0, 1.0)

	var current_sky_color: Color
	if progress < 0.5:

		current_sky_color = day_color.lerp(dusk_color, progress * 2.0)
	else:
		current_sky_color = dusk_color.lerp(space_color, (progress - 0.5) * 2.0)

	# 4. Apply color to the background
	if color_rect:
		color_rect.color = current_sky_color


func _locate_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0] as Node2D
	elif get_parent():
		var bubble_node := get_parent().get_node_or_null("Bubble")
		if bubble_node is Node2D:
			player = bubble_node
