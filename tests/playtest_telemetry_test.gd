extends Node

func _ready() -> void:
	var scene: Node = load("res://scenes/vertical_slice.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	scene._playtest_elapsed = 601.25
	scene._playtest_hits = 7
	scene._playtest_damage_received = 24.0
	scene._playtest_parries = 2
	scene._playtest_deaths = 1
	scene._playtest_checkpoints = 2
	scene._playtest_recoveries = 1
	scene._complete_playtest()
	var summary: Dictionary = scene._build_playtest_summary()
	if not summary.completed or summary.duration_seconds != 601.25 or summary.hits_landed != 7 or summary.shadows_recovered != 1:
		push_error("REGRESSÃO: resumo de telemetria incorreto")
		get_tree().quit(1)
		return
	if "10:01" not in scene.telemetry_label.text or "CONCLUÍDO" not in scene.telemetry_label.text:
		push_error("REGRESSÃO: HUD de telemetria incorreto")
		get_tree().quit(1)
		return
	print("PASS: telemetria registra e resume a run")
	get_tree().quit(0)
