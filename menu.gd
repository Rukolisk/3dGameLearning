extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SessionManager.player_connected.connect(_on_player_connected)
	SessionManager.player_disconnected.connect(_on_player_disconnected)
	SessionManager.server_disconnected.connect(_on_server_disconnected)
	$Lancer.hide()
	_mettre_a_jour_label()

func _on_heberger_pressed() -> void:
	var err = SessionManager.create_game()
	if(err != OK):
		$PlayerNumber.text = "Erreur serveur : %s" % err
		return
	$Lancer.show()
	_desactiver_boutons()

func _on_rejoindre_pressed() -> void:
	var err = SessionManager.join_game()
	if err != OK:
		$PlayerNumber.text = "Erreur connexion : %s" % err
		return
	_desactiver_boutons()

func _on_lancer_pressed() -> void:
	SessionManager.load_game.rpc("res://main.tscn")

func _on_player_connected(_id, _info) -> void:
		_mettre_a_jour_label()

func _on_player_disconnected(_id) -> void:
		_mettre_a_jour_label()
		
func _on_server_disconnected() -> void:
		_label_deconnecte()
		_activer_boutons()
		
func _label_deconnecte() -> void:
	$PlayerNumber.text = "l'Hôte à quitté"

func _mettre_a_jour_label() -> void:
	if SessionManager.players.size():
		$PlayerNumber.text = "joueurs connectés : %d" % SessionManager.players.size()
	else:
		$PlayerNumber.text = ""

func _desactiver_boutons() -> void:
	$Heberger.disabled = true
	$Rejoindre.disabled=true
	
func _activer_boutons() -> void:
	$Heberger.disabled = false
	$Rejoindre.disabled = false
