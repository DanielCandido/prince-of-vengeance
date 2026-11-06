extends Node

func _ready() -> void:
	var scene: Node = load("res://scenes/vertical_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	var player: KaelenController = scene.get_node("Kaelen")
	if player.character_sprite.sprite_frames.get_frame_count(&"idle") != 4:
		_fail("idle 2D de Kaelen esta incompleto"); return
	if player.character_sprite.sprite_frames.get_frame_count(&"run") != 8:
		_fail("corrida 2D de Kaelen esta incompleta"); return
	if player.character_sprite.sprite_frames.get_frame_count(&"jump") != 4:
		_fail("pulo 2D de Kaelen esta incompleto"); return
	var enemy_sprites: Array[AnimatedSprite2D] = [scene.get_node("TrainingEnemy/Visual/Sprite"), scene.get_node("CrossbowGuard/Visual/Sprite"), scene.get_node("SecondRoomBruiser/Visual/Sprite")]
	for sprite in enemy_sprites:
		if sprite.sprite_frames == null or sprite.sprite_frames.get_animation_names().is_empty():
			_fail("inimigo nao possui animacoes 2D"); return
	print("PASS: Kaelen e inimigos usam sprites 2D animados")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("REGRESSAO: " + message); get_tree().quit(1)
