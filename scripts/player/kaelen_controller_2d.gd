class_name KaelenController
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal will_changed(current: float, maximum: float)
signal combat_state_changed(label: String)
signal parry_succeeded
signal damage_received(amount: float)

enum State { FREE, DASH, ATTACK, CHARGE, HEAVY, PARRY, HEAL, HURT, DEAD }

@export_category("Movimento")
@export var run_speed := 420.0
@export var ground_acceleration := 1450.0
@export var ground_deceleration := 2300.0
@export var air_acceleration := 1700.0
@export var gravity := 1750.0
@export var max_fall_speed := 1450.0
@export_category("Pulo")
@export var jump_speed := 690.0
@export var jump_cut_multiplier := 0.45
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.12
@export var aerial_attack_hang_time := 0.12
@export_category("Combate")
@export var combat_enabled := true
@export var max_will := 100.0
@export var will_per_hit := 12.0
@export var parry_will := 25.0
@export var heal_cost := 35.0
@export var heal_amount := 30.0
@export var heavy_charge_time := 0.8

const ATTACK_DAMAGE := [12.0, 15.0, 22.0]
const ATTACK_DURATION := [0.26, 0.3, 0.38]
const ATTACK_STARTUP := [0.045, 0.055, 0.08]
const ATTACK_ACTIVE_END := [0.16, 0.19, 0.25]
const HEAVY_DURATION := 1.0
const HEAVY_STARTUP := 0.22
const HEAVY_ACTIVE_END := 0.72
const PARRY_DURATION := 0.26
const PARRY_ACTIVE_FROM := 0.03
const PARRY_ACTIVE_END := 0.15
const DASH_DURATION := 0.32
const DASH_SPEED := 620.0

var state := State.FREE
var will := 25.0
var _facing := 1.0
var _coyote_left := 0.0
var _jump_buffer_left := 0.0
var _aerial_attack_hang_left := 0.0
var _state_left := 0.0
var _dash_cooldown_left := 0.0
var _air_dash_available := true
var _combo_index := 0
var _combo_buffered := false
var _attack_connected := false
var _attack_hitbox_live := false
var _charge_elapsed := 0.0
var _respawning := false
var _landing_animation_left := 0.0

@onready var character_sprite: AnimatedSprite2D = $Visual/KaelenSprite
@onready var health: HealthComponent = $Health
@onready var attack_hitbox: Hitbox2D = $AttackHitbox

func _ready() -> void:
	character_sprite.sprite_frames = _build_sprite_frames()
	global_position = GameState.checkpoint_position
	attack_hitbox.source = self
	if not combat_enabled: attack_hitbox.deactivate()
	health.health_changed.connect(func(current: float, maximum: float) -> void: health_changed.emit(current, maximum))
	health.depleted.connect(_on_depleted)
	attack_hitbox.hit_landed.connect(_on_attack_landed)
	will = minf(will, _effective_max_will())
	will_changed.emit(will, _effective_max_will())
	_update_animation()

func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"idle", "res://assets/characters/kaelen/kaelen_idle_v1.png", Vector2(543, 724), [0, 1, 2, 3], 5.0, true, 4)
	_add_animation(frames, &"run", "res://assets/characters/kaelen/kaelen_run_v3_normalized.png", Vector2(512, 512), range(8), 10.0, true, 4)
	_add_animation(frames, &"jump", "res://assets/characters/kaelen/kaelen_jump_v2_normalized.png", Vector2(512, 512), [0, 1, 2, 3], 8.5, false, 6)
	_add_animation(frames, &"fall", "res://assets/characters/kaelen/kaelen_jump_v2_normalized.png", Vector2(512, 512), [4], 1.0, false, 6)
	_add_animation(frames, &"land", "res://assets/characters/kaelen/kaelen_jump_v2_normalized.png", Vector2(512, 512), [5], 1.0, false, 6)
	_add_animation(frames, &"attack_1", "res://assets/characters/kaelen/kaelen_combo_v1.png", Vector2(512, 341.333), [0, 1, 2], 12.0, false, 3)
	_add_animation(frames, &"attack_2", "res://assets/characters/kaelen/kaelen_combo_v1.png", Vector2(512, 341.333), [3, 4, 5], 11.0, false, 3)
	_add_animation(frames, &"attack_3", "res://assets/characters/kaelen/kaelen_combo_v1.png", Vector2(512, 341.333), [6, 7, 8], 9.0, false, 3)
	_add_animation(frames, &"heavy", "res://assets/characters/kaelen/kaelen_heavy_death_v1.png", Vector2(512, 512), [0, 1, 2], 4.0, false, 3)
	_add_animation(frames, &"death", "res://assets/characters/kaelen/kaelen_heavy_death_v1.png", Vector2(512, 512), [3, 4, 5], 4.0, false, 3)
	_add_animation(frames, &"charge", "res://assets/characters/kaelen/kaelen_states_v1.png", Vector2(512, 341.333), [0, 1, 2], 5.0, true, 3)
	_add_animation(frames, &"heal", "res://assets/characters/kaelen/kaelen_states_v1.png", Vector2(512, 341.333), [3, 4, 5], 5.0, true, 3)
	_add_animation(frames, &"hurt", "res://assets/characters/kaelen/kaelen_states_v1.png", Vector2(512, 341.333), [6, 7, 8], 9.0, false, 3)
	_add_animation(frames, &"parry", "res://assets/characters/kaelen/kaelen_states_v1.png", Vector2(512, 341.333), [6, 7, 8], 12.0, false, 3)
	return frames

func _add_animation(frames: SpriteFrames, animation: StringName, path: String, cell: Vector2, indices: Array, fps: float, loop: bool, columns: int) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, fps)
	frames.set_animation_loop(animation, loop)
	var texture: Texture2D = load(path)
	for index: int in indices:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2((index % columns) * cell.x, floori(index / float(columns)) * cell.y, cell.x, cell.y)
		frames.add_frame(animation, atlas)

func _physics_process(delta: float) -> void:
	var was_on_floor := is_on_floor()
	_update_timers(delta)
	if Input.is_action_just_pressed("jump"): _jump_buffer_left = jump_buffer_time
	_handle_state_input()
	_apply_gravity(delta)
	match state:
		State.FREE: _process_free(delta)
		State.DASH: velocity = Vector2(_facing * DASH_SPEED, 0.0)
		State.ATTACK, State.CHARGE, State.HEAVY, State.PARRY, State.HEAL: velocity.x = move_toward(velocity.x, 0.0, 3000.0 * delta)
		State.HURT, State.DEAD: velocity.x = move_toward(velocity.x, 0.0, 720.0 * delta)
	move_and_slide()
	if not was_on_floor and is_on_floor() and velocity.y >= 0.0: _landing_animation_left = 0.14
	_update_grounded_state()
	_update_facing_visuals()
	_update_animation()

func _update_timers(delta: float) -> void:
	_coyote_left = maxf(_coyote_left - delta, 0.0)
	_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)
	_aerial_attack_hang_left = maxf(_aerial_attack_hang_left - delta, 0.0)
	_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
	_landing_animation_left = maxf(_landing_animation_left - delta, 0.0)
	if state == State.FREE or state == State.CHARGE or state == State.DEAD: return
	_state_left = maxf(_state_left - delta, 0.0)
	_update_combat_windows()
	if _state_left <= 0.0: _finish_state()

func _handle_state_input() -> void:
	if state == State.ATTACK and Input.is_action_just_pressed("attack"):
		_combo_buffered = true
		return
	if state == State.CHARGE:
		_charge_elapsed += get_physics_process_delta_time()
		if Input.is_action_just_released("heavy_attack"):
			if _charge_elapsed >= heavy_charge_time: _start_heavy_attack()
			else: _set_state(State.FREE)
		return
	if state != State.FREE:
		if state == State.HEAL and Input.is_action_just_released("heal"): _set_state(State.FREE)
		return
	if Input.is_action_just_pressed("attack"): _start_attack(0)
	elif Input.is_action_just_pressed("heavy_attack"):
		_charge_elapsed = 0.0
		_set_state(State.CHARGE)
	elif Input.is_action_just_pressed("parry"): _set_state(State.PARRY, PARRY_DURATION)
	elif Input.is_action_pressed("heal") and will >= heal_cost and health.current_health < health.max_health: _set_state(State.HEAL, 1.5)
	elif Input.is_action_just_pressed("dash") and _dash_cooldown_left <= 0.0 and (is_on_floor() or _air_dash_available): _start_dash()

func _start_dash() -> void:
	_set_state(State.DASH, DASH_DURATION)
	_dash_cooldown_left = 0.45
	if not is_on_floor(): _air_dash_available = false

func _process_free(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(direction):
		_facing = signf(direction)
		var acceleration := ground_acceleration if is_on_floor() else air_acceleration
		if velocity.x * direction < 0.0: acceleration *= 1.65
		velocity.x = move_toward(velocity.x, direction * run_speed, acceleration * delta)
	else: velocity.x = move_toward(velocity.x, 0.0, (ground_deceleration if is_on_floor() else air_acceleration) * delta)
	_try_jump()
	if Input.is_action_just_released("jump") and velocity.y < 0.0: velocity.y *= jump_cut_multiplier

func _apply_gravity(delta: float) -> void:
	if not is_on_floor() and state != State.DASH and _aerial_attack_hang_left <= 0.0:
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

func _try_jump() -> void:
	if _jump_buffer_left > 0.0 and (is_on_floor() or _coyote_left > 0.0):
		velocity.y = -jump_speed
		_coyote_left = 0.0
		_jump_buffer_left = 0.0

func _start_attack(index: int) -> void:
	if not is_on_floor():
		velocity.y = 0.0
		_aerial_attack_hang_left = aerial_attack_hang_time
	_combo_index = index
	_combo_buffered = false
	_attack_connected = false
	_cancel_attack_hitbox()
	_set_state(State.ATTACK, ATTACK_DURATION[index])

func _start_heavy_attack() -> void:
	_attack_connected = false
	_cancel_attack_hitbox()
	_set_state(State.HEAVY, HEAVY_DURATION)

func _update_combat_windows() -> void:
	if not combat_enabled:
		_cancel_attack_hitbox()
		return
	if state == State.ATTACK:
		var elapsed: float = float(ATTACK_DURATION[_combo_index]) - _state_left
		_set_attack_hitbox_window(elapsed >= ATTACK_STARTUP[_combo_index] and elapsed <= ATTACK_ACTIVE_END[_combo_index], ATTACK_DAMAGE[_combo_index], 250.0 + _combo_index * 90.0, &"light")
	elif state == State.HEAVY:
		var elapsed: float = HEAVY_DURATION - _state_left
		_set_attack_hitbox_window(elapsed >= HEAVY_STARTUP and elapsed <= HEAVY_ACTIVE_END, 38.0, 600.0, &"heavy")

func _set_attack_hitbox_window(active: bool, damage: float, knockback: float, attack_type: StringName) -> void:
	if active and not _attack_hitbox_live:
		_attack_hitbox_live = true
		attack_hitbox.activate(damage, knockback, attack_type)
	elif not active and _attack_hitbox_live: _cancel_attack_hitbox()

func _cancel_attack_hitbox() -> void:
	_attack_hitbox_live = false
	attack_hitbox.deactivate()

func _is_parry_active() -> bool:
	if not combat_enabled or state != State.PARRY: return false
	var elapsed := PARRY_DURATION - _state_left
	return elapsed >= PARRY_ACTIVE_FROM and elapsed <= PARRY_ACTIVE_END

func _set_state(next_state: State, duration := 0.0) -> void:
	state = next_state
	_state_left = duration
	var tint := Color.WHITE
	match state:
		State.DASH: tint = Color(0.55, 0.82, 1.0)
		State.ATTACK: tint = Color(1.0, 0.65, 0.55)
		State.CHARGE: tint = Color(1.0, 0.38, 0.3)
		State.HEAVY: tint = Color(1.0, 0.85, 0.4)
		State.PARRY: tint = Color(0.5, 1.0, 1.0)
		State.HEAL: tint = Color(0.75, 0.55, 1.0)
		State.HURT: tint = Color(1.0, 0.35, 0.35)
	character_sprite.modulate = tint
	combat_state_changed.emit(State.keys()[state])

func _update_animation() -> void:
	var next: StringName = &"idle"
	if state == State.DEAD: next = &"death"
	elif state == State.CHARGE: next = &"charge"
	elif state == State.HEAVY: next = &"heavy"
	elif state == State.ATTACK: next = StringName("attack_%d" % (_combo_index + 1))
	elif state == State.PARRY: next = &"parry"
	elif state == State.HEAL: next = &"heal"
	elif state == State.HURT: next = &"hurt"
	elif not is_on_floor(): next = &"jump" if velocity.y < 0.0 else &"fall"
	elif _landing_animation_left > 0.0: next = &"land"
	elif absf(velocity.x) > 20.0: next = &"run"
	if character_sprite.animation != next: character_sprite.play(next)

func play_pickup_animation() -> void:
	character_sprite.modulate = Color(0.7, 1.0, 1.0)
	var tween := create_tween()
	tween.tween_property(character_sprite, "modulate", Color.WHITE, 0.35)

func is_combat_enabled() -> bool: return combat_enabled

func _update_facing_visuals(_delta := 1.0 / 60.0) -> void:
	character_sprite.flip_h = _facing < 0.0
	attack_hitbox.position.x = absf(attack_hitbox.position.x) * _facing

func _finish_state() -> void:
	var finished := state
	if finished == State.ATTACK:
		_cancel_attack_hitbox()
		if _combo_buffered and _combo_index < 2:
			_start_attack(_combo_index + 1)
			return
	elif finished == State.HEAVY: _cancel_attack_hitbox()
	elif finished == State.HEAL:
		_spend_will(heal_cost)
		health.heal(heal_amount)
	_set_state(State.FREE)

func receive_hit(damage: float, knockback: float, source: Node2D, _attack_type: StringName = &"light") -> void:
	if not combat_enabled or state == State.DASH or state == State.DEAD: return
	if _is_parry_active():
		_add_will(parry_will)
		parry_succeeded.emit()
		if is_instance_valid(source) and source.has_method("parried"): source.parried(signf(source.global_position.x - global_position.x))
		_set_state(State.FREE)
		return
	_cancel_attack_hitbox()
	var before := health.current_health
	health.damage(damage)
	damage_received.emit(before - health.current_health)
	if health.current_health <= 0.0: return
	velocity.x = knockback
	_set_state(State.HURT, 0.32)

func _on_attack_landed(_position: Vector2, _attack_type: StringName) -> void:
	if (state == State.ATTACK or state == State.HEAVY) and not _attack_connected:
		_attack_connected = true
		_add_will(will_per_hit)

func _add_will(amount: float) -> void:
	will = minf(will + amount, _effective_max_will())
	will_changed.emit(will, _effective_max_will())

func _spend_will(amount: float) -> void:
	will = maxf(will - amount, 0.0)
	will_changed.emit(will, _effective_max_will())

func _effective_max_will() -> float: return max_will * 0.5 if GameState.will_locked else max_will

func restore_at_checkpoint() -> void:
	health.reset()
	will = _effective_max_will()
	will_changed.emit(will, _effective_max_will())

func refresh_will_limit() -> void:
	will = minf(will, _effective_max_will())
	will_changed.emit(will, _effective_max_will())

func _update_grounded_state() -> void:
	if is_on_floor():
		_coyote_left = coyote_time
		_aerial_attack_hang_left = 0.0
		_air_dash_available = true

func _on_depleted() -> void:
	if _respawning: return
	_respawning = true
	GameState.register_death(global_position)
	_cancel_attack_hitbox()
	velocity.x = 0.0
	_set_state(State.DEAD)
	await get_tree().create_timer(0.8).timeout
	health.reset()
	will = minf(25.0, _effective_max_will())
	will_changed.emit(will, _effective_max_will())
	global_position = GameState.checkpoint_position
	velocity = Vector2.ZERO
	_set_state(State.FREE)
	_respawning = false
