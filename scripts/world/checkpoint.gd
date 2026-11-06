class_name Checkpoint
extends Area2D

var _player_nearby: Node2D
@onready var flame: Polygon2D = $Flame

func _ready() -> void:
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"): _player_nearby = body
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body == _player_nearby: _player_nearby = null
	)

func _process(_delta: float) -> void:
	if is_instance_valid(_player_nearby) and Input.is_action_just_pressed("interact"):
		GameState.activate_checkpoint(global_position + Vector2(0.0, 4.0))
		flame.color = Color(0.25, 0.75, 1.0)
		_player_nearby.restore_at_checkpoint()
