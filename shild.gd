extends Node
@onready var target = get_parent()

signal no_damage(this_much)

# Called when the node enters the scene tree for the first time.
func _ready():
	no_damage.connect(_no_damage)
#	print("I'm a shild for " + str(target))

func _no_damage(damage):
	pass
	
func _unhandled_input(event):
	
	if Input.is_action_just_released("shild"):
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
