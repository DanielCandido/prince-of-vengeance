extends Node

func _ready() -> void:
	var brute: ThornBrute = load("res://scenes/enemies/thorn_brute.tscn").instantiate()
	add_child(brute)
	await get_tree().process_frame
	brute._telegraph_left = 0.5
	brute.velocity.x = 0.0
	var health_before := brute.health.current_health
	brute.receive_hit(12.0, 10.0, null)
	if brute.health.current_health >= health_before or not is_zero_approx(brute.velocity.x) or brute._telegraph_left <= 0.0:
		push_error("REGRESSÃO: hyper-armor do Bruto não preservou o ataque")
		get_tree().quit(1)
		return
	brute.parried(1.0)
	if brute._telegraph_left > 0.0 or brute._stagger_left <= 0.0:
		push_error("REGRESSÃO: parry não interrompeu o Bruto")
		get_tree().quit(1)
		return
	print("PASS: Bruto mantém hyper-armor e é interrompido por parry")
	get_tree().quit(0)
