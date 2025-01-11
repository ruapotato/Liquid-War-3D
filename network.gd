extends Node3D

@onready var player = preload("res://player.tscn")
var multiplayer_peer = ENetMultiplayerPeer.new()

const PORT = 6969
const ADDRESS = "127.0.0.1"

var connected_upids = []
var local_player_id = 0
var local_player = null  # Added this declaration

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	print("Peer Connected: ", id)
	if multiplayer.is_server():
		# Tell new peer about existing players
		for peer_id in connected_upids:
			rpc_id(id, "spawn_player", peer_id)
		# Tell all peers about new player
		rpc("spawn_player", id)
		spawn_player(id)

func _on_peer_disconnected(id: int) -> void:
	print("Peer Disconnected: ", id)
	if has_node(str(id)):
		get_node(str(id)).queue_free()
	connected_upids.erase(id)

func _on_host_pressed():
	$Menu.visible = false
	var error = multiplayer_peer.create_server(PORT)
	if error != OK:
		print("Failed to create server: ", error)
		return
		
	multiplayer.multiplayer_peer = multiplayer_peer
	local_player_id = 1  # Server is always ID 1
	connected_upids.append(local_player_id)
	
	print("Server started. My ID: ", local_player_id)
	$Network_Info/UPID.text = "Server: " + str(local_player_id)
	spawn_player(local_player_id)

func _on_connect_pressed():
	$Menu.visible = false
	var error = multiplayer_peer.create_client(ADDRESS, PORT)
	if error != OK:
		print("Failed to create client: ", error)
		return
		
	multiplayer.multiplayer_peer = multiplayer_peer
	local_player_id = multiplayer_peer.get_unique_id()
	
	print("Client started. My ID: ", local_player_id)
	$Network_Info/UPID.text = "Client: " + str(local_player_id)

@rpc("any_peer")
func spawn_player(id: int):
	if not id in connected_upids:
		connected_upids.append(id)
	
	# Don't respawn existing players
	if has_node(str(id)):
		return
		
	print("Spawning player with ID: ", id)
	var new_player = player.instantiate()
	new_player.name = str(id)
	new_player.set_multiplayer_authority(id)
	add_child(new_player)
	
	if id == local_player_id:
		print("This is my player: ", id)
		local_player = new_player
