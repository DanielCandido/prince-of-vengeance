extends Node

func _ready() -> void:
	var scene: Node = load("res://scenes/vertical_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	var player: KaelenController = scene.get_node("Kaelen")
	if not scene.has_node("BandFire/Flame") or not scene.has_node("BandFire/Stones"):
		_fail("fogueira 2D esta incompleta"); return
	if not player.combat_enabled:
		_fail("combate deveria iniciar ativado"); return
	player._start_attack(0)
	player._state_left = KaelenController.ATTACK_DURATION[0] - KaelenController.ATTACK_STARTUP[0] - 0.01
	player._update_combat_windows(); player._update_animation()
	if player.character_sprite.animation != &"attack_1" or not player._attack_hitbox_live:
		_fail("ataque 2D nao animou ou ativou hitbox"); return
	player._set_state(KaelenController.State.FREE); player._start_dash()
	if not is_equal_approx(player._state_left, KaelenController.DASH_DURATION):
		_fail("dash nao iniciou com duracao correta"); return
	player._set_state(KaelenController.State.CHARGE); player._update_animation()
	if player.character_sprite.animation != &"charge":
		_fail("carregamento nao usa animacao 2D"); return
	player._start_heavy_attack(); player._update_animation()
	if player.character_sprite.animation != &"heavy" or player._state_left < 0.99:
		_fail("golpe pesado nao iniciou corretamente"); return
	print("PASS: combate e movimentacao 2D calibrados")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("REGRESSAO: " + message); get_tree().quit(1)
