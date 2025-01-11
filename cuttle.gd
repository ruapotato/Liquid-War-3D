extends RigidBody3D

@onready var piv = $piv
@onready var spring_arm = $piv/SpringArm3D
@onready var camera = $piv/SpringArm3D/Camera3D
@onready var network_upid = self.find_child("network_upid")

const SPEED = 15.0
const ACCELERATION = 3.0
const DECELERATION = 5.0
const MAX_ZOOM = 20.0
const MIN_ZOOM = 2.0
const ZOOM_SPEED = 0.5
const ROTATION_SPEED = 0.004

var last_sent_pos = Vector3.ZERO
var velocity = Vector3.ZERO
var target_velocity = Vector3.ZERO

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	var my_id = name.to_int()
	print("Player ", my_id, " ready. Authority: ", get_multiplayer_authority())
	print("Initial camera state - current: ", camera.current)
	print("Initial camera global transform: ", camera.global_transform)
	
	# Physics setup
	gravity_scale = 0
	lock_rotation = true
	contact_monitor = true
	max_contacts_reported = 1
	
	# Camera setup
	if is_multiplayer_authority():
		print("Setting up authority camera for player: ", my_id)
		camera.current = true
		
		if my_id == 1:
			print("Pre-reparent hierarchy for player 1:")
			print("- Camera parent: ", camera.get_parent().name)
			print("- SpringArm parent: ", spring_arm.get_parent().name)
			print("- Pivot parent: ", piv.get_parent().name)
			
			var original_cam_transform = camera.global_transform
			var original_spring_transform = spring_arm.global_transform
			var original_piv_transform = piv.global_transform
			
			# Try keeping the whole camera setup intact
			piv.reparent(self, false)
			
			print("Post-reparent hierarchy check:")
			print("- Camera parent: ", camera.get_parent().name)
			print("- SpringArm parent: ", spring_arm.get_parent().name)
			print("- Pivot parent: ", piv.get_parent().name)
			
			# Verify transforms
			print("Camera transform maintained: ", camera.global_transform.is_equal_approx(original_cam_transform))
			print("SpringArm transform maintained: ", spring_arm.global_transform.is_equal_approx(original_spring_transform))
			print("Pivot transform maintained: ", piv.global_transform.is_equal_approx(original_piv_transform))
		
		network_upid.text = "Local: " + str(my_id)
	else:
		camera.current = false
		network_upid.text = "Remote: " + str(my_id)

# Add this new function to monitor camera changes
func _process(_delta):
	if is_multiplayer_authority() and str(name).to_int() == 1:
		if !camera.current:
			print("WARNING: Player 1 camera lost current status!")
			print("Current camera hierarchy:")
			print("- Camera parent: ", camera.get_parent().name)
			print("- SpringArm parent: ", spring_arm.get_parent().name)
			print("- Pivot parent: ", piv.get_parent().name)
			camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
		
	if event is InputEventMouseMotion:
		spring_arm.rotate_x(-event.relative.y * ROTATION_SPEED)
		piv.rotate_y(-event.relative.x * ROTATION_SPEED)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI/2, PI/2)
	
	elif event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				spring_arm.spring_length = clamp(
					spring_arm.spring_length - ZOOM_SPEED,
					MIN_ZOOM,
					MAX_ZOOM
				)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				spring_arm.spring_length = clamp(
					spring_arm.spring_length + ZOOM_SPEED,
					MIN_ZOOM,
					MAX_ZOOM
				)

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
		
	# Movement input
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	# Camera-relative movement
	var cam_basis = spring_arm.global_transform.basis
	var direction = cam_basis.x * input_dir.x + cam_basis.z * input_dir.y
	direction = direction.normalized()
	
	# Vertical movement
	if Input.is_action_pressed("float"):
		direction.y = 1.0
	elif Input.is_action_pressed("ui_cancel"):
		direction.y = -1.0
		
	# Movement physics
	target_velocity = direction * SPEED
	velocity = velocity.lerp(target_velocity, ACCELERATION * delta)
	if direction.length() == 0:
		velocity = velocity.lerp(Vector3.ZERO, DECELERATION * delta)
		
	linear_velocity = velocity
	
	# Network sync
	if last_sent_pos.distance_to(global_position) > 0.1:
		rpc("receive_remote_transform", global_position, velocity)
		last_sent_pos = global_position

@rpc("unreliable")
func receive_remote_transform(pos: Vector3, vel: Vector3):
	if not is_multiplayer_authority():
		global_position = global_position.lerp(pos, 0.3)
		linear_velocity = vel
