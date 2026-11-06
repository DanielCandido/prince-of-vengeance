class_name BoltProjectile
extends Area2D

@export var speed := 780.0
@export var damage := 14.0
@export var lifetime := 4.0
var direction := 1.0
var shooter: Node2D
var _reflected := false

func setup(new_direction: float, owner_actor: Node2D) -> void:
	direction = signf(new_direction); shooter = owner_actor; scale.x = direction

func _ready() -> void: area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta; lifetime -= delta
	if lifetime <= 0.0: queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not area.has_method("receive_hit"): return
	var actor: Node2D = (area as Hurtbox2D).actor if area is Hurtbox2D else null
	if actor == shooter and not _reflected: return
	area.receive_hit(damage, direction * 240.0, self, &"projectile")
	queue_free()

func parried(_direction: float) -> void:
	_reflected = true; direction *= -1.0; damage = 28.0; speed *= 1.35; scale.x = direction
	set_deferred("monitoring", false); await get_tree().physics_frame; set_deferred("monitoring", true)
