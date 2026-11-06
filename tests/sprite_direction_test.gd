extends Node

func _ready() -> void:
	var scene: Node = load("res://scenes/vertical_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	var player: KaelenController = scene.get_node("Kaelen")
	Input.action_press("move_left"); player._process_free(0.1); player._update_facing_visuals(); Input.action_release("move_left")
	if not player.character_sprite.flip_h:
		push_error("REGRESSAO: sprite nao virou para a esquerda"); get_tree().quit(1); return
	Input.action_press("move_right"); player._process_free(0.1); player._update_facing_visuals(); Input.action_release("move_right")
	if player.character_sprite.flip_h:
		push_error("REGRESSAO: sprite nao virou para a direita"); get_tree().quit(1); return
	print("PASS: sprites 2D acompanham esquerda e direita")
	get_tree().quit(0)
