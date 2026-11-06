class_name Hitbox2D
extends Area2D

signal hit_landed(position: Vector2, attack_type: StringName)

@export var damage := 10.0
@export var knockback := 320.0
@export var source: Node2D
@export var attack_type: StringName = &"light"
var _hit_areas: Array[Area2D] = []

func _ready() -> void:
	monitoring = false
	area_entered.connect(_on_area_entered)

func activate(new_damage: float = damage, new_knockback: float = knockback, new_attack_type: StringName = attack_type) -> void:
	damage = new_damage
	knockback = new_knockback
	attack_type = new_attack_type
	_hit_areas.clear()
	set_deferred("monitoring", true)

func deactivate() -> void:
	set_deferred("monitoring", false)

func _on_area_entered(area: Area2D) -> void:
	if area in _hit_areas or not area.has_method("receive_hit"):
		return
	if area is Hurtbox2D and (area as Hurtbox2D).actor == source:
		return
	_hit_areas.append(area)
	var direction := 1.0
	if is_instance_valid(source):
		direction = signf(area.global_position.x - source.global_position.x)
	area.receive_hit(damage, direction * knockback, source, attack_type)
	hit_landed.emit(area.global_position, attack_type)
