extends Node

func _ready() -> void:
	var scene: Node = load("res://scenes/vertical_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	var player: KaelenController = scene.get_node("Kaelen")
	player.combat_enabled = true

	player._start_attack(0)
	if player._attack_hitbox_live:
		_fail("ataque leve ficou ativo durante o startup")
		return
	player._state_left = KaelenController.ATTACK_DURATION[0] - KaelenController.ATTACK_STARTUP[0] - 0.001
	player._update_combat_windows()
	if not player._attack_hitbox_live:
		_fail("ataque leve não ativou após o startup")
		return
	player._state_left = KaelenController.ATTACK_DURATION[0] - KaelenController.ATTACK_ACTIVE_END[0] - 0.001
	player._update_combat_windows()
	if player._attack_hitbox_live:
		_fail("ataque leve permaneceu ativo durante a recuperação")
		return

	player._set_state(KaelenController.State.PARRY, KaelenController.PARRY_DURATION)
	player._state_left = KaelenController.PARRY_DURATION - 0.01
	if player._is_parry_active():
		_fail("parry ficou ativo durante a preparação")
		return
	player._state_left = KaelenController.PARRY_DURATION - 0.05
	if not player._is_parry_active():
		_fail("parry não ficou ativo dentro da janela")
		return
	player._state_left = KaelenController.PARRY_DURATION - 0.18
	if player._is_parry_active():
		_fail("parry permaneceu ativo durante a recuperação")
		return

	print("PASS: startup, atividade e recuperação do combate estão separados")
	get_tree().quit(0)

func _fail(message: String) -> void:
	push_error("REGRESSÃO: " + message)
	get_tree().quit(1)
