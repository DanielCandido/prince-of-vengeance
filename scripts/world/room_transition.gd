class_name RoomTransition
extends Area2D

@export var destination: Node2D
var _locked := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _locked or not body.is_in_group("player") or not is_instance_valid(destination): return
	_locked = true
	body.global_position = destination.global_position
	body.velocity = Vector2.ZERO
	await get_tree().create_timer(0.35).timeout
	_locked = false
