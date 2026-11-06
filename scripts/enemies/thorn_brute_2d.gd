class_name ThornBrute
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
@export var gravity := 1750.0
@export var move_speed := 110.0
@export var detection_range := 580.0
@export var attack_range := 180.0
@export var telegraph_duration := 0.95
@export var attack_duration := 0.28
@export var attack_cooldown := 2.8
@export var scrap_reward := 35
var _target: CharacterBody2D
var _home_position := Vector2.ZERO
var _cooldown_left := 0.8
var _telegraph_left := 0.0
var _attack_left := 0.0
var _stagger_left := 0.0
@onready var health: HealthComponent = $Health
@onready var attack_hitbox: Hitbox2D = $AttackHitbox
@onready var sprite: AnimatedSprite2D = $Visual/Sprite

func _ready() -> void:
	_home_position = global_position; _target = get_tree().get_first_node_in_group("player"); attack_hitbox.source = self
	sprite.sprite_frames = EnemySpriteLibrary.build("res://assets/characters/enemies/thorn_brute_states_v3_normalized.png", Vector2(512, 512), &"walk"); sprite.play(&"idle")
	health.health_changed.connect(func(current: float, maximum: float) -> void: health_changed.emit(current, maximum)); health.depleted.connect(_on_depleted)

func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y += gravity * delta
	_cooldown_left = maxf(_cooldown_left - delta, 0.0); _stagger_left = maxf(_stagger_left - delta, 0.0); velocity.x = move_toward(velocity.x, 0.0, 850.0 * delta)
	if _stagger_left > 0.0: pass
	elif _telegraph_left > 0.0:
		_telegraph_left -= delta; sprite.play(&"telegraph")
		if _telegraph_left <= 0.0: _attack_left = attack_duration; attack_hitbox.activate(30.0, 650.0, &"brute")
	elif _attack_left > 0.0:
		_attack_left -= delta; sprite.play(&"attack")
		if _attack_left <= 0.0: attack_hitbox.deactivate(); _cooldown_left = attack_cooldown
	else: _chase_or_attack()
	move_and_slide()

func _chase_or_attack() -> void:
	if not is_instance_valid(_target): return
	var distance := _target.global_position.x - global_position.x
	if absf(distance) > detection_range: sprite.play(&"idle"); return
	var facing := signf(distance); sprite.flip_h = facing < 0.0; attack_hitbox.position.x = absf(attack_hitbox.position.x) * facing
	if absf(distance) <= attack_range:
		velocity.x = 0.0; sprite.play(&"idle")
		if _cooldown_left <= 0.0: _telegraph_left = telegraph_duration
	else: velocity.x = facing * move_speed; sprite.play(&"walk")

func receive_hit(damage: float, knockback: float, _source: Node2D, _attack_type: StringName = &"light") -> void:
	health.damage(damage)
	if health.current_health > 0.0 and not _has_hyper_armor(): velocity.x = knockback * 0.45; _stagger_left = 0.3

func parried(direction: float) -> void:
	_cancel_attack(); velocity.x = direction * 420.0; _stagger_left = 1.1; _cooldown_left = attack_cooldown

func _has_hyper_armor() -> bool: return _telegraph_left > 0.0 or _attack_left > 0.0
func _cancel_attack() -> void: _telegraph_left = 0.0; _attack_left = 0.0; attack_hitbox.deactivate()
func _on_depleted() -> void:
	_cancel_attack(); GameState.add_scrap(scrap_reward); set_physics_process(false); await get_tree().create_timer(2.0).timeout
	global_position = _home_position; health.reset(); set_physics_process(true)
