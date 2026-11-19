extends Node

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected()

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CONNECTIONS = 9

var players = {}
var player_info = {"name": ""}
var players_loaded = []
var loading = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func join_game(address = "", pseudo = "") -> Error:
	if address.is_empty():
		address = DEFAULT_SERVER_IP
			
	var peer = ENetMultiplayerPeer.new()

	player_info.name = pseudo
	
	var error = peer.create_client(address, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer=peer
	return OK
	
func create_game(pseudo = "") -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer=peer
	player_info.name = pseudo
	players[1]=player_info
	player_connected.emit(1, player_info)
	return OK	
	
func remove_multiplayer_peer():
	loading=false
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()
	players_loaded.clear()
	
@rpc("call_local","reliable")
func load_game(game_scene_path):
	loading = true
	players_loaded.clear()
	get_tree().change_scene_to_file(game_scene_path)
	
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server() && loading:
		players_loaded.append(multiplayer.get_remote_sender_id())
		_check_all_player_loaded()
			
func _check_all_player_loaded() -> void:
	if !loading || players_loaded.size() < players.size():
		return
	else:
		loading = false
		get_tree().current_scene.start_game()

func _on_player_connected(id):
	_register_player.rpc_id(id, player_info)
	
@rpc("any_peer","reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
	
func _on_player_disconnected(id):
	players_loaded.erase(id)
	players.erase(id)
	player_disconnected.emit(id)
	if multiplayer.is_server():
		_check_all_player_loaded()
	
func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	if player_info.name.is_empty():
		player_info.name = "user"+str(peer_id)
	players[peer_id]=player_info
	player_connected.emit(peer_id, player_info)
	
func _on_connected_fail():
	remove_multiplayer_peer()
	
func _on_server_disconnected():
	remove_multiplayer_peer()
	server_disconnected.emit()
