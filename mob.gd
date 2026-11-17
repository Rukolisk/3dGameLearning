extends CharacterBody3D
signal squashed
@export var min_speed = 10
@export var max_speed = 18

func _physics_process(delta: float) -> void:
	move_and_slide()
	
@rpc("any_peer", "call_local", "reliable")
func squash():
	if !is_queued_for_deletion():
		queue_free()
		squashed.emit()

func initialize(start_position, player_position, speed, angle):
	var target_position = player_position
	target_position.y = start_position.y

	look_at_from_position(start_position, target_position, Vector3.UP)
	rotate_y(angle)                  

	velocity = Vector3.FORWARD * speed
	velocity = velocity.rotated(Vector3.UP, rotation.y)
	$AnimationPlayer.speed_scale = speed / min_speed

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	if is_multiplayer_authority():
		queue_free()
