class_name CrossbowRaider
extends CharacterBody2D

const BOLT_SCENE := preload("res://scenes/combat/bolt_projectile.tscn")
signal health_changed(current: float, maximum: float)
@export var gravity := 1750.0
@export var firing_range := 830.0
@export var retreat_range := 250.0
@export var fire_cooldown := 2.1
@export var telegraph_time := 0.8
@export var scrap_reward := 22
var _cooldown := 0.8
var _telegraph := 0.0
var _stagger := 0.0
var _target: Node2D
var _facing := -1.0
@onready var health: HealthComponent = $Health
@onready var sprite: AnimatedSprite2D = $Visual/Sprite

func _ready() -> void:
	_target = get_tree().get_first_node_in_group("player")
	sprite.sprite_frames = EnemySpriteLibrary.build("res://assets/characters/enemies/crossbow_raider_states_v3_normalized.png", Vector2(512, 512), &"walk"); sprite.play(&"idle")
	health.health_changed.connect(func(current: float, maximum: float) -> void: health_changed.emit(current, maximum)); health.depleted.connect(_on_depleted)

func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y += gravity * delta
	_cooldown = maxf(_cooldown - delta, 0.0); _stagger = maxf(_stagger - delta, 0.0); velocity.x = move_toward(velocity.x, 0.0, 1300.0 * delta)
	if _stagger > 0.0 or not is_instance_valid(_target): _telegraph = 0.0
	elif _telegraph > 0.0:
		_telegraph -= delta; sprite.play(&"telegraph")
		if _telegraph <= 0.0: _fire()
	else:
		var distance := _target.global_position.x - global_position.x; _facing = signf(distance); sprite.flip_h = _facing < 0.0
		if absf(distance) < retreat_range: velocity.x = -_facing * 210.0; sprite.play(&"walk")
		elif absf(distance) <= firing_range and _cooldown <= 0.0: _telegraph = telegraph_time
		else: sprite.play(&"idle")
	move_and_slide()

func _fire() -> void:
	var bolt: BoltProjectile = BOLT_SCENE.instantiate(); get_parent().add_child(bolt); bolt.global_position = global_position + Vector2(_facing * 55.0, -25.0); bolt.setup(_facing, self); _cooldown = fire_cooldown; sprite.play(&"attack")

func receive_hit(damage: float, knockback: float, _source: Node2D, _attack_type: StringName = &"light") -> void: health.damage(damage); velocity.x = knockback; _stagger = 0.3
func parried(direction: float) -> void: velocity.x = direction * 380.0; _stagger = 0.7
func _on_depleted() -> void: GameState.add_scrap(scrap_reward); queue_free()
