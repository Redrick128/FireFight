extends Node3D

@onready var Bullet: MeshInstance3D = $Bullet
@onready var ray_cast_3d: RayCast3D = $Bullet/RayCast3D
var prev_pos: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	prev_pos = Bullet.global_position
	ray_cast_3d.exclude_parent


var speed = 620 #Dis in M/s
var is_hit_obj = false
var direction: Vector3

func _process(delta):
	if is_hit_obj:
		return

	var dist = speed * delta
	var new_pos = global_position + direction * dist

	var query = PhysicsRayQueryParameters3D.new()
	query.from = prev_pos
	query.to = new_pos

	var result = get_world_3d().direct_space_state.intersect_ray(query)

	# Debug
	if result:
		is_hit_obj = true
		global_position = result["position"]
		print("Hit:", result["collider"], "Object Global Position:", result["position"])
		return

	global_position = new_pos
	prev_pos = new_pos
