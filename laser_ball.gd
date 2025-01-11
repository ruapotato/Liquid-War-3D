extends RigidBody3D

@onready var mesh = $MeshInstance3D

var damage = 10
var ttl = 11

# Called when the node enters the scene tree for the first time.
func _ready():
	max_contacts_reported = 100
	$shot.play()
	#mesh.material_override("res://native/laser_L1.tres")

func _on_body_entered(body):
	if body.get_script() and damage != 0:
		#print(body.get_signal_list())
		for sig in body.get_signal_list():
			if sig.name == "no_damage":
				ttl = .01
				damage = 0
			if sig.name == "damage_me":
				#print("hi")
				body.emit_signal("damage_me", damage)
				$hit.play()
				ttl = .5
				damage = 0



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	ttl -= delta
	if ttl < 0:
		queue_free()
