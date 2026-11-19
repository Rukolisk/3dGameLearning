extends Label

@rpc("authority","call_local","reliable")
func afficher_classement(classement):
	var texte = ""
	var i = 1
	for entree in classement:
		texte += "%d. %s : %d\n" % [i, entree.name, entree.score]
		i += 1
	text = texte
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
