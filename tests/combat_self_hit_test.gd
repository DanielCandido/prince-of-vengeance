extends Node

func _ready() -> void:
	var scene: Node = load("res://scenes/vertical_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var player: KaelenController = scene.get_node("Kaelen")
	var health_before := player.health.current_health
	Input.action_press("attack")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("attack")
	await get_tree().create_timer(0.5).timeout
	if not is_equal_approx(player.health.current_health, health_before):
		push_error("REGRESSÃO: ataque próprio reduziu a vida de %.1f para %.1f" % [health_before, player.health.current_health])
		get_tree().quit(1)
		return
	print("PASS: ataques de Kaelen ignoram a própria hurtbox")
	get_tree().quit(0)
