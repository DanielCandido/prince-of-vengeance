extends Node

func _ready() -> void:
	var scene: Node = load("res://scenes/vertical_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	var player: KaelenController = scene.get_node("Kaelen")
	player.combat_enabled = true
	player.receive_hit(999.0, 0.0, null)
	await get_tree().process_frame
	if player.state != KaelenController.State.DEAD:
		push_error("REGRESSÃO: Kaelen não entrou no estado de morte")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.9).timeout
	if player.state != KaelenController.State.FREE or player.health.current_health != player.health.max_health:
		push_error("REGRESSÃO: respawn não restaurou Kaelen")
		get_tree().quit(1)
		return
	print("PASS: morte aguarda animação e respawn restaura Kaelen")
	get_tree().quit(0)
