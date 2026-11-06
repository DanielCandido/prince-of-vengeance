extends Node

func _ready() -> void:
	var scene: Node = load("res://scenes/vertical_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var player: KaelenController = scene.get_node("Kaelen")
	var enemy: TrainingEnemy = scene.get_node("TrainingEnemy")
	player.global_position = Vector2(400.0, 620.0)
	enemy.global_position = Vector2(490.0, 620.0)
	var health_before := enemy.health.current_health
	player.attack_hitbox.activate(12.0, 4.0, &"light")
	player.attack_hitbox._on_area_entered(enemy.get_node("Hurtbox"))
	if enemy.health.current_health >= health_before:
		push_error("REGRESSÃO: ataque de Kaelen não causou dano ao inimigo")
		get_tree().quit(1)
		return
	print("PASS: inimigo recebeu dano (%.1f -> %.1f)" % [health_before, enemy.health.current_health])
	get_tree().quit(0)
