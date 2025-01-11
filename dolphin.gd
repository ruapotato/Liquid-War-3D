extends RigidBody3D

var target

var speed = 5
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func find_target():
	var closest_target_dist = 9999
	var closest_target = null
	
	for child in get_parent().get_children():
		if child is cuttle:
			var dist_check = global_position.distance_to(child.global_position)
			if dist_check < closest_target_dist:
				closest_target_dist = dist_check
				closest_target = child
				
	if closest_target != null:
		return(closest_target)


func _physics_process(delta):
	if target:
		#print(target)
		look_at(target.global_position)
		
		
		var local = to_local(global_position)
		var local_target = Vector3(local.x,local.y,local.z - 1)
		
		#Add speed on local Z
		var global_direction = -global_transform.basis.z * speed * delta * 100
		#apply_impulse(global_direction, global_direction * delta)
		linear_velocity = global_direction


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	target = find_target()

