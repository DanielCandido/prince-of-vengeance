class_name Hurtbox2D
extends Area2D

@export var actor: Node2D

func receive_hit(damage: float, knockback: float, source: Node2D, attack_type: StringName) -> void:
	if is_instance_valid(actor) and actor.has_method("receive_hit"):
		actor.receive_hit(damage, knockback, source, attack_type)
