class_name VengeanceShadow
extends CharacterBody2D

@export var move_speed := 270.0
@export var gravity := 1750.0
var _target: Node2D
var _attack_cooldown := 0.0
var _stagger_left := 0.0
@onready var health: HealthComponent = $Health
@onready var sprite: AnimatedSprite2D = $Visual/Sprite

func _ready() -> void:
	_target = get_tree().get_first_node_in_group("player")
	sprite.sprite_frames = EnemySpriteLibrary.build("res://assets/characters/enemies/vengeance_shadow_states_v3_normalized.png", Vector2(512, 512), &"float")
	sprite.modulate = Color(0.72, 0.45, 1.0, 0.82); sprite.play(&"float"); health.depleted.connect(_on_depleted)

func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y += gravity * delta
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0); _stagger_left = maxf(_stagger_left - delta, 0.0)
	if is_instance_valid(_target):
		var distance := _target.global_position.x - global_position.x; sprite.flip_h = distance < 0.0
		if _stagger_left > 0.0: velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		elif absf(distance) > 80.0: velocity.x = signf(distance) * move_speed
		else:
			velocity.x = 0.0
			if _attack_cooldown <= 0.0: _target.receive_hit(12.0, signf(distance) * 300.0, self, &"shadow"); _attack_cooldown = 1.2
	move_and_slide()

func receive_hit(damage: float, knockback: float, _source: Node2D, _attack_type: StringName = &"light") -> void: health.damage(damage); velocity.x = knockback; _stagger_left = 0.18
func parried(direction: float) -> void: velocity.x = direction * 420.0; _stagger_left = 0.8; _attack_cooldown = 1.2
func _on_depleted() -> void: GameState.recover_resources(); queue_free()
