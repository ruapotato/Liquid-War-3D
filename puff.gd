extends RigidBody3D

@onready var laser_ball_L1 = preload("res://laser_ball_L1.tscn")
@onready var player = self.get_parent().find_child("cuttle")
@onready var target = self.get_parent().find_child("cuttle")
@onready var core = self.find_child("core")

var mouse_move = [0,0]
var shoot_speed = 17
var life = 100
var launch_power = 0
var max_launch_power = 25
var launch_power_build_speed = 10
var wants_to_grab = false
var tethered = false
var power = 0
var max_power = 100
var power_build_speed = 10
var cost_to_shoot = 10
var shoot_cooldown = 0
var fire_rate = .1
var target_in_sight = false
signal damage(this_much)
signal add_life(this_much)
#var shoot_vector = Vector3(5,0,0)
# Called when the node enters the scene tree for the first time.
func _ready():
	damage.connect(_take_damage)
	add_life.connect(_add_life)
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	contact_monitor = true
	max_contacts_reported = 99999



func _take_damage(damage):
	#print("Oh that really got me good!")
	life -= damage
	target = player
	#print(life)

func _add_life(this_much):
	life += this_much
	if life > 100:
		life  = 100
	target = player
	#print("AI added: " + str(life))


func _on_body_entered(body):
	#print("hit" + body.name)
	
	#Tether if we are not near the player or target is not a player
	if global_position.distance_to(target.position) > 20 and target == player:
		tethered = true
		linear_velocity = Vector3(0,0,0)

func _physics_process(delta):
	if not target:
		target = player
	look_at(target.position, Vector3(0, 1, 0), false)
	var space_state = get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.create(position, target.position)
	var in_view = space_state.intersect_ray(q)
	
	
	#Bug fix, not really sure why it's needed
	if "collider" not in in_view:
		return
	
	#print(str(in_view.collider))
	if target == in_view.collider:
		target_in_sight = true
		#print("I see you!")
	else:
		#print("Were are you?")
		target_in_sight = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	#Update power
	if power < max_power:
		power += delta * power_build_speed
	elif power > max_power:
		power = max_power
	
	#Update shootcooldown
	if shoot_cooldown > 0:
		shoot_cooldown -= delta
	
	#Add launch power
	if tethered:
		linear_velocity = Vector3(0,0,0)
		if launch_power < max_launch_power:
			launch_power += delta * launch_power_build_speed
		elif launch_power > max_launch_power:
			launch_power = max_launch_power

	
	#Update light
	#TODO only do this on life cahnge
	#core.get_active_material(1).emission_energy_multiplier = abs(pow(abs(life-100), 1/3.0) - 4.62)/8

	
	if life <= 60 and target == player:
		var objs = self.get_parent().get_children()
		for obj in objs:
			if "life_cube" in obj.name:
				target = obj
				print("Set new target: " + target.name)
			
	#jump
	if launch_power > 10:
		if tethered:
			tethered = false
			var local = to_local(global_position)
			var local_target = Vector3(local.x,local.y,local.z - 1)
			
			#Add speed on local Z
			var global_direction = -global_transform.basis.z * launch_power
			apply_impulse(global_direction, global_direction * 10)
			launch_power = 0


	#Fire
	if target_in_sight:
		if shoot_cooldown <= 0:
			if power - cost_to_shoot > 0:
				power -= cost_to_shoot
				#print("Add new laser ball")
				var new_laser = laser_ball_L1.instantiate()
				new_laser.gravity_scale = 0
				new_laser.contact_monitor = true

				var local = to_local(global_position)
				var local_target = Vector3(local.x,local.y,local.z - 1)
				var global_direction = -global_transform.basis.z * shoot_speed
				var player_pushback = global_transform.basis.z
				
				#If target is not player shoot backword
				if target != player:
					local_target = Vector3(local.x,local.y,local.z + 1)
					global_direction = global_transform.basis.z * shoot_speed
					player_pushback = -global_transform.basis.z
				#var pos = Vector3(global_position.x,lobal_position.y,global_position.z + .5)
				
				#Add speed on Z
				new_laser.transform.origin = to_global(local_target)
				#var global_direction = -global_transform.basis.z * shoot_speed
				new_laser.apply_impulse(global_direction, global_direction * 10)
				apply_impulse(player_pushback, global_direction * 10)
				new_laser.rotation = rotation
				get_parent().add_child(new_laser)
	if life <= 0:
		queue_free()
