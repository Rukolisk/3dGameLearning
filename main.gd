extends Node

@export var mob_scene: PackedScene
@export var player_scene: PackedScene
var players = []
const SPAWN_PER_LINE = 3
const SPAWN_SPACING = 3
var mob_count = 0
const MOB_MIN_SPEED=10
const MOB_MAX_SPEED=18
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PlayerSpawner.spawn_function = spawn_player
	$MobSpawner.spawn_function = spawn_mob
	$UserInterface/Retry.hide()
	SessionManager.player_loaded.rpc_id(1) # Tell the server that this peer has loaded.
	SessionManager.server_disconnected.connect(_on_server_disconnected)
	SessionManager.player_disconnected.connect(_on_player_disconnected)


func start_game() -> void:
	print("Tout le monde est prêt, la partie commence !")
	var index = 0
	for peer_id in SessionManager.players:
		var colonne = index % SPAWN_PER_LINE
		var ligne = index / SPAWN_PER_LINE
		var data = {
			"id": peer_id,
			"position": Vector3(colonne * SPAWN_SPACING, 0,ligne * SPAWN_SPACING)
		}
		var player = $PlayerSpawner.spawn(data)
		player.hit.connect(_on_player_hit)
		players.append(player)
		index += 1
	$MobTimer.start()

func spawn_player(data: Variant) -> Node:
	var player = player_scene.instantiate()
	player.name = str(data["id"])
	player.position = data["position"]
	return player
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func spawn_mob(data: Variant) -> Node:
	var mob = mob_scene.instantiate()
	mob.name = str(data["id"])
	mob.initialize(data["position"], data["player_position"],data["random_speed"], data["random_rotate"])
	mob.squashed.connect($UserInterface/ScoreLabel._on_mob_squashed.bind())
	return mob
	
func _on_mob_timer_timeout() -> void:
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	mob_spawn_location.progress_ratio = randf()

	var player_position = players.pick_random().position
	var random_rotate =randf_range(-PI / 4, PI / 4)
	var random_speed = randi_range(MOB_MIN_SPEED,MOB_MAX_SPEED)
	var data = {
		"id": mob_count,
		"position": mob_spawn_location.position,
		"player_position": player_position,
		"random_rotate": random_rotate,
		"random_speed": random_speed
	}
	mob_count += 1
	$MobSpawner.spawn(data)
	

func _on_player_hit(node: Node3D) -> void:
	players.erase(node)
	if !players.size():
		$MobTimer.stop()
		show_retry.rpc()
		
@rpc("authority","call_local","reliable")
func show_retry():
	$UserInterface/Retry.show()

func _unhandled_input(event: InputEvent) -> void:
	if multiplayer.is_server():
		if event.is_action_pressed("ui_accept") and $UserInterface/Retry.visible:
			reload.rpc()
			
@rpc("authority","call_local","reliable")
func reload():
	get_tree().reload_current_scene()


func _on_deconnexion_pressed() -> void:
	SessionManager.remove_multiplayer_peer()
	get_tree().change_scene_to_file("res://menu.tscn")

func _on_server_disconnected() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")

func _on_player_disconnected(id) -> void:
	# 1. Seul le serveur s'en occupe
	if not multiplayer.is_server():
		return

	# 2. Chercher le personnage dans Players, par son nom (l'ID en texte)
	var player = $Players.get_node_or_null(str(id))

	# 3. S'il existe encore, on le fait mourir
	if player != null:
		player.die()
