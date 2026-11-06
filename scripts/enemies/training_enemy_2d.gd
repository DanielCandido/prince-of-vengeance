class_name TrainingEnemy
extends CharacterBody2D

signal health_changed(current: float, maximum: float)

@export var gravity := 1750.0
@export var attack_range := 155.0
@export var attack_cooldown := 2.2
@export var telegraph_duration := 0.65
@export var attack_duration := 0.18
@export var patrol_distance := 230.0
@export var detection_range := 520.0
@export var move_speed := 190.0
@export var scrap_reward := 15
@export var starts_guarded := false
var _cooldown_left := 1.0
var _telegraph_left := 0.0
var _attack_left := 0.0
var _stagger_left := 0.0
var _home_position := Vector2.ZERO
var _guard_active := true
var _patrol_direction := 1.0
@onready var health: HealthComponent = $Health
@onready var target: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var attack_hitbox: Hitbox2D = $AttackHitbox
@onready var sprite: AnimatedSprite2D = $Visual/Sprite

func _ready() -> void:
	_home_position = global_position
	_guard_active = starts_guarded
	attack_hitbox.source = self
	sprite.sprite_frames = EnemySpriteLibrary.build("res://assets/characters/enemies/swamp_raider_states_v3_normalized.png", Vector2(512, 512), &"walk")
	sprite.play(&"idle")
	health.health_changed.connect(func(current: float, maximum: float) -> void: health_changed.emit(current, maximum))
	health.depleted.connect(_on_depleted)

func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
	if is_instance_valid(target) and target.has_method("is_combat_enabled") and not target.is_combat_enabled():
		_cancel_attack(); move_and_slide(); return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_stagger_left = maxf(_stagger_left - delta, 0.0)
	if _stagger_left > 0.0: _cancel_attack()
	elif _telegraph_left > 0.0:
		_telegraph_left -= delta
		sprite.play(&"telegraph")
		if _telegraph_left <= 0.0:
			_attack_left = attack_duration
			attack_hitbox.activate(18.0, 420.0, &"enemy")
	elif _attack_left > 0.0:
		_attack_left -= delta
		sprite.play(&"attack")
		if _attack_left <= 0.0:
			attack_hitbox.deactivate(); _cooldown_left = attack_cooldown
	else: _update_patrol_and_chase()
	move_and_slide()

func _update_patrol_and_chase() -> void:
	var facing := _patrol_direction
	if is_instance_valid(target) and absf(target.global_position.x - global_position.x) <= detection_range:
		var distance := target.global_position.x - global_position.x
		facing = signf(distance)
		if absf(distance) <= attack_range:
			velocity.x = 0.0
			if _cooldown_left <= 0.0: _telegraph_left = telegraph_duration
		else: velocity.x = facing * move_speed
	else:
		if absf(global_position.x - _home_position.x) >= patrol_distance: _patrol_direction = -signf(global_position.x - _home_position.x)
		velocity.x = _patrol_direction * move_speed * 0.45
	sprite.flip_h = facing < 0.0
	attack_hitbox.position.x = absf(attack_hitbox.position.x) * facing
	if sprite.animation not in [&"idle", &"walk"] or sprite.animation == &"idle" and absf(velocity.x) > 1.0: sprite.play(&"walk" if absf(velocity.x) > 1.0 else &"idle")

func receive_hit(damage: float, knockback: float, _source: Node2D, attack_type: StringName = &"light") -> void:
	if _guard_active and attack_type != &"heavy":
		health.damage(damage * 0.2); velocity.x = knockback * 0.2; return
	if _guard_active:
		_guard_active = false; _stagger_left = 1.2
	health.damage(damage); velocity.x = knockback; _stagger_left = maxf(_stagger_left, 0.22)

func parried(direction: float) -> void:
	_cancel_attack(); _stagger_left = 1.0; velocity.x = direction * 480.0; _cooldown_left = attack_cooldown

func _cancel_attack() -> void:
	_telegraph_left = 0.0; _attack_left = 0.0; attack_hitbox.deactivate(); sprite.play(&"idle")

func _on_depleted() -> void:
	_cancel_attack(); GameState.add_scrap(scrap_reward); set_physics_process(false); modulate = Color(0.25, 0.25, 0.25)
	await get_tree().create_timer(2.0).timeout
	global_position = _home_position; _guard_active = starts_guarded; health.reset(); modulate = Color.WHITE; set_physics_process(true)
