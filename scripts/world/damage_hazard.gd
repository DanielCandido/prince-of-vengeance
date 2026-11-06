class_name DamageHazard
extends Area2D

@export var damage := 20.0
@export var tick_interval := 0.8
var _targets: Array[Node2D] = []
var _cooldowns: Dictionary = {}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	for target in _targets.duplicate():
		if not is_instance_valid(target):
			_targets.erase(target)
			continue
		var left: float = maxf(float(_cooldowns.get(target, 0.0)) - delta, 0.0)
		_cooldowns[target] = left
		if left <= 0.0:
			target.receive_hit(damage, 0.0, self, &"hazard")
			_cooldowns[target] = tick_interval

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("receive_hit"):
		_targets.append(body)
		_cooldowns[body] = 0.0

func _on_body_exited(body: Node2D) -> void:
	_targets.erase(body)
	_cooldowns.erase(body)
