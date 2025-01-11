extends RayCast3D

@onready var mesh = $MeshInstance3D
@onready var laser_effect = $laser_effect
@onready var player = get_parent().find_child("cuttle")


var damage = 50
var time_alive = 0
var ttl = .4
var size = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	#add_exception(player)
	#print("hi")
	$shot.play()
	#mesh.material_override("res://native/laser_L1.tres")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_alive += delta
	var ray_cast_point
	force_raycast_update()
	if is_colliding():
		ray_cast_point = to_local(get_collision_point())
		mesh.mesh.height = ray_cast_point.z
		mesh.position.z = ray_cast_point.z/2
		laser_effect.position.z = ray_cast_point.z/2
		#if "Briska" in get_collider().collider:
		#	print("Oh Shit")
		for sig in get_collider().get_signal_list():
			if sig.name == "no_damage":
				get_collider().emit_signal("no_damage")

			if sig.name == "damage":
				#print("hi")
				get_collider().emit_signal("damage", damage * delta)
				$hit.play()
	else:
		mesh.position = Vector3(0,0, -50)
		mesh.mesh.height = 100
		laser_effect.position = Vector3(0,0, -50)
	#scale beem up and down
	#var size = ((int(time_alive * 100) % 30) -15) / 10000.0

	var size_to_be = (time_alive - ttl)/10.0
	size = lerp(float(size), float(size_to_be), delta * 10)

	mesh.mesh.top_radius = size
	mesh.mesh.bottom_radius = size
	if ttl < time_alive:
		queue_free()
		#print("HIT!")
